package app.meethalfway.mobile
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.*
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import java.time.*
import java.time.format.DateTimeFormatter

private val tabs=listOf(Triple("home","Discover",Icons.Outlined.AutoAwesome),Triple("plans","My plans",Icons.Outlined.CalendarMonth),Triple("preferences","Preferences",Icons.Outlined.Tune),Triple("privacy","Privacy",Icons.Outlined.Shield))
@Composable fun MeetRoot(m:MeetModel){
    DisposableEffect(m.roomId){val stop=m.roomId?.let{m.watch(it)};onDispose{stop?.invoke()}}
    BackHandler(m.roomId!=null||m.showPreferences){if(m.showPreferences)m.showPreferences=false else m.navigate("plans")}
    Surface(color=MHDesign.canvas){BoxWithConstraints(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing)){
        val wide=maxWidth>=760.dp
        Row(Modifier.fillMaxSize()){
            if(wide)Column(Modifier.width(MHDesign.sidebarWidth.dp).fillMaxHeight().background(MHDesign.accentSoft.copy(alpha=.25f)).padding(18.dp),verticalArrangement=Arrangement.spacedBy(12.dp)){
                Heading("meethalfway",23);Spacer(Modifier.height(18.dp))
                tabs.forEach{(id,label,icon)->TextButton(onClick={m.navigate(id)},modifier=Modifier.fillMaxWidth().heightIn(min=44.dp),shape=RoundedCornerShape(11.dp),colors=ButtonDefaults.textButtonColors(containerColor=if(m.tab==id)MHDesign.accentSoft.copy(alpha=.8f)else Color.Transparent,contentColor=if(m.tab==id)MHDesign.accent else MHDesign.secondary)){
                    Icon(icon,null,Modifier.size(17.dp));Spacer(Modifier.width(10.dp));Text(label,fontSize=13.sp);Spacer(Modifier.weight(1f))
                }}
                Spacer(Modifier.weight(1f));Text("Your people. Your privacy.",fontSize=12.sp);Caption("Private thoughts stay with you.\nGood plans bring you together.")
            }
            Column(Modifier.weight(1f)){
                Row(Modifier.fillMaxWidth().height(62.dp).padding(horizontal=20.dp),verticalAlignment=Alignment.CenterVertically){Icon(Icons.Outlined.People,null,tint=MHDesign.accent,modifier=Modifier.size(22.dp));Text("meethalfway",fontSize=18.sp,fontWeight=FontWeight.SemiBold,modifier=Modifier.padding(start=6.dp).clickable{m.navigate("home")});Spacer(Modifier.weight(1f));Row(Modifier.glass(24).padding(horizontal=11.dp,vertical=8.dp),verticalAlignment=Alignment.CenterVertically){Icon(Icons.Outlined.LocationOn,null,modifier=Modifier.size(12.dp),tint=MHDesign.secondary);Text("Toronto",fontSize=10.sp,color=MHDesign.secondary)}}
                Box(Modifier.weight(1f)){
                    when{m.tab=="privacy"->PrivacyScreen(m);m.tab=="preferences"||m.showPreferences->PreferencesScreen(m);m.roomId!=null->RoomScreen(m);m.tab=="plans"->PlansScreen(m);else->DiscoverScreen(m)}
                    if(m.busy)Row(Modifier.align(Alignment.TopCenter).padding(top=8.dp).glass(18).padding(12.dp),verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(10.dp)){CircularProgressIndicator(Modifier.size(16.dp),strokeWidth=2.dp);Text("Bringing your plan together…",fontSize=11.sp)}
                }
                if(!wide)Row(Modifier.padding(horizontal=16.dp,vertical=8.dp).fillMaxWidth().height(MHDesign.tabHeight.dp).glass(24).padding(6.dp)){
                    tabs.forEach{(id,label,icon)->Column(Modifier.weight(1f).fillMaxHeight().clip(RoundedCornerShape(18.dp)).background(if(m.tab==id)MHDesign.accentSoft.copy(alpha=.8f)else Color.Transparent).clickable{m.navigate(id)},horizontalAlignment=Alignment.CenterHorizontally,verticalArrangement=Arrangement.Center){Icon(icon,null,tint=if(m.tab==id)MHDesign.accent else MHDesign.secondary,modifier=Modifier.size(17.dp));Text(label,fontSize=9.sp,color=MHDesign.secondary,modifier=Modifier.padding(top=4.dp))}}
                }
            }
        }
    }}
    m.message?.let{AlertDialog(onDismissRequest={m.message=null},confirmButton={TextButton(onClick={m.message=null}){Text("OK")}},title={Text("MeetHalfway")},text={Text(it,fontSize=13.sp)})}
    if(m.sheet!=null)MeetSheet(m)
}
@Composable fun DiscoverScreen(m:MeetModel){var seed by remember{mutableStateOf("")};BoxWithConstraints(Modifier.fillMaxSize()){
    val orbitHeight=(maxOf(maxHeight.value,520f)-250).toInt().coerceIn(180,560)
    val scroll=rememberScrollState()
    Column(Modifier.fillMaxSize().then(if(maxHeight<520.dp)Modifier.verticalScroll(scroll)else Modifier).padding(horizontal=18.dp),horizontalAlignment=Alignment.CenterHorizontally){
        Spacer(Modifier.height(14.dp));Text("YOU, THEM & A LITTLE COMMON GROUND",fontSize=8.sp,color=MHDesign.secondary,letterSpacing=1.5.sp);Spacer(Modifier.height(10.dp));Heading("Make time for your people.");Spacer(Modifier.height(10.dp));Caption("Different tastes. Different budgets. One good plan.")
        Orbit(m.data.members,m.data.catalog,home=true,height=orbitHeight,onMember={m.open("sample-toronto",it.id)},onIdea={m.preview=it;m.sheet="idea"},onCentre={m.open("sample-toronto")})
        Text("A world of possibilities. One plan together.",fontSize=9.sp,color=MHDesign.secondary);Spacer(Modifier.height(12.dp))
        Row(verticalAlignment=Alignment.CenterVertically){TextButton(onClick={m.open("sample-toronto")}){Icon(Icons.Outlined.People,null,Modifier.size(13.dp));Text(" Explore a sample group",fontSize=10.sp)};TextButton(onClick={m.sheet="join"}){Text("Join a plan",fontSize=10.sp)}}
        Row(Modifier.fillMaxWidth().glass(26).padding(10.dp),verticalAlignment=Alignment.CenterVertically){IconButton(onClick={m.seed="";m.sheet="create"},modifier=Modifier.size(28.dp)){Icon(Icons.Outlined.Add,"Create a new plan",Modifier.size(17.dp))};BasicTextField(seed,{seed=it.take(70)},Modifier.weight(1f).height(34.dp),singleLine=true,textStyle=TextStyle(fontFamily=Inter,fontSize=13.sp,color=MHDesign.secondary),keyboardOptions=KeyboardOptions(imeAction=ImeAction.Go),keyboardActions=KeyboardActions(onGo={m.seed=seed;m.sheet="create"}),decorationBox={inner->Box(contentAlignment=Alignment.CenterStart){if(seed.isEmpty())Text("What’s the plan? A catch-up, a game night…",fontSize=11.sp,color=MHDesign.secondary);inner()}});IconButton(onClick={m.seed=seed;m.sheet="create"},modifier=Modifier.size(34.dp).background(MHDesign.accent,RoundedCornerShape(12.dp))){Icon(Icons.Outlined.ArrowUpward,"Start this plan",Modifier.size(16.dp),tint=Color.White)}}
        Spacer(Modifier.height(12.dp));Text("Toronto sample ideas · Illustrative photos",fontSize=8.sp,color=MHDesign.secondary);Spacer(Modifier.height(12.dp))
    }
}}
@Composable fun PlansScreen(m:MeetModel){Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),verticalArrangement=Arrangement.spacedBy(20.dp)){
    Heading("Your plans, coming together.",28);Caption("Pick up where your people left off.")
    Row(horizontalArrangement=Arrangement.spacedBy(10.dp)){Action("New plan"){m.seed="";m.sheet="create"};Action("Join with a link",true){m.sheet="join"}}
    (m.cloudRooms+m.localRooms).forEach{room->Column(Modifier.fillMaxWidth().glass().clickable{m.open(room.id)}.padding(20.dp),verticalArrangement=Arrangement.spacedBy(16.dp)){Row{Text(if(room.status=="confirmed")"All set"else"Finding your halfway",fontSize=10.sp,color=MHDesign.accent);Spacer(Modifier.weight(1f));Text(if(room.local)"On this device"else"Live room",fontSize=10.sp,color=MHDesign.secondary)};Heading(room.title,22);Caption("${room.date} · Toronto");Row{Caption("${room.memberIds.size} people");Spacer(Modifier.weight(1f));Caption("Open plan ›")}}}
}}
@Composable fun RoomScreen(m:MeetModel){val room=m.room;val context=LocalContext.current;var filtered by remember(room?.id){mutableStateOf(false)}
    if(room==null){Box(Modifier.fillMaxSize(),contentAlignment=Alignment.Center){CircularProgressIndicator()};return}
    val ranked=m.rankings;val selected=ranked.firstOrNull{it.id==m.selected}?:ranked.firstOrNull()
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),verticalArrangement=Arrangement.spacedBy(20.dp)){
        if(room.local)Caption("SAMPLE GROUP · Switch people to try each perspective. Live rooms connect real devices.",Modifier.glass(12).padding(12.dp))
        Heading(room.title,28);Caption("${room.date} · ${room.memberIds.size} people · Toronto")
        Row(horizontalArrangement=Arrangement.spacedBy(8.dp)){if(m.isHost)Action("Add an idea",true){m.sheet="option"};Action("My preferences",true){m.showPreferences=true}}
        if(!room.local&&room.inviteId!=null)Action("Invite people"){shareText(context,"Join ${room.title}","https://meethalfway-2026-e43ca6.web.app/?invite=${room.inviteId}")}
        Row(Modifier.horizontalScroll(rememberScrollState()),horizontalArrangement=Arrangement.spacedBy(9.dp)){room.members.forEachIndexed{i,member->Row(Modifier.glass(13).clickable(enabled=room.local){m.persona=member.id}.padding(10.dp),verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(8.dp)){Avatar(member,i);Column{Text(member.name+if(member.id==m.myId)" · you"else"",fontSize=11.sp,fontWeight=FontWeight.Medium);Text(if(member.card==null)"Adding preferences"else"Preferences shared",fontSize=9.sp,color=MHDesign.secondary)}}};if(room.local&&room.members.size<8)TextButton(onClick={m.addSample()}){Text("+ Sample person",fontSize=11.sp)}}
        if(room.proposal!=null)VotingPanel(m,room)
        Row(horizontalArrangement=Arrangement.spacedBy(12.dp)){TextButton(onClick={filtered=false}){Text("Common ground (${minOf(3,ranked.size)})",fontSize=11.sp,fontWeight=if(!filtered)FontWeight.SemiBold else FontWeight.Normal)};TextButton(onClick={filtered=true}){Text("Outside our limits",fontSize=11.sp,fontWeight=if(filtered)FontWeight.SemiBold else FontWeight.Normal)}}
        if(filtered)(room.options.ifEmpty{m.data.catalog}).map{Planner.evaluate(it,room.members,m.data)}.filter{!it.eligible}.forEach{result->Column(Modifier.fillMaxWidth().glass().padding(17.dp),verticalArrangement=Arrangement.spacedBy(9.dp)){Heading(result.candidate.name,17);Caption(result.reasons.joinToString("\n"))}}
        else {
            Orbit(room.members,room.options.ifEmpty{m.data.catalog},ranked,selected?.id?:"",ready=room.allReady,onMember={if(room.local)m.persona=it.id},onIdea={idea->if(ranked.any{it.id==idea.id})m.selected=idea.id else filtered=true},onCentre={})
            if(selected!=null){PlanCard(selected,m.explanations.firstOrNull{it.id==selected.id}.takeIf{m.explanationRevision==room.revision}){m.selected=selected.id;m.sheet="details"};Action("Explain this shortlist",true,enabled=!m.busy){m.sheet="cloud"};Caption("The lowest individual fit comes first. Every shared limit is respected.");ranked.take(3).filter{it.id!=selected.id}.forEach{rank->PlanCard(rank){m.selected=rank.id;m.sheet="details"}}}
            else {Heading(if(room.allReady)"Let’s find a little more room."else"Good plans take everyone.",20);Caption(if(room.allReady)"No idea meets every requirement. Decide together whether to edit a limit."else"Everyone needs to share a preference card.")}
        }
        Caption(if(room.options.isEmpty())"Toronto sample catalogue. Costs, hours, access and travel are fixtures. Photos are illustrative."else"Activities and access are host-reported. Travel is approximate. Verify current details before going.")
    }
}
@Composable fun VotingPanel(m:MeetModel,room:PlanRoom){val p=room.proposal?:return;val rank=m.rankings.firstOrNull{it.id==p.candidateId}?:return;val context=LocalContext.current
    Column(Modifier.fillMaxWidth().background(MHDesign.accentSoft.copy(alpha=.6f),RoundedCornerShape(20.dp)).padding(20.dp),verticalArrangement=Arrangement.spacedBy(16.dp)){
        Text(if(room.status=="confirmed")"IT’S A PLAN"else"A PLAN ON THE TABLE",fontSize=10.sp,color=MHDesign.accent);Heading(rank.candidate.name,23);Caption("${room.date} · ${timeLabel(p.startMinute)} · ${rank.candidate.venue}")
        if(room.status=="confirmed")Action("Add to calendar"){shareCalendar(context,room,rank.candidate)}else {
            Row(horizontalArrangement=Arrangement.spacedBy(6.dp)){listOf("yes" to "I’m in","maybe" to "Discuss","no" to "Change it").forEach{(choice,label)->Action(label,outlined=room.votes[m.myId]?.choice!=choice,enabled=!m.busy){m.run{m.vote(choice)}}}}
            room.members.forEach{member->Caption("${member.name} · ${room.votes[member.id]?.takeIf{it.revision==p.revision&&it.candidateId==p.candidateId}?.choice?:"Not voted"}")}
            if(m.isHost)Action("Everyone’s in. Make it happen.",enabled=room.canConfirm&&!m.busy){m.run{m.confirm()}}
        }
    }
}
@Composable fun PrivacyScreen(m:MeetModel){Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),verticalArrangement=Arrangement.spacedBy(22.dp)){
    Heading("Bring yourself.\nKeep your private thoughts.",28)
    listOf("Your words stay here." to "Private notes use only an on-device model on supported hardware. There is no cloud fallback. Manual controls always remain available.","Your card, your call." to "Review your neighbourhood, budget, travel limit, interests, availability and access requirements before sharing with room members.","Everyone’s limits count." to "Hard limits filter the shortlist before scoring. Every current member must accept the same proposal before confirmation.","A neighbourhood is enough." to "Travel uses a neighbourhood centre. We don’t request a live location or street address. Photos and sample venue data are illustrative.","Cloud explanations are a choice." to "After approval, shared cards and eligible ideas are sent through Firebase AI Logic. Your private note is excluded. Anyone with your invitation can join and see the shared room.").forEach{(title,body)->Column(Modifier.fillMaxWidth().glass().padding(20.dp),verticalArrangement=Arrangement.spacedBy(13.dp)){Heading(title,18);Text(body,fontSize=14.sp,color=MHDesign.secondary,lineHeight=21.sp)}}
    Heading("Where AI actually ran",20);if(m.receipts.isEmpty())Caption("No AI requests in this session yet.");m.receipts.forEach{Caption("${it.provider} · ${it.milliseconds} ms")}
}}
fun shareText(context:android.content.Context,title:String,text:String){context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply{type="text/plain";putExtra(Intent.EXTRA_SUBJECT,title);putExtra(Intent.EXTRA_TEXT,text)},"Share MeetHalfway"))}
fun shareCalendar(context:android.content.Context,room:PlanRoom,idea:ActivityIdea){
    val start=room.proposal?.startMinute?:960
    fun stamp(minute:Int)=LocalDate.parse(room.date).plusDays((minute/1440).toLong()).format(DateTimeFormatter.BASIC_ISO_DATE)+"T%02d%02d00".format(minute/60%24,minute%60)
    fun escape(text:String)=text.replace("\\","\\\\").replace("\n","\\n").replace(",","\\,").replace(";","\\;")
    val content=listOf("BEGIN:VCALENDAR","VERSION:2.0","PRODID:-//MeetHalfway//Toronto//EN","BEGIN:VTIMEZONE","TZID:America/Toronto","BEGIN:STANDARD","DTSTART:19701101T020000","RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU","TZOFFSETFROM:-0400","TZOFFSETTO:-0500","END:STANDARD","BEGIN:DAYLIGHT","DTSTART:19700308T020000","RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU","TZOFFSETFROM:-0500","TZOFFSETTO:-0400","END:DAYLIGHT","END:VTIMEZONE","BEGIN:VEVENT","UID:${room.id}@meethalfway.app","DTSTAMP:"+DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'").withZone(ZoneOffset.UTC).format(Instant.now()),"DTSTART;TZID=America/Toronto:${stamp(start)}","DTEND;TZID=America/Toronto:${stamp(start+90)}","SUMMARY:${escape(room.title)}","LOCATION:${escape(idea.venue)}","DESCRIPTION:Verify current venue details before going.","END:VEVENT","END:VCALENDAR").joinToString("\r\n")
    val directory=File(context.cacheDir,"calendar").apply{mkdirs()};val file=File(directory,"meethalfway-plan.ics").apply{writeText(content)};val uri=FileProvider.getUriForFile(context,"${context.packageName}.files",file)
    context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply{type="text/calendar";putExtra(Intent.EXTRA_STREAM,uri);addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)},"Add MeetHalfway plan"))
}
