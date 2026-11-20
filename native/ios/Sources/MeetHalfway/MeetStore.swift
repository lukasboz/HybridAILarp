import Foundation
import SwiftUI
import FirebaseCore

enum MeetSheet: Identifiable {
    case create,join,idea(Activity),details(String),addOption,review(PreferenceCard),cloudReview
    var id: String {switch self {case .create:return "create";case .join:return "join";case .idea(let a):return "idea-"+a.id;case .details(let id):return "details-"+id;case .addOption:return "option";case .review:return "review";case .cloudReview:return "cloud"}}
}
@MainActor
final class MeetStore: ObservableObject {
    let data: Experience?
    private let service = FirebaseService()
    @Published var tab = "home"
    @Published var roomId: String?
    @Published var room: PlanRoom?
    @Published var localRooms: [PlanRoom] = []
    @Published var cloudRooms: [PlanRoom] = []
    @Published var uid = ""
    @Published var persona = "alex"
    @Published var name = UserDefaults.standard.string(forKey:"meet.name") ?? "You"
    @Published var sheet: MeetSheet?
    @Published var busy = false
    @Published var message: String?
    @Published var pendingInvite = ""
    @Published var planSeed = ""
    @Published var selected = ""
    @Published var showPreferences = false
    @Published var explanations: [Explanation] = []
    @Published var explanationRevision: Int?
    @Published var receipts: [AIReceipt] = []
    var configured: Bool {FirebaseApp.app() != nil}
    var myId: String {room?.local == true ? persona : uid}
    var isHost: Bool {room?.ownerId == myId}
    var rankings: [RankedPlan] {guard let data,let room else{return []};return Planner.rank(room,data:data)}
    var currentCard: PreferenceCard? {room?.members.first(where:{$0.id == myId})?.card ?? savedCard() ?? data?.defaultCard}
    init() {
        data = try? Experience.load()
        if let bytes = UserDefaults.standard.data(forKey:"meet.rooms") {localRooms = (try? JSONDecoder().decode([PlanRoom].self,from:bytes)) ?? []}
        if let data, !localRooms.contains(where:{$0.id == "sample-toronto"}) {
            localRooms.insert(PlanRoom(id:"sample-toronto",title:"Saturday, sorted.",date:PlanFormat.nextSaturday(),ownerId:"alex",memberIds:data.members.map(\.id),members:data.members),at:0)
        }
    }
    func run(_ action: @escaping () async throws -> Void) {
        guard !busy else{return};busy = true
        Task {defer {busy = false};do {try await action()}catch {message = error.localizedDescription}}
    }
    func connect() async {
        guard configured else{return}
        do {uid = try await service.signIn();cloudRooms = try await service.listRooms(uid:uid)}catch {message = "Live connection unavailable. Samples remain available. \(error.localizedDescription)"}
    }
    func open(_ id: String, as member: String? = nil) {
        roomId = id;room = localRooms.first(where:{$0.id == id}) ?? cloudRooms.first(where:{$0.id == id})
        persona = member ?? (id == "sample-toronto" ? "alex" : room?.ownerId ?? "")
        selected = "";explanations = [];explanationRevision = nil;showPreferences = false;tab = "plans"
    }
    func watch(_ id: String) async {
        guard let data, !localRooms.contains(where:{$0.id == id}) else{return}
        do {
            _ = try await service.signIn();let feed = try service.feed(id:id,data:data);defer {feed.stop()}
            feed.onChange = { [weak self] value in guard let self,self.roomId == id else{return};self.room = value;if self.explanationRevision != value.revision {self.explanations = []}}
            feed.onError = {[weak self] error in self?.message = error.localizedDescription}
            while !Task.isCancelled {try await Task.sleep(for:.seconds(30))}
        }catch is CancellationError {}catch {message = error.localizedDescription}
    }
    func create(title: String, date: String, displayName: String, live: Bool) async throws {
        let title = title.trimmingCharacters(in:.whitespacesAndNewlines), displayName = displayName.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !title.isEmpty,title.count <= 70,!displayName.isEmpty,displayName.count <= 30,date >= PlanFormat.dateString(Date()) else {throw MeetError.message("Add a plan name, your first name, and a date today or later.")}
        name = displayName;UserDefaults.standard.set(name,forKey:"meet.name")
        if live {uid = try await service.signIn();let id = try await service.create(title:title,date:date,name:name,uid:uid);cloudRooms = try await service.listRooms(uid:uid);sheet = nil;open(id)}
        else {
            let me = "device-"+FirebaseService.randomHex(8), member = Member(id:me,name:name,card:nil)
            let value = PlanRoom(id:FirebaseService.randomHex(18),title:title,date:date,ownerId:me,memberIds:[me],members:[member])
            localRooms.append(value);persist();sheet = nil;open(value.id)
        }
    }
    func join(_ input: String, name: String) async throws {
        let cleaned = name.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !cleaned.isEmpty,cleaned.count <= 30 else {throw MeetError.message("Add your first name.")}
        self.name = cleaned;UserDefaults.standard.set(cleaned,forKey:"meet.name");uid = try await service.signIn()
        let id = try await service.join(input:input,name:cleaned,uid:uid);cloudRooms = try await service.listRooms(uid:uid);sheet = nil;open(id)
    }
    func mutate(_ change: (inout PlanRoom)->Void) {
        guard let id = roomId,let index = localRooms.firstIndex(where:{$0.id == id}) else{return}
        change(&localRooms[index]);room = localRooms[index];persist()
        if explanationRevision != room?.revision {explanations = []}
    }
    private func reset(_ value: inout PlanRoom) {value.revision += 1;value.proposal = nil;value.status = "gathering";value.votes = [:]}
    func share(_ card: PreferenceCard) async throws {
        guard let data else{return};try card.validate(in:data)
        if let value = room {
            if value.local {let id=myId;mutate {r in if let i=r.members.firstIndex(where:{$0.id == id}) {r.members[i].card=card};self.reset(&r)}}
            else {try await service.share(room:value,uid:uid,name:name,card:card)}
        }
        UserDefaults.standard.set(try JSONEncoder().encode(card),forKey:"meet.card");sheet=nil;showPreferences=false
        message = "Your card is shared. Your private note stayed on this device."
    }
    func propose(_ plan: RankedPlan) async throws {
        guard let value=room,let fresh=rankings.first(where:{$0.id == plan.id}),isHost else {throw MeetError.message("Review the current eligible shortlist first.")}
        if value.local {mutate {r in r.revision += 1;r.status="voting";r.proposal=Proposal(candidateId:fresh.id,startMinute:fresh.start ?? 960,revision:r.revision);r.votes=[:]}}
        else {try await service.propose(room:value,plan:fresh)};sheet=nil
    }
    func vote(_ choice: String) async throws {
        guard let value=room,let p=value.proposal,value.status == "voting" else{return}
        if value.local {let id=myId;mutate {$0.votes[id]=Vote(choice:choice,candidateId:p.candidateId,revision:p.revision)}}
        else {try await service.vote(room:value,uid:uid,choice:choice)}
    }
    func confirm() async throws {
        guard let value=room,value.canConfirm,isHost else {throw MeetError.message("Everyone needs to accept this version of the plan.")}
        if value.local {mutate {$0.status="confirmed"}}else {try await service.confirm(room:value)}
    }
    func addSample() {
        guard let data,let room,room.local,room.members.count < 8 else{return}
        let n=room.members.count,member=Member(id:"sample-\(n)",name:["Sam","Riley","Casey","Taylor","Jamie","Avery","Morgan","Robin"][n],card:data.defaultCard)
        mutate {$0.members.append(member);$0.memberIds.append(member.id);self.reset(&$0)}
    }
    func addOption(_ option: Activity, areaId: String) async throws {
        guard let value=room,isHost else{return}
        if value.local {
            guard let id=(1...12).map({String(format:"option-%02d",$0)}).first(where:{id in !value.options.contains(where:{$0.id == id})}) else {throw MeetError.message("A room can hold twelve activities.")}
            var added=option;added.id=id;mutate {$0.options.append(added);self.reset(&$0)}
        }else {try await service.addOption(room:value,uid:uid,option:option,areaId:areaId)};sheet=nil
    }
    func explain() async throws {
        guard let value=room else{return};let revision=value.revision
        let (items,receipt)=try await NativeAI.explain(room:value,ranked:rankings);receipts.append(receipt)
        guard room?.revision == revision,room?.id == value.id else {throw MeetError.message("The group changed. Request an explanation for the new shortlist.")}
        explanations=items;explanationRevision=revision;sheet=nil
    }
    func savedCard() -> PreferenceCard? {UserDefaults.standard.data(forKey:"meet.card").flatMap {try? JSONDecoder().decode(PreferenceCard.self,from:$0)}}
    private func persist() {if let bytes=try? JSONEncoder().encode(localRooms) {UserDefaults.standard.set(bytes,forKey:"meet.rooms")}}
}
