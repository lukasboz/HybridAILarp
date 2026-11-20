import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var store: MeetStore
    @State var card: PreferenceCard
    @State private var note=""
    private func value<T>(_ key: WritableKeyPath<PreferenceCard,T>) -> Binding<T> {Binding(get:{card[keyPath:key]},set:{card[keyPath:key]=$0})}
    var body: some View {
        Form {
            Section {Text("A little more you.").font(MHDesign.font(27,weight:.semibold));Text("Tell us what works. Keep the reasons private.").foregroundStyle(MHDesign.secondary)}
            Section("A private thought") {
                TextEditor(text:$note).frame(minHeight:100).font(MHDesign.font(14)).accessibilityLabel("Private note, stays on this device").onChange(of:note) {_,v in if v.count > 2000 {note=String(v.prefix(2000))}}
                Text(NativeAI.localReason).font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)
                Button {store.run {let start=Date();card=try await NativeAI.extract(note:note,base:card,data:store.data!);store.receipts.append(AIReceipt(provider:"Apple Foundation Models · on device",milliseconds:Int(Date().timeIntervalSince(start)*1000)));note=""}} label:{Label("Draft on this iPhone",systemImage:"sparkles")}.disabled(!NativeAI.localAvailable || note.isEmpty || store.busy)
                Text("No cloud fallback. You can always use the controls below.").font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)
            }
            Section("Your editable card") {
                if let data=store.data {
                    Picker("Neighbourhood",selection:value(\.areaId)) {ForEach(data.areas) {Text($0.name).tag($0.id)}}
                    Stepper("Up to $\(card.maxSpend) CAD",value:value(\.maxSpend),in:0...200,step:5)
                    Stepper("Up to \(card.maxTravel) min travel",value:value(\.maxTravel),in:5...120,step:5)
                    Picker("Travel",selection:value(\.mode)) {Text("Transit").tag("transit");Text("Walk").tag("walk");Text("Bike").tag("bike")}
                    ForEach(data.interests) {interest in Toggle(interest.name,isOn:Binding(get:{card.interests.contains(interest.id)},set:{on in if on {if !card.interests.contains(interest.id) {card.interests.append(interest.id)}}else if card.interests.count > 1 {card.interests.removeAll {$0 == interest.id}}}))}
                }
            }
            Section("Make a little time") {
                Picker("From",selection:value(\.earliest)) {ForEach(Array(stride(from:360,through:1380,by:30)),id:\.self) {Text(PlanFormat.time($0)).tag($0)}}
                Picker("Until",selection:value(\.latest)) {ForEach(Array(stride(from:390,through:1440,by:30)),id:\.self) {Text(PlanFormat.time($0)).tag($0)}}
                Text("Allow at least 90 minutes together.").font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)
            }
            Section("What matters") {Toggle("A quiet setting",isOn:value(\.quiet));Toggle("Keep it indoors",isOn:value(\.indoors));Toggle("Confirmed step-free access",isOn:value(\.stepFree))}
            Section {
                Button {do {try card.validate(in:store.data!);note="";store.sheet = .review(card)}catch {store.message=error.localizedDescription}} label:{Label("Review before sharing",systemImage:"checkmark.shield")}.buttonStyle(MHButtonStyle()).disabled(store.busy)
                Text("Room members can see your approved card. Your private note is excluded.").font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)
            }
        }.scrollContentBackground(.hidden).font(MHDesign.font(14)).onDisappear {note=""}
    }
}
struct MeetSheets: View {
    @EnvironmentObject private var store: MeetStore
    @Environment(\.dismiss) private var dismiss
    let sheet: MeetSheet
    var body: some View {
        NavigationStack {
            Group {switch sheet {
            case .create: CreateRoomForm()
            case .join: JoinRoomForm()
            case .addOption: AddOptionForm()
            case .idea(let activity): idea(activity)
            case .details(let id): detail(id)
            case .review(let card): review(card)
            case .cloudReview: cloudReview
            }}.font(MHDesign.font(14)).background(MHDesign.canvas)
                .toolbar {ToolbarItem(placement:.cancellationAction) {Button("Close") {dismiss()}.disabled(store.busy)}}
        }.tint(MHDesign.accent)
    }
    private func idea(_ activity: Activity) -> some View {
        ScrollView {VStack(alignment:.leading,spacing:20) {
            ActivityPhoto(activity:activity).frame(height:220).clipped().clipShape(RoundedRectangle(cornerRadius:20))
            Text(activity.name).font(MHDesign.font(27,weight:.semibold));Text(activity.venue+" · Toronto sample idea").foregroundStyle(MHDesign.secondary);Text(activity.description)
            Text("Illustrative photo. Costs, hours, access and travel are sample data. The group’s shared preferences decide which ideas qualify.").font(MHDesign.font(12)).foregroundStyle(MHDesign.secondary)
            Button("Make it a plan") {store.planSeed=activity.name;store.sheet = .create}.buttonStyle(MHButtonStyle())
            Button("Explore the sample group") {store.sheet=nil;store.open("sample-toronto")}.buttonStyle(MHButtonStyle(outlined:true))
        }.padding(20)}
    }
    @ViewBuilder private func detail(_ id: String) -> some View {
        if let room=store.room,let plan=store.rankings.first(where:{$0.id == id}) {
            ScrollView {VStack(alignment:.leading,spacing:20) {
                PlanCard(rank:plan) {}
                Text(plan.candidate.description)
                Text("A fit for each person").font(MHDesign.font(20,weight:.medium))
                ForEach(plan.fits,id:\.memberId) {fit in HStack {Text(room.members.first(where:{$0.id == fit.memberId})?.name ?? "Member");Spacer();Text("\(fit.score)/100 · ~\(fit.travel) min")}.font(MHDesign.font(12))}
                Text("Scores are planning estimates, not probabilities. Travel uses neighbourhood centres. Costs, hours and access are sample or host-reported; verify current details.").font(MHDesign.font(12)).foregroundStyle(MHDesign.secondary)
                if plan.candidate.url.hasPrefix("https://"),let url=URL(string:plan.candidate.url) {Link("Visit venue website",destination:url).buttonStyle(MHButtonStyle(outlined:true))}
                if store.isHost {Button("Put this to the group") {store.run {try await store.propose(plan)}}.buttonStyle(MHButtonStyle()).disabled(room.members.count < 2 || store.busy)}
            }.padding(20)}
        } else {ContentUnavailableView("The shortlist changed",systemImage:"arrow.clockwise",description:Text("Close this sheet and review the current plan."))}
    }
    private func review(_ card: PreferenceCard) -> some View {
        Form {
            Section {Text("Your card, your call.").font(MHDesign.font(27,weight:.semibold));Text("Only these preferences will be shared with room members. Your private note is excluded.").foregroundStyle(MHDesign.secondary)}
            Section("Approved preferences") {
                LabeledContent("Neighbourhood",value:store.data?.areas.first(where:{$0.id == card.areaId})?.name ?? card.areaId)
                LabeledContent("Spending limit",value:"$\(card.maxSpend) CAD");LabeledContent("Travel limit",value:"\(card.maxTravel) min · \(card.mode)")
                LabeledContent("Interests",value:card.interests.joined(separator:", "));LabeledContent("Available",value:"\(PlanFormat.time(card.earliest))–\(PlanFormat.time(card.latest))")
                LabeledContent("Quiet",value:card.quiet ? "Required" : "Flexible");LabeledContent("Indoors",value:card.indoors ? "Required" : "Flexible");LabeledContent("Step-free",value:card.stepFree ? "Confirmed access required" : "Flexible")
            }
            Section {
                Button(store.room == nil ? "Save on this device" : "Share this card") {store.run {try await store.share(card)}}.buttonStyle(MHButtonStyle()).disabled(store.busy)
                Text("Updating a room card reopens the decision and makes earlier votes obsolete.").font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)
            }
        }.scrollContentBackground(.hidden)
    }
    private var cloudReview: some View {
        Form {
            Section {Text("A little more context.").font(MHDesign.font(26,weight:.semibold));Text("This sends the room’s approved preference cards and three eligible ideas to Firebase AI Logic. The model explains the shortlist; it cannot override shared limits. Your private note is excluded.").foregroundStyle(MHDesign.secondary)}
            Section {Button("Explain these plans") {store.run {try await store.explain()}}.buttonStyle(MHButtonStyle()).disabled(store.busy);if store.busy {ProgressView("Preparing a cloud explanation…")}}
        }.scrollContentBackground(.hidden)
    }
}
struct CreateRoomForm: View {
    @EnvironmentObject private var store: MeetStore
    @State private var title=""
    @State private var name=""
    @State private var date=Date()
    @State private var live=true
    var body: some View {
        Form {
            Section {Text("Make a little time.").font(MHDesign.font(28,weight:.semibold));Text("Start a plan. Bring your people. Find your halfway.").foregroundStyle(MHDesign.secondary)}
            Section("The plan") {TextField("Plan name",text:$title);TextField("Your first name",text:$name);DatePicker("Which day?",selection:$date,in:Calendar.current.startOfDay(for:Date())...,displayedComponents:.date)}
            Section {Toggle("Live room",isOn:$live).disabled(!store.configured);Text(live ? "Friends join from their own phones or browsers with a private link." : "Explore the planning flow on this device with sample people.").font(MHDesign.font(12)).foregroundStyle(MHDesign.secondary)}
            Section {Button("Make a plan") {store.run {try await store.create(title:title,date:PlanFormat.dateString(date),displayName:name,live:live)}}.buttonStyle(MHButtonStyle()).disabled(store.busy)}
        }.scrollContentBackground(.hidden).onAppear {title=store.planSeed.isEmpty ? "Saturday, sorted." : store.planSeed;name=store.name == "You" ? "" : store.name;live=store.configured;let f=DateFormatter();f.dateFormat="yyyy-MM-dd";date=f.date(from:PlanFormat.nextSaturday()) ?? Date()}
    }
}
struct JoinRoomForm: View {
    @EnvironmentObject private var store: MeetStore
    @State private var link=""
    @State private var name=""
    var body: some View {Form {
        Section {Text("There’s room for you.").font(MHDesign.font(27,weight:.semibold));Text("Paste the invitation your friend shared.").foregroundStyle(MHDesign.secondary)}
        Section {TextField("Invitation link or code",text:$link).textInputAutocapitalization(.never).autocorrectionDisabled();TextField("Your first name",text:$name)}
        Section {Text("Joined members can see the room’s approved preference cards. Review your own card after joining.").font(MHDesign.font(12));Button("Join the room") {store.run {try await store.join(link,name:name)}}.buttonStyle(MHButtonStyle()).disabled(store.busy)}
    }.scrollContentBackground(.hidden).onAppear {link=store.pendingInvite;name=store.name == "You" ? "" : store.name}}
}
struct AddOptionForm: View {
    @EnvironmentObject private var store: MeetStore
    @State private var name=""
    @State private var venue=""
    @State private var description=""
    @State private var url=""
    @State private var area="downtown"
    @State private var tag="games"
    @State private var cost=20
    @State private var noise=2
    @State private var opens=960
    @State private var closes=1320
    @State private var indoor=true
    @State private var stepFree=false
    var body: some View {
        Form {
            Section {Text("Bring an idea to the table.").font(MHDesign.font(25,weight:.semibold));Text("You provide the details. The first real activity replaces sample options.").font(MHDesign.font(12)).foregroundStyle(MHDesign.secondary)}
            Section("Your activity") {
                TextField("Activity name",text:$name);TextField("Venue or meeting place",text:$venue)
                if let data=store.data {Picker("Neighbourhood",selection:$area) {ForEach(data.areas) {Text($0.name).tag($0.id)}};Picker("Main interest",selection:$tag) {ForEach(data.interests) {Text($0.name).tag($0.id)}}}
                Stepper("~$\(cost) CAD per person",value:$cost,in:0...200)
                TextField("What will you do?",text:$description,axis:.vertical).lineLimit(3...6)
                TextField("Venue link (optional HTTPS)",text:$url).textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            Section("Time and setting") {
                Picker("From",selection:$opens) {ForEach(Array(stride(from:360,through:1350,by:30)),id:\.self) {Text(PlanFormat.time($0)).tag($0)}}
                Picker("Until",selection:$closes) {ForEach(Array(stride(from:450,through:1440,by:30)),id:\.self) {Text(PlanFormat.time($0)).tag($0)}}
                Picker("Setting",selection:$noise) {Text("Quiet").tag(1);Text("Conversation").tag(2);Text("Lively").tag(3)}
                Toggle("Indoors",isOn:$indoor);Toggle("I confirmed step-free access",isOn:$stepFree)
                Text("Leave access off when unknown. Details are labelled as host-reported. Adding an activity reopens voting.").font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)
            }
            Section {Button("Add this activity") {store.run {
                guard let a=store.data?.areas.first(where:{$0.id == area}),!name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,name.count <= 70,!venue.isEmpty,venue.count <= 100,!description.isEmpty,description.count <= 300,url.count <= 1000,(url.isEmpty || url.hasPrefix("https://")),closes-opens >= 90 else {throw MeetError.message("Check the activity details and allow 90 minutes.")}
                let idea=Activity(id:"",name:name,venue:venue,area:a.name,lat:a.lat,lng:a.lng,cost:cost,tags:[tag],noise:noise,indoor:indoor,stepFree:stepFree ? true : nil,theme:["games":"games","art":"art","coffee":"library","food":"market","outdoors":"park","music":"water"][tag] ?? "library",description:description,url:url,duration:90,windows:[[opens,closes]],dataSource:"host")
                try await store.addOption(idea,areaId:area)
            }}.buttonStyle(MHButtonStyle()).disabled(store.busy)}
        }.scrollContentBackground(.hidden)
    }
}
