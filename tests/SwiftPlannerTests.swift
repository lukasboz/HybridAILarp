import Foundation

struct PlannerCase: Decodable {
    let name: String
    let members: [Member]
    let expected: [Expected]
    struct Expected: Decodable {let id:String;let minFit:Int;let meanFit:Int;let maxTravel:Int;let start:Int}
}
@main
struct PlannerContractTests {
    static func main() throws {
        let root=CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "shared"
        let data=try JSONDecoder().decode(Experience.self,from:Data(contentsOf:URL(fileURLWithPath:root+"/experience.json")))
        let cases=try JSONDecoder().decode([PlannerCase].self,from:Data(contentsOf:URL(fileURLWithPath:root+"/planner-cases.json")))
        for fixture in cases {
            let actual=Planner.ranked(members:fixture.members,catalog:data.catalog,data:data)
            precondition(actual.count == fixture.expected.count,"\(fixture.name): result count differs")
            for (got,want) in zip(actual,fixture.expected) {
                precondition(got.id == want.id && got.minFit == want.minFit && got.meanFit == want.meanFit && got.maxTravel == want.maxTravel && got.start == want.start,"\(fixture.name): Swift differs from the shared web result for \(want.id)")
            }
            print("PASS Swift planner: \(fixture.name)")
        }
        var polluted=data.defaultCard.fields;polluted["privateNote"]="NEVER_SHARED"
        do {_ = try PreferenceCard.parse(polluted,in:data);fatalError("Private note field was accepted")}catch {}
        print("PASS Swift approved-card allowlist")
        var midnight=PlanRoom(id:"calendar-test",title:"Games; friends, together",date:"2026-11-01",ownerId:"alex",memberIds:data.members.map(\.id),members:data.members)
        midnight.proposal=Proposal(candidateId:data.catalog[0].id,startMinute:1350,revision:1)
        let calendar=PlanFormat.calendar(midnight,activity:data.catalog[0])
        precondition(calendar.contains("DTEND;TZID=America/Toronto:20261102T000000"),"Calendar midnight rollover failed")
        precondition(calendar.contains("Games\\; friends\\, together"),"Calendar text escaping failed")
        print("PASS Swift calendar midnight rollover and escaping")
    }
}
