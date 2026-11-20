import Foundation

struct PreferenceCard: Codable, Equatable {
    var areaId: String
    var maxSpend: Int
    var maxTravel: Int
    var mode: String
    var interests: [String]
    var earliest: Int
    var latest: Int
    var quiet: Bool
    var indoors: Bool
    var stepFree: Bool

    static let keys: Set<String> = ["areaId","maxSpend","maxTravel","mode","interests","earliest","latest","quiet","indoors","stepFree"]
    func validate(in data: Experience) throws {
        guard data.areas.contains(where: {$0.id == areaId}), (0...200).contains(maxSpend),
              (5...120).contains(maxTravel), ["transit","walk","bike"].contains(mode),
              (1...6).contains(interests.count), Set(interests).count == interests.count,
              interests.allSatisfy({ value in data.interests.contains(where: {$0.id == value}) }),
              (360...1380).contains(earliest), (390...1440).contains(latest), latest-earliest >= 90
        else { throw MeetError.message("Check your preferences and allow at least 90 minutes.") }
    }
    var fields: [String: Any] {
        ["areaId":areaId,"maxSpend":maxSpend,"maxTravel":maxTravel,"mode":mode,"interests":interests,
         "earliest":earliest,"latest":latest,"quiet":quiet,"indoors":indoors,"stepFree":stepFree]
    }
    static func parse(_ object: [String: Any], in data: Experience) throws -> PreferenceCard {
        guard Set(object.keys) == keys else { throw MeetError.message("The draft contains an unsupported field. Your private note was not shared.") }
        let card = try JSONDecoder().decode(PreferenceCard.self, from: JSONSerialization.data(withJSONObject: object))
        try card.validate(in: data); return card
    }
}
struct Area: Codable, Identifiable { let id: String; let name: String; let lat: Double; let lng: Double }
struct Interest: Codable, Identifiable { let id: String; let name: String }
struct Activity: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var venue: String
    var area: String
    var lat: Double
    var lng: Double
    var cost: Int
    var tags: [String]
    var noise: Int
    var indoor: Bool
    var stepFree: Bool?
    var theme: String
    var description: String
    var url: String
    var duration: Int
    var windows: [[Int]]
    var dataSource: String?
    var imageName: String {
        ["games":"games","art":"art","studio":"art","library":"coffee","market":"food","park":"park","picnic":"park","water":"water"][theme] ?? "coffee"
    }
}
struct Member: Codable, Identifiable, Equatable { var id: String; var name: String; var card: PreferenceCard?; var inviteId: String? }
struct Proposal: Codable, Equatable { var candidateId: String; var startMinute: Int; var revision: Int }
struct Vote: Codable, Equatable { var choice: String; var candidateId: String; var revision: Int }
struct PlanRoom: Codable, Identifiable {
    var id: String
    var title: String
    var date: String
    var ownerId: String
    var memberIds: [String]
    var status: String = "gathering"
    var revision: Int = 0
    var proposal: Proposal?
    var members: [Member] = []
    var votes: [String: Vote] = [:]
    var options: [Activity] = []
    var inviteId: String?
    var local: Bool = true
    var allReady: Bool { !members.isEmpty && members.count == memberIds.count && members.allSatisfy {$0.card != nil} }
    var canConfirm: Bool {
        guard let p = proposal, members.count >= 2, allReady else { return false }
        return members.allSatisfy { m in votes[m.id]?.choice == "yes" && votes[m.id]?.revision == p.revision && votes[m.id]?.candidateId == p.candidateId }
    }
}
struct Experience: Codable {
    let areas: [Area]
    let catalog: [Activity]
    let interests: [Interest]
    let members: [Member]
    let defaultCard: PreferenceCard
    static func load() throws -> Experience {
        guard let file = Bundle.main.url(forResource: "experience", withExtension: "json", subdirectory: "Shared") else { throw MeetError.message("The shared activity catalogue is missing from this build.") }
        return try JSONDecoder().decode(Experience.self, from: Data(contentsOf: file))
    }
}
struct IndividualFit: Codable { var memberId: String; var score: Int; var travel: Int; var matches: Int }
struct RankedPlan: Identifiable {
    let candidate: Activity
    let eligible: Bool
    let reasons: [String]
    let fits: [IndividualFit]
    let start: Int?
    var id: String { candidate.id }
    var minFit: Int { fits.map(\.score).min() ?? 0 }
    var meanFit: Int { fits.isEmpty ? 0 : Int((Double(fits.map(\.score).reduce(0,+))/Double(fits.count)).rounded()) }
    var maxTravel: Int { fits.map(\.travel).max() ?? 0 }
}
enum Planner {
    static func distance(_ a: Area, _ b: Activity) -> Double {
        let radians = Double.pi/180
        let v = pow(sin((b.lat-a.lat)*radians/2),2) + cos(a.lat*radians)*cos(b.lat*radians)*pow(sin((b.lng-a.lng)*radians/2),2)
        return 6371*2*atan2(sqrt(v),sqrt(1-v))
    }
    static func evaluate(_ candidate: Activity, members: [Member], data: Experience) -> RankedPlan {
        guard !members.isEmpty, members.allSatisfy({$0.card != nil && (try? $0.card!.validate(in:data)) != nil}) else {
            return RankedPlan(candidate:candidate,eligible:false,reasons:["Waiting for everyone’s preferences."],fits:[],start:nil)
        }
        let cards = members.compactMap(\.card), earliest = cards.map(\.earliest).max()!, latest = cards.map(\.latest).min()!
        let slot = candidate.windows.first { min($0[1],latest)-max($0[0],earliest) >= candidate.duration }
        let travel = cards.map { card -> Int in
            let area = data.areas.first {$0.id == card.areaId}!
            let speed = ["transit":18.0,"walk":4.5,"bike":12.0][card.mode]!
            return Int(ceil(distance(area,candidate)*1.35/speed*60 + (card.mode == "transit" ? 10 : 3)))
        }
        var reasons: [String] = []
        if slot == nil { reasons.append("No shared 90-minute time window.") }
        if cards.contains(where: {candidate.cost > $0.maxSpend}) { reasons.append("Above someone’s shared spending limit.") }
        if cards.enumerated().contains(where: {travel[$0.offset] > $0.element.maxTravel}) { reasons.append("Beyond someone’s travel limit.") }
        if cards.contains(where: { $0.quiet }) && candidate.noise > 1 { reasons.append("Doesn’t meet the quiet-setting requirement.") }
        if cards.contains(where: { $0.indoors }) && !candidate.indoor { reasons.append("An indoor setting is required.") }
        if cards.contains(where: { $0.stepFree }) && candidate.stepFree != true { reasons.append("Step-free access hasn’t been confirmed.") }
        var fits: [IndividualFit] = []
        for (i,c) in cards.enumerated() {
            let matches = c.interests.filter {candidate.tags.contains($0)}.count
            let interest = Double(matches)/Double(min(c.interests.count,candidate.tags.count))
            let affordable = c.maxSpend == 0 ? 1 : 1-Double(candidate.cost)/Double(max(c.maxSpend,1))
            let convenient = 1-min(Double(travel[i])/Double(c.maxTravel),1)
            let scoreValue: Double = 45.0 + interest*30.0 + affordable*10.0 + convenient*15.0
            let score = max(0,min(100,Int(scoreValue.rounded())))
            fits.append(IndividualFit(memberId:members[i].id,score:score,travel:travel[i],matches:matches))
        }
        return RankedPlan(candidate:candidate,eligible:reasons.isEmpty,reasons:reasons,fits:fits,start:slot.map {max($0[0],earliest)})
    }
    static func rank(_ room: PlanRoom, data: Experience) -> [RankedPlan] {
        ranked(members:room.members,catalog:room.options.isEmpty ? data.catalog : room.options,data:data)
    }
    static func ranked(members: [Member], catalog: [Activity], data: Experience) -> [RankedPlan] {
        catalog.map {evaluate($0,members:members,data:data)}.filter(\.eligible).sorted {
            if $0.minFit != $1.minFit {return $0.minFit > $1.minFit}
            if $0.meanFit != $1.meanFit {return $0.meanFit > $1.meanFit}
            if $0.maxTravel != $1.maxTravel {return $0.maxTravel < $1.maxTravel}
            if $0.candidate.cost != $1.candidate.cost {return $0.candidate.cost < $1.candidate.cost}
            return $0.id < $1.id
        }
    }
}
struct Explanation: Codable, Identifiable { let id: String; let reason: String; let tradeoff: String }
struct AIReceipt: Identifiable { let id = UUID(); let provider: String; let milliseconds: Int; let date = Date() }
enum MeetError: LocalizedError { case message(String); var errorDescription: String? { if case .message(let value) = self {return value}; return nil } }
enum PlanFormat {
    static func time(_ n: Int) -> String { let hour = n/60%24; return "\(hour%12 == 0 ? 12 : hour%12)\(n%60 == 0 ? "" : String(format:":%02d",n%60))\(hour < 12 ? "am" : "pm")" }
    static func nextSaturday() -> String {
        var cal = Calendar(identifier:.gregorian); cal.timeZone = TimeZone(identifier:"America/Toronto")!
        let today = cal.startOfDay(for:Date()), delta = (7-cal.component(.weekday,from:today)+7)%7
        let next = cal.date(byAdding:.day,value:delta == 0 ? 7 : delta,to:today)!
        return dateString(next)
    }
    static func dateString(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = TimeZone(identifier:"America/Toronto"); return f.string(from:date) }
    static func calendar(_ room: PlanRoom, activity: Activity) -> String {
        let start = room.proposal?.startMinute ?? 960
        func stamp(_ minute: Int) -> String {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = TimeZone(identifier:"America/Toronto")
            let day = f.date(from:room.date) ?? Date()
            var calendar = Calendar(identifier:.gregorian);calendar.timeZone = TimeZone(identifier:"America/Toronto")!
            let date = calendar.date(byAdding:.day,value:minute/1440,to:day)!
            return "\(dateString(date).replacingOccurrences(of:"-",with:""))T\(String(format:"%02d%02d00",minute/60%24,minute%60))"
        }
        func escaped(_ s: String) -> String {s.replacingOccurrences(of:"\\",with:"\\\\").replacingOccurrences(of:"\n",with:"\\n").replacingOccurrences(of:",",with:"\\,").replacingOccurrences(of:";",with:"\\;")}
        return ["BEGIN:VCALENDAR","VERSION:2.0","PRODID:-//MeetHalfway//Toronto//EN","BEGIN:VTIMEZONE","TZID:America/Toronto","BEGIN:STANDARD","DTSTART:19701101T020000","RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU","TZOFFSETFROM:-0400","TZOFFSETTO:-0500","END:STANDARD","BEGIN:DAYLIGHT","DTSTART:19700308T020000","RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU","TZOFFSETFROM:-0500","TZOFFSETTO:-0400","END:DAYLIGHT","END:VTIMEZONE","BEGIN:VEVENT","UID:\(room.id)@meethalfway.app","DTSTAMP:\(ISO8601DateFormatter().string(from:Date()).replacingOccurrences(of:"-",with:"").replacingOccurrences(of:":",with:""))","DTSTART;TZID=America/Toronto:\(stamp(start))","DTEND;TZID=America/Toronto:\(stamp(start+90))","SUMMARY:\(escaped(room.title))","LOCATION:\(escaped(activity.venue))","DESCRIPTION:Verify venue details before going.","END:VEVENT","END:VCALENDAR"].joined(separator:"\r\n")
    }
}
