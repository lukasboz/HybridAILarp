import SwiftUI

struct MeetRootView: View {
    @EnvironmentObject private var store: MeetStore
    private let tabs=[("home","Discover","sparkles"),("plans","My plans","calendar"),("preferences","Preferences","slider.horizontal.3"),("privacy","Privacy","lock.shield")]
    var body: some View {
        GeometryReader {geo in
            ZStack {
                MHDesign.canvas.ignoresSafeArea()
                HStack(spacing:0) {
                    if geo.size.width >= 760 {sidebar}
                    VStack(spacing:0) {
                        header
                        Group {
                            if store.data == nil {ContentUnavailableView("Build resources missing",systemImage:"exclamationmark.triangle",description:Text("Run the shared resource build before packaging this app."))}
                            else if store.tab == "privacy" {PrivacyView()}
                            else if store.tab == "preferences" || store.showPreferences {PreferencesView(card:store.currentCard!).id(store.myId)}
                            else if store.roomId != nil {RoomView()}
                            else if store.tab == "plans" {PlansView()}
                            else {DiscoverView()}
                        }.frame(maxWidth:.infinity,maxHeight:.infinity)
                    }
                }
            }.safeAreaInset(edge:.bottom,spacing:0) {if geo.size.width < 760 {bottomBar.padding(.horizontal,16).padding(.bottom,8).padding(.top,6)}}
        }.font(MHDesign.font(MHDesign.bodySize)).foregroundStyle(MHDesign.ink)
            .sheet(item:$store.sheet) {MeetSheets(sheet:$0).environmentObject(store).presentationCornerRadius(28)}
            .alert("MeetHalfway",isPresented:Binding(get:{store.message != nil},set:{if !$0 {store.message=nil}})) {Button("OK") {store.message=nil}} message: {Text(store.message ?? "")}
            .overlay(alignment:.top) {if store.busy {Label {Text("Bringing your plan together…")} icon:{ProgressView()}.font(MHDesign.font(12)).padding(13).mhGlass(18).padding(.top,70)}}
            .task(id:store.roomId) {if let id=store.roomId {await store.watch(id)}}
    }
    private func navigate(_ id: String) {store.tab=id;store.showPreferences=false;if id == "home" || id == "plans" {store.roomId=nil;store.room=nil}}
    private var header: some View {
        HStack {
            Button {navigate("home")} label:{HStack(spacing:5) {Image(systemName:"person.2").foregroundStyle(MHDesign.accent);Text("meet").font(MHDesign.font(18))+Text("halfway").font(MHDesign.font(18,weight:.semibold))}}.buttonStyle(.plain)
            Spacer();Label("Toronto",systemImage:"mappin").font(MHDesign.font(10)).padding(.horizontal,11).padding(.vertical,8).mhGlass(24)
        }.padding(.horizontal,20).frame(height:62)
    }
    private var bottomBar: some View {
        HStack(spacing:4) {ForEach(tabs,id:\.0) {item in
            Button {navigate(item.0)} label:{VStack(spacing:4) {Image(systemName:item.2).font(.system(size:17));Text(item.1).font(MHDesign.font(9))}.frame(maxWidth:.infinity).frame(height:47).foregroundStyle(store.tab == item.0 ? MHDesign.accent : MHDesign.secondary).background(store.tab == item.0 ? MHDesign.accentSoft.opacity(0.8) : .clear,in:RoundedRectangle(cornerRadius:18))}.buttonStyle(.plain)
        }}.padding(6).frame(height:MHDesign.tabHeight).mhGlass(24)
    }
    private var sidebar: some View {
        VStack(alignment:.leading,spacing:12) {
            Text("meethalfway").font(MHDesign.font(23,weight:.semibold)).padding(.vertical,25)
            ForEach(tabs,id:\.0) {item in Button {navigate(item.0)} label:{Label(item.1,systemImage:item.2).font(MHDesign.font(13)).padding(12).frame(maxWidth:.infinity,minHeight:44,alignment:.leading).foregroundStyle(store.tab == item.0 ? MHDesign.accent : MHDesign.secondary).background(store.tab == item.0 ? MHDesign.accentSoft.opacity(0.8) : .clear,in:RoundedRectangle(cornerRadius:11))}.buttonStyle(.plain)}
            Spacer();Text("Your people. Your privacy.").font(MHDesign.font(12,weight:.medium));Text("Private thoughts stay with you.\nGood plans bring you together.").font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)
        }.padding(18).frame(width:MHDesign.sidebarWidth).frame(maxHeight:.infinity).background(MHDesign.accentSoft.opacity(0.25))
    }
}
struct DiscoverView: View {
    @EnvironmentObject private var store: MeetStore
    @State private var seed=""
    var body: some View {
        GeometryReader {geo in
            ScrollView {
                VStack(spacing:0) {
                    VStack(spacing:10) {Text("YOU, THEM & A LITTLE COMMON GROUND").font(MHDesign.font(8,weight:.medium)).tracking(1.5).foregroundStyle(MHDesign.secondary);Text("Make time for your people.").font(MHDesign.font(MHDesign.headingSize,weight:.medium));Text("Different tastes. Different budgets. One good plan.").font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)}.padding(.top,14)
                    if let data=store.data {
                        OrbitView(members:data.members,ideas:data.catalog,home:true,onMember:{store.open("sample-toronto",as:$0.id)},onIdea:{store.sheet = .idea($0)},onCentre:{store.open("sample-toronto")})
                            .frame(maxHeight:.infinity)
                    }
                    Text("A world of possibilities. One plan together.").font(MHDesign.font(9)).foregroundStyle(MHDesign.secondary).padding(.bottom,18)
                    HStack(spacing:12) {Button {store.open("sample-toronto")} label:{Label("Explore a sample group",systemImage:"person.2")};Button {store.sheet = .join} label:{Label("Join a plan",systemImage:"link")}}.font(MHDesign.font(10)).foregroundStyle(MHDesign.secondary).padding(.bottom,15)
                    HStack(spacing:10) {
                        Button {store.planSeed="";store.sheet = .create} label:{Image(systemName:"plus").frame(width:24,height:32)}
                        TextField("What’s the plan? A catch-up, a game night…",text:$seed).font(MHDesign.font(12)).submitLabel(.go).onSubmit(start)
                        Button(action:start) {Image(systemName:"arrow.up").font(.system(size:14,weight:.medium)).frame(width:34,height:34).foregroundStyle(.white).background(MHDesign.accent,in:RoundedRectangle(cornerRadius:12))}.accessibilityLabel("Start this plan")
                    }.padding(10).mhGlass(26)
                    Text("Toronto sample ideas · Illustrative photos").font(MHDesign.font(8)).foregroundStyle(MHDesign.secondary).padding(.top,12)
                }.padding(.horizontal,18).padding(.bottom,12).frame(maxWidth:800).frame(maxWidth:.infinity).frame(height:max(geo.size.height,520))
            }.scrollDisabled(geo.size.height >= 520).scrollDismissesKeyboard(.interactively)
        }
    }
    private func start() {store.planSeed=String(seed.prefix(70));store.sheet = .create}
}
struct PlansView: View {
    @EnvironmentObject private var store: MeetStore
    var body: some View {
        ScrollView {VStack(alignment:.leading,spacing:20) {
            Text("Your plans, coming together.").font(MHDesign.font(28,weight:.semibold))
            Text("Pick up where your people left off.").foregroundStyle(MHDesign.secondary)
            HStack {Button("New plan") {store.planSeed="";store.sheet = .create}.buttonStyle(MHButtonStyle());Button("Join with a link") {store.sheet = .join}.buttonStyle(MHButtonStyle(outlined:true))}
            ForEach(store.cloudRooms+store.localRooms) {room in Button {store.open(room.id)} label:{
                VStack(alignment:.leading,spacing:16) {
                    HStack {Text(room.status == "confirmed" ? "All set" : "Finding your halfway");Spacer();Text(room.local ? "On this device" : "Live room")}.font(MHDesign.font(10)).foregroundStyle(MHDesign.accent)
                    Text(room.title).font(MHDesign.font(22,weight:.medium));Text("\(room.date) · Toronto").font(MHDesign.font(12)).foregroundStyle(MHDesign.secondary)
                    HStack {Label("\(room.memberIds.count) people",systemImage:"person.2");Spacer();Label("Open plan",systemImage:"chevron.right")}.font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)
                }.padding(20).frame(maxWidth:.infinity,alignment:.leading).mhGlass()
            }.buttonStyle(.plain)}
        }.padding(20)}
    }
}
struct RoomView: View {
    @EnvironmentObject private var store: MeetStore
    @State private var filtered=false
    var body: some View {
        if let room=store.room,let data=store.data {
            let ranked=store.rankings, selected=ranked.first(where:{$0.id == store.selected}) ?? ranked.first
            ScrollView {VStack(alignment:.leading,spacing:20) {
                if room.local {Text("SAMPLE GROUP · Switch people to try each perspective. Live rooms connect real devices.").font(MHDesign.font(10)).foregroundStyle(MHDesign.secondary).padding(12).frame(maxWidth:.infinity,alignment:.leading).background(MHDesign.accentSoft.opacity(0.4),in:RoundedRectangle(cornerRadius:12))}
                VStack(alignment:.leading,spacing:10) {Text(room.title).font(MHDesign.font(28,weight:.semibold));Label("\(room.date) · \(room.memberIds.count) people · Toronto",systemImage:"calendar").font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)}
                HStack(spacing:8) {if store.isHost {Button("Add an idea") {store.sheet = .addOption}.buttonStyle(MHButtonStyle(outlined:true))};Button("My preferences") {store.showPreferences=true}.buttonStyle(MHButtonStyle(outlined:true))}
                if !room.local,let token=room.inviteId,let url=URL(string:"https://meethalfway-2026-e43ca6.web.app/?invite=\(token)") {ShareLink(item:url) {Label("Invite people",systemImage:"link")}.buttonStyle(MHButtonStyle())}
                ScrollView(.horizontal,showsIndicators:false) {HStack(spacing:9) {ForEach(Array(room.members.enumerated()),id:\.element.id) {i,m in Button {if room.local {store.persona=m.id}} label:{HStack {MHAvatar(member:m,index:i);VStack(alignment:.leading,spacing:4) {Text(m.name+(store.myId == m.id ? " · you" : "")).font(MHDesign.font(11,weight:.medium));Text(m.card == nil ? "Adding preferences" : "Preferences shared").font(MHDesign.font(9)).foregroundStyle(MHDesign.secondary)}}.padding(10).background(store.myId == m.id ? MHDesign.accentSoft.opacity(0.6) : .white,in:RoundedRectangle(cornerRadius:13))}.buttonStyle(.plain)};if room.local,room.members.count < 8 {Button("+ Sample person") {store.addSample()}.font(MHDesign.font(11))}}}
                if room.proposal != nil {VotingView(room:room)}
                Picker("Plan results",selection:$filtered) {Text("Common ground (\(min(3,ranked.count)))").tag(false);Text("Outside our limits").tag(true)}.pickerStyle(.segmented)
                if filtered {
                    ForEach(room.options.isEmpty ? data.catalog : room.options) {idea in
                        let result=Planner.evaluate(idea,members:room.members,data:data)
                        if !result.eligible {VStack(alignment:.leading,spacing:9) {Text(idea.name).font(MHDesign.font(17,weight:.medium));Text(result.reasons.joined(separator:"\n")).font(MHDesign.font(12)).foregroundStyle(MHDesign.secondary)}.padding(17).frame(maxWidth:.infinity,alignment:.leading).mhGlass()}
                    }
                } else {
                    OrbitView(members:room.members,ideas:room.options.isEmpty ? data.catalog : room.options,ranked:ranked,selected:selected?.id ?? "",ready:room.allReady,onMember:{if room.local {store.persona=$0.id}},onIdea:{idea in if ranked.contains(where:{$0.id == idea.id}) {store.selected=idea.id}else {filtered=true}},onCentre:{})
                        .frame(height:360).padding(.horizontal,-20)
                    if let selected {
                        PlanCard(rank:selected,explanation:store.explanationRevision == room.revision ? store.explanations.first(where:{$0.id == selected.id}) : nil) {store.sheet = .details(selected.id)}
                        Button {store.sheet = .cloudReview} label:{Label("Explain this shortlist",systemImage:"sparkles")}.buttonStyle(MHButtonStyle(outlined:true)).disabled(store.busy)
                        Text("The lowest individual fit comes first. Every shared limit is respected.").font(MHDesign.font(11)).foregroundStyle(MHDesign.secondary)
                        ForEach(Array(ranked.prefix(3)).filter {$0.id != selected.id}) {rank in PlanCard(rank:rank) {store.sheet = .details(rank.id)}}
                    } else {ContentUnavailableView(room.allReady ? "Let’s find a little more room." : "Good plans take everyone.",systemImage:"person.2",description:Text(room.allReady ? "No idea meets every requirement. Decide together whether to edit a limit." : "Everyone needs to share a preference card."))}
                }
                Text(room.options.isEmpty ? "Toronto sample catalogue. Costs, hours, access and travel are fixtures. Photos are illustrative." : "Activities and access are host-reported. Travel is approximate. Verify current details before going.").font(MHDesign.font(10)).foregroundStyle(MHDesign.secondary)
            }.padding(20).frame(maxWidth:900).frame(maxWidth:.infinity)}
        } else {ProgressView("Opening your planning room…")}
    }
}
struct VotingView: View {
    @EnvironmentObject private var store: MeetStore
    let room: PlanRoom
    var body: some View {
        if let proposal=room.proposal,let rank=store.rankings.first(where:{$0.id == proposal.candidateId}) {
            VStack(alignment:.leading,spacing:16) {
                Label(room.status == "confirmed" ? "IT’S A PLAN" : "A PLAN ON THE TABLE",systemImage:room.status == "confirmed" ? "checkmark.circle" : "person.2").font(MHDesign.font(10,weight:.medium))
                Text(rank.candidate.name).font(MHDesign.font(23,weight:.semibold));Text("\(room.date) · \(PlanFormat.time(proposal.startMinute)) · \(rank.candidate.venue)").font(MHDesign.font(12))
                if room.status == "confirmed" {ShareLink(item:CalendarExport(content:PlanFormat.calendar(room,activity:rank.candidate)),preview:SharePreview(room.title)) {Label("Add to calendar",systemImage:"calendar.badge.plus")}.buttonStyle(MHButtonStyle())}
                else {
                    HStack {ForEach([("yes","I’m in"),("maybe","Discuss"),("no","Change it")],id:\.0) {item in Button(item.1) {store.run {try await store.vote(item.0)}}.buttonStyle(MHButtonStyle(outlined:room.votes[store.myId]?.choice != item.0))}}
                    ForEach(room.members) {m in Text("\(m.name) · \(room.votes[m.id]?.revision == proposal.revision ? room.votes[m.id]?.choice ?? "Not voted" : "Not voted")").font(MHDesign.font(11))}
                    if store.isHost {Button("Everyone’s in. Make it happen.") {store.run {try await store.confirm()}}.buttonStyle(MHButtonStyle()).disabled(!room.canConfirm || store.busy)}
                }
            }.padding(20).frame(maxWidth:.infinity,alignment:.leading).background(MHDesign.accentSoft.opacity(0.6),in:RoundedRectangle(cornerRadius:20))
        }
    }
}
struct PrivacyView: View {
    @EnvironmentObject private var store: MeetStore
    var body: some View {
        ScrollView {VStack(alignment:.leading,spacing:22) {
            Text("Bring yourself.\nKeep your private thoughts.").font(MHDesign.font(28,weight:.semibold))
            privacy("Your words stay here.","Private notes use only an on-device model on supported hardware. There is no cloud fallback. Manual controls work on iPhone 13.","iphone")
            privacy("Your card, your call.","You review your neighbourhood, budget, travel limit, interests, availability and access requirements before sharing them with room members.","checkmark.shield")
            privacy("Everyone’s limits count.","Hard limits filter the shortlist before scoring. Every current member must accept the same proposal before it can be confirmed.","person.2")
            privacy("A neighbourhood is enough.","Travel estimates use a neighbourhood centre. We don’t request live location or a street address. Photos and sample venue data are illustrative.","mappin")
            privacy("Cloud explanations are a choice.","After your approval, shared cards and eligible ideas are sent through Firebase AI Logic. Your private note is excluded. Anyone with your invitation can join and see the shared room.","cloud")
            Text("Where AI actually ran").font(MHDesign.font(20,weight:.semibold))
            if store.receipts.isEmpty {Text("No AI requests in this session yet.").foregroundStyle(MHDesign.secondary)}
            ForEach(store.receipts) {receipt in Text("\(receipt.provider) · \(receipt.milliseconds) ms").font(MHDesign.font(12)).padding(14).mhGlass()}
        }.padding(20).frame(maxWidth:800).frame(maxWidth:.infinity)}
    }
    private func privacy(_ title: String,_ body: String,_ symbol: String) -> some View {VStack(alignment:.leading,spacing:13) {Label(title,systemImage:symbol).font(MHDesign.font(18,weight:.medium));Text(body).font(MHDesign.font(14)).foregroundStyle(MHDesign.secondary).lineSpacing(5)}.padding(20).frame(maxWidth:.infinity,alignment:.leading).mhGlass()}
}
