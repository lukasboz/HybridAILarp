import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class FirebaseService {
    private var database: Firestore {get throws {
        guard FirebaseApp.app() != nil else {throw MeetError.message("Live rooms are unavailable in this build. You can explore the sample group.")}
        return Firestore.firestore()
    }}
    func signIn() async throws -> String {
        _ = try database
        if let user = Auth.auth().currentUser {return user.uid}
        return try await Auth.auth().signInAnonymously().user.uid
    }
    func listRooms(uid: String) async throws -> [PlanRoom] {
        let docs = try await database.collection("rooms").whereField("memberIds",arrayContains:uid).getDocuments()
        return docs.documents.compactMap {Self.decodeRoom($0.documentID,$0.data())}
    }
    static func randomHex(_ length: Int) -> String {
        var rng = SystemRandomNumberGenerator()
        return (0..<length).map {_ in String(format:"%02x",UInt8.random(in:0...255,using:&rng))}.joined()
    }
    func create(title: String, date: String, name: String, uid: String) async throws -> String {
        let db = try database, id = Self.randomHex(18), token = Self.randomHex(24), batch = db.batch(), root = db.collection("rooms").document(id)
        batch.setData(["title":title,"date":date,"city":"Toronto","ownerId":uid,"memberIds":[uid],"status":"gathering","revision":0,"proposal":NSNull(),"lastJoinInviteId":token,"createdAt":FieldValue.serverTimestamp()],forDocument:root)
        batch.setData(["name":name,"card":NSNull(),"inviteId":token,"updatedAt":FieldValue.serverTimestamp()],forDocument:root.collection("members").document(uid))
        batch.setData(["roomId":id,"title":title,"createdBy":uid,"expiresAt":Timestamp(date:Date().addingTimeInterval(7*86400))],forDocument:db.collection("invites").document(token))
        try await batch.commit();return id
    }
    func join(input: String, name: String, uid: String) async throws -> String {
        let token = URLComponents(string:input)?.queryItems?.first(where:{$0.name == "invite"})?.value ?? input.trimmingCharacters(in:.whitespacesAndNewlines)
        guard token.range(of:"^[a-f0-9]{48}$",options:.regularExpression) != nil else {throw MeetError.message("Paste a valid invitation link or code.")}
        let db = try database, invite = try await db.collection("invites").document(token).getDocument()
        guard let v = invite.data(), let id = v["roomId"] as? String, let expires = v["expiresAt"] as? Timestamp, expires.dateValue() > Date() else {throw MeetError.message("That invitation has expired.")}
        let root = db.collection("rooms").document(id), member = root.collection("members").document(uid)
        if let existing = try? await member.getDocument(), existing.exists {return id}
        let batch = db.batch()
        batch.setData(["name":name,"card":NSNull(),"inviteId":token,"updatedAt":FieldValue.serverTimestamp()],forDocument:member)
        batch.updateData(["memberIds":FieldValue.arrayUnion([uid]),"lastJoinInviteId":token,"status":"gathering","proposal":NSNull(),"revision":FieldValue.increment(Int64(1))],forDocument:root)
        try await batch.commit();return id
    }
    func share(room: PlanRoom, uid: String, name: String, card: PreferenceCard) async throws {
        let db = try database, root = db.collection("rooms").document(room.id), batch = db.batch()
        batch.updateData(["card":card.fields,"name":name,"updatedAt":FieldValue.serverTimestamp()],forDocument:root.collection("members").document(uid))
        batch.updateData(["proposal":NSNull(),"status":"gathering","revision":FieldValue.increment(Int64(1))],forDocument:root)
        try await batch.commit()
    }
    func propose(room: PlanRoom, plan: RankedPlan) async throws {
        let ref = try database.collection("rooms").document(room.id)
        _ = try await ref.firestore.runTransaction {tx,errorPointer -> Any? in
            do {
                guard try tx.getDocument(ref).data()?["revision"] as? Int == room.revision else {throw MeetError.message("The group changed. Review the updated shortlist.")}
                let revision = room.revision+1
                tx.updateData(["status":"voting","revision":revision,"proposal":["candidateId":plan.id,"startMinute":plan.start ?? 960,"revision":revision]],forDocument:ref)
            } catch {errorPointer?.pointee = error as NSError};return nil
        }
    }
    func vote(room: PlanRoom, uid: String, choice: String) async throws {
        guard let p = room.proposal else {throw MeetError.message("There is no current proposal.")}
        try await database.collection("rooms").document(room.id).collection("votes").document(uid).setData(["choice":choice,"candidateId":p.candidateId,"revision":p.revision,"updatedAt":FieldValue.serverTimestamp()])
    }
    func confirm(room: PlanRoom) async throws {try await database.collection("rooms").document(room.id).updateData(["status":"confirmed"])}
    func addOption(room: PlanRoom, uid: String, option: Activity, areaId: String) async throws {
        guard let slot = (1...12).map({String(format:"option-%02d",$0)}).first(where:{id in !room.options.contains(where:{$0.id == id})}) else {throw MeetError.message("A room can hold twelve activities.")}
        let db = try database, ref = db.collection("rooms").document(room.id), batch = db.batch()
        batch.setData(["name":option.name,"venue":option.venue,"areaId":areaId,"cost":option.cost,"tags":option.tags,"noise":option.noise,"indoor":option.indoor,"stepFree":option.stepFree.map {$0 as Any} ?? NSNull(),"description":option.description,"url":option.url,"opens":option.windows[0][0],"closes":option.windows[0][1],"createdBy":uid,"updatedAt":FieldValue.serverTimestamp()],forDocument:ref.collection("options").document(slot))
        batch.updateData(["updatedAt":FieldValue.serverTimestamp()],forDocument:ref.collection("members").document(uid))
        batch.updateData(["status":"gathering","proposal":NSNull(),"revision":FieldValue.increment(Int64(1))],forDocument:ref)
        try await batch.commit()
    }
    func feed(id: String, data: Experience) throws -> RoomFeed {RoomFeed(db:try database,id:id,data:data)}
    static func decodeRoom(_ id: String, _ v: [String:Any]) -> PlanRoom? {
        guard let title = v["title"] as? String, let date = v["date"] as? String, let owner = v["ownerId"] as? String, let ids = v["memberIds"] as? [String] else {return nil}
        var room = PlanRoom(id:id,title:title,date:date,ownerId:owner,memberIds:ids,local:false)
        room.status = v["status"] as? String ?? "gathering";room.revision = v["revision"] as? Int ?? 0
        if let p = v["proposal"] as? [String:Any], let candidate = p["candidateId"] as? String, let start = p["startMinute"] as? Int, let revision = p["revision"] as? Int {room.proposal = Proposal(candidateId:candidate,startMinute:start,revision:revision)}
        room.inviteId = v["lastJoinInviteId"] as? String;return room
    }
}

@MainActor
final class RoomFeed {
    private var listeners: [ListenerRegistration] = []
    private var root: PlanRoom?
    private var members: [Member] = []
    private var votes: [String:Vote] = [:]
    private var options: [Activity] = []
    var onChange: ((PlanRoom)->Void)?
    var onError: ((Error)->Void)?
    init(db: Firestore, id: String, data: Experience) {
        let ref = db.collection("rooms").document(id)
        listeners.append(ref.addSnapshotListener { [weak self] snapshot,error in Task { @MainActor in
            guard let self else {return};if let error {self.onError?(error);return}
            if let v = snapshot?.data() {self.root = FirebaseService.decodeRoom(id,v);self.emit()}
        }})
        listeners.append(ref.collection("members").addSnapshotListener { [weak self] snapshot,error in Task { @MainActor in
            guard let self else {return};if let error {self.onError?(error);return}
            self.members = (snapshot?.documents ?? []).compactMap {doc in
                let v = doc.data();guard let name = v["name"] as? String else {return nil}
                return Member(id:doc.documentID,name:name,card:(v["card"] as? [String:Any]).flatMap {try? PreferenceCard.parse($0,in:data)},inviteId:v["inviteId"] as? String)
            };self.emit()
        }})
        listeners.append(ref.collection("votes").addSnapshotListener { [weak self] snapshot,error in Task { @MainActor in
            guard let self else {return};if let error {self.onError?(error);return}
            self.votes = Dictionary(uniqueKeysWithValues:(snapshot?.documents ?? []).compactMap {doc -> (String,Vote)? in
                let v = doc.data();guard let choice = v["choice"] as? String, let candidate = v["candidateId"] as? String, let revision = v["revision"] as? Int else {return nil}
                return (doc.documentID,Vote(choice:choice,candidateId:candidate,revision:revision))
            });self.emit()
        }})
        listeners.append(ref.collection("options").addSnapshotListener { [weak self] snapshot,error in Task { @MainActor in
            guard let self else {return};if let error {self.onError?(error);return}
            self.options = (snapshot?.documents ?? []).compactMap {doc in
                let v = doc.data();guard let aid = v["areaId"] as? String, let area = data.areas.first(where:{$0.id == aid}), let name = v["name"] as? String, let venue = v["venue"] as? String, let cost = v["cost"] as? Int, let tags = v["tags"] as? [String], let opens = v["opens"] as? Int, let closes = v["closes"] as? Int else {return nil}
                return Activity(id:doc.documentID,name:name,venue:venue,area:area.name,lat:area.lat,lng:area.lng,cost:cost,tags:tags,noise:v["noise"] as? Int ?? 2,indoor:v["indoor"] as? Bool ?? true,stepFree:v["stepFree"] as? Bool,theme:["games":"games","art":"art","coffee":"library","food":"market","outdoors":"park","music":"water"][tags.first ?? ""] ?? "library",description:v["description"] as? String ?? "",url:v["url"] as? String ?? "",duration:90,windows:[[opens,closes]],dataSource:"host")
            };self.emit()
        }})
    }
    private func emit() {guard var value = root else {return};value.members = members;value.votes = votes;value.options = options;onChange?(value)}
    func stop() {listeners.forEach {$0.remove()};listeners = []}
    deinit {listeners.forEach {$0.remove()}}
}
