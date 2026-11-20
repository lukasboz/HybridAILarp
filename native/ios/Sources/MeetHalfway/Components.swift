import SwiftUI
import UIKit
import CoreTransferable
import UniformTypeIdentifiers

struct MHGlass: ViewModifier {
    var radius: CGFloat = MHDesign.cardRadius
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.tint(.white.opacity(0.18)),in:RoundedRectangle(cornerRadius:radius))
        } else {
            content.background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:radius))
                .overlay(RoundedRectangle(cornerRadius:radius).stroke(MHDesign.border.opacity(0.8),lineWidth:1))
        }
    }
}
extension View {func mhGlass(_ radius: CGFloat = MHDesign.cardRadius) -> some View {modifier(MHGlass(radius:radius))}}
struct MHButtonStyle: ButtonStyle {
    var outlined = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(MHDesign.font(13,weight:.medium)).padding(.horizontal,16).padding(.vertical,12)
            .frame(minHeight:44).foregroundStyle(outlined ? MHDesign.secondary : .white)
            .background(outlined ? MHDesign.surface : MHDesign.accent,in:RoundedRectangle(cornerRadius:MHDesign.controlRadius))
            .overlay(RoundedRectangle(cornerRadius:MHDesign.controlRadius).stroke(outlined ? MHDesign.border : .clear,lineWidth:1))
            .opacity(configuration.isPressed ? 0.75 : 1).scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
struct MHAvatar: View {
    let member: Member
    var index = 0
    var size: CGFloat = 34
    private let colors: [Color] = [Color(hex:0xDDD9F2),Color(hex:0xF7DDD2),Color(hex:0xDCD5EE),Color(hex:0xD4E0F2)]
    var body: some View {
        Text(String(member.name.prefix(2)).uppercased()).font(MHDesign.font(size*0.27,weight:.semibold))
            .foregroundStyle(MHDesign.secondary).frame(width:size,height:size)
            .background(colors[index%colors.count],in:Circle()).overlay(Circle().stroke(.white,lineWidth:2))
            .overlay(Circle().stroke(MHDesign.accent.opacity(member.card == nil ? 0 : 0.16),lineWidth:1).padding(-2))
            .accessibilityLabel(member.name)
    }
}
struct ActivityPhoto: View {
    let activity: Activity
    var body: some View {
        if let url = Bundle.main.url(forResource:activity.imageName,withExtension:"jpg",subdirectory:"Shared/activities"),let image = UIImage(contentsOfFile:url.path) {
            Image(uiImage:image).resizable().scaledToFill().accessibilityHidden(true)
        } else {Rectangle().fill(MHDesign.accentSoft).overlay(Image(systemName:"sparkles").foregroundStyle(MHDesign.accent))}
    }
}
struct GlassOrb: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors:[.white.opacity(0.85),MHDesign.orb.opacity(0.75),Color(hex:0xBAC1E8).opacity(0.45)],center:.topLeading,startRadius:0,endRadius:105))
            Circle().stroke(.white.opacity(0.6),lineWidth:1).padding(7)
            Ellipse().fill(.white.opacity(0.33)).frame(width:32,height:16).rotationEffect(.degrees(-35)).offset(x:-15,y:-22).blur(radius:6)
            Circle().trim(from:0.1,to:0.7).stroke(.white.opacity(0.5),lineWidth:0.7).padding(16).rotationEffect(.degrees(-30))
        }.mhGlass(80).clipShape(Circle()).shadow(color:MHDesign.accent.opacity(0.12),radius:22,y:9)
            .scaleEffect(breathe ? 1.03 : 0.97)
            .onAppear {if !reduceMotion {withAnimation(.easeInOut(duration:3.5).repeatForever(autoreverses:true)) {breathe=true}}}
            .accessibilityHidden(true)
    }
}
struct OrbitView: View {
    let members: [Member]
    let ideas: [Activity]
    var ranked: [RankedPlan] = []
    var selected = ""
    var home = false
    var ready = true
    var onMember: (Member)->Void
    var onIdea: (Activity)->Void
    var onCentre: ()->Void
    var body: some View {
        GeometryReader { geometry in
            let centre = CGPoint(x:geometry.size.width/2,y:geometry.size.height*0.46)
            let radius = min(geometry.size.width*0.36,min(geometry.size.height*0.39,210))
            let peopleRadius = min(radius*0.53,MHDesign.peopleRadius)
            ZStack {
                Circle().fill(RadialGradient(colors:[MHDesign.orb.opacity(0.16),.clear],center:.center,startRadius:10,endRadius:150)).frame(width:300,height:300).position(centre)
                ForEach(Array(ideas.enumerated()),id:\.element.id) {index,idea in
                    let angle = Double(index)/Double(max(ideas.count,1))*2*Double.pi-Double.pi/2
                    let eligible = home || !ready || ranked.contains(where:{$0.id == idea.id})
                    Button {onIdea(idea)} label: {
                        ActivityPhoto(activity:idea).frame(width:MHDesign.tileSize-6,height:MHDesign.tileSize-2).clipped().clipShape(RoundedRectangle(cornerRadius:9))
                            .padding(3).background(.white,in:RoundedRectangle(cornerRadius:12))
                            .overlay(RoundedRectangle(cornerRadius:12).stroke(idea.id == selected ? MHDesign.accent.opacity(0.5) : MHDesign.border.opacity(0.45),lineWidth:idea.id == selected ? 2 : 1))
                            .shadow(color:MHDesign.ink.opacity(0.08),radius:5,y:3)
                            .overlay(alignment:.bottomTrailing) {
                                if !home,let fit=ranked.first(where:{$0.id == idea.id}) {Text("\(fit.minFit)").font(MHDesign.font(8,weight:.semibold)).padding(4).background(.white,in:RoundedRectangle(cornerRadius:5)).offset(x:4,y:4)}
                            }
                    }.buttonStyle(.plain).opacity(eligible ? 1 : 0.25).disabled(!home && !ready)
                        .accessibilityLabel(idea.name+(eligible ? "" : ", outside shared limits"))
                        .position(x:centre.x+CGFloat(cos(angle))*radius,y:centre.y+CGFloat(sin(angle))*radius)
                }
                Button(action:onCentre) {GlassOrb().frame(width:MHDesign.orbSize,height:MHDesign.orbSize)}.buttonStyle(.plain).position(centre).accessibilityLabel("Explore the sample group").disabled(!home).accessibilityHidden(!home)
                Text(home ? "Find your halfway" : ready ? "Common ground, found." : "Bringing everyone together.")
                    .font(MHDesign.font(9)).foregroundStyle(MHDesign.secondary.opacity(0.8)).position(x:centre.x,y:centre.y+MHDesign.orbSize/2+21)
                ForEach(Array(members.prefix(8).enumerated()),id:\.element.id) {index,member in
                    let angle = Double(index)/Double(max(members.count,1))*2*Double.pi-Double.pi/2
                    Button {onMember(member)} label: {
                        VStack(spacing:5) {
                            MHAvatar(member:member,index:index,size:30)
                            Text(member.name).font(MHDesign.font(9,weight:.medium))
                            Text(home ? "Sample" : member.card == nil ? "Adding preferences" : "Ready").font(MHDesign.font(7)).foregroundStyle(MHDesign.secondary.opacity(0.7))
                        }.foregroundStyle(MHDesign.secondary)
                    }.buttonStyle(.plain).position(x:centre.x+CGFloat(cos(angle))*peopleRadius,y:centre.y+CGFloat(sin(angle))*peopleRadius)
                }
            }
        }.accessibilityElement(children:.contain)
    }
}
struct PlanCard: View {
    let rank: RankedPlan
    var explanation: Explanation?
    var action: ()->Void
    var body: some View {
        VStack(alignment:.leading,spacing:14) {
            ActivityPhoto(activity:rank.candidate).frame(height:144).clipped().clipShape(RoundedRectangle(cornerRadius:12))
            HStack {Text("COMMON GROUND").font(MHDesign.font(9,weight:.medium)).tracking(1.2);Spacer();Text("\(rank.minFit)").font(MHDesign.font(22,weight:.medium))+Text("/100").font(MHDesign.font(10))}.foregroundStyle(MHDesign.accent.opacity(0.75))
            Text(rank.candidate.name).font(MHDesign.font(20,weight:.semibold)).foregroundStyle(MHDesign.ink)
            Text("\(rank.candidate.venue) · \(rank.candidate.area)").font(MHDesign.font(12)).foregroundStyle(MHDesign.secondary)
            HStack(spacing:12) {Label(rank.candidate.cost == 0 ? "Free" : "~$\(rank.candidate.cost)",systemImage:"dollarsign.circle");Label(PlanFormat.time(rank.start ?? 960),systemImage:"clock");Label("~\(rank.maxTravel) min max",systemImage:"tram")}.font(MHDesign.font(10)).foregroundStyle(MHDesign.secondary)
            if let explanation {Text(explanation.reason).font(MHDesign.font(13));Text("The tradeoff: "+explanation.tradeoff).font(MHDesign.font(12)).foregroundStyle(MHDesign.secondary)}
            Divider().overlay(MHDesign.border)
            HStack {Label("Within everyone’s limits",systemImage:"checkmark").font(MHDesign.font(10));Spacer();Button("Take a closer look",action:action).font(MHDesign.font(11,weight:.medium))}.foregroundStyle(MHDesign.secondary)
        }.padding(16).background(.white,in:RoundedRectangle(cornerRadius:20)).overlay(RoundedRectangle(cornerRadius:20).stroke(MHDesign.border,lineWidth:1))
    }
}
struct CalendarExport: Transferable {
    let content: String
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType:UTType(filenameExtension:"ics")!) {value in
            let file=FileManager.default.temporaryDirectory.appendingPathComponent("MeetHalfway-\(UUID().uuidString).ics")
            try value.content.write(to:file,atomically:true,encoding:.utf8);return SentTransferredFile(file)
        }
    }
}
