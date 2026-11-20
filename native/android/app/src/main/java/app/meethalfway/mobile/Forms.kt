package app.meethalfway.mobile
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.*
import androidx.compose.ui.platform.LocalContext
import android.content.Intent
import android.net.Uri
import java.time.*

@Composable fun FormSection(title:String,content:@Composable ColumnScope.()->Unit){Column(Modifier.fillMaxWidth().glass().padding(18.dp),verticalArrangement=Arrangement.spacedBy(14.dp)){Text(title,fontSize=16.sp,fontWeight=FontWeight.Medium);content()}}
@Composable fun Field(label:String,value:String,limit:Int=100,singleLine:Boolean=true,update:(String)->Unit){OutlinedTextField(value,{update(it.take(limit))},Modifier.fillMaxWidth(),label={Text(label,fontSize=12.sp)},singleLine=singleLine,textStyle=LocalTextStyle.current.copy(fontSize=14.sp))}
@Composable fun Stepper(label:String,value:Int,min:Int,max:Int,step:Int=1,update:(Int)->Unit){Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically){Text(label,fontSize=13.sp,modifier=Modifier.weight(1f));TextButton(onClick={update((value-step).coerceAtLeast(min))},enabled=value>min){Text("−")};TextButton(onClick={update((value+step).coerceAtMost(max))},enabled=value<max){Text("+")}}}
@Composable fun SwitchField(label:String,value:Boolean,update:(Boolean)->Unit){Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically){Text(label,fontSize=13.sp,modifier=Modifier.weight(1f));Switch(value,update)}}
@Composable fun Choice(label:String,value:String,options:List<Pair<String,String>>,update:(String)->Unit){var expanded by remember{mutableStateOf(false)};Column{Text(label,fontSize=11.sp,color=MHDesign.secondary);Box{TextButton(onClick={expanded=true}){Text(options.firstOrNull{it.first==value}?.second?:value,fontSize=13.sp)};DropdownMenu(expanded,{expanded=false},Modifier.heightIn(max=320.dp)){options.forEach{(key,text)->DropdownMenuItem(text={Text(text,fontSize=13.sp)},onClick={update(key);expanded=false})}}}}}
@Composable fun PreferencesScreen(m:MeetModel){var card by remember(m.myId){mutableStateOf(m.currentCard)};var note by remember(m.myId){mutableStateOf("")}
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).imePadding().padding(20.dp),verticalArrangement=Arrangement.spacedBy(20.dp)){
        Heading("A little more you.",27);Caption("Tell us what works. Keep the reasons private.")
        FormSection("A private thought"){
            Field("Private note · stays on this device",note,2000,false){note=it}
            Caption(if(m.localAI)"Gemini Nano is ready on this device."else"Local AI needs supported hardware. Manual controls keep your note private.")
            Action("Draft on this device",enabled=note.isNotBlank()&&!m.busy){m.run{val start=System.currentTimeMillis();card=NativeAI.extract(note,card,m.data);m.localAI=true;m.receipts=m.receipts+AIReceipt("Gemini Nano · on device",System.currentTimeMillis()-start);note=""}}
            Caption("No cloud fallback. You can always use the controls below.")
        }
        FormSection("Your editable card"){
            Choice("Neighbourhood",card.areaId,m.data.areas.map{it.id to it.name}){card=card.copy(areaId=it)}
            Stepper("Up to $${card.maxSpend} CAD",card.maxSpend,0,200,5){card=card.copy(maxSpend=it)}
            Stepper("Up to ${card.maxTravel} min travel",card.maxTravel,5,120,5){card=card.copy(maxTravel=it)}
            Choice("Travel",card.mode,listOf("transit" to "Transit","walk" to "Walk","bike" to "Bike")){card=card.copy(mode=it)}
            m.data.interests.forEach{i->SwitchField(i.name,i.id in card.interests){on->card=card.copy(interests=if(on)(card.interests+i.id).distinct()else if(card.interests.size>1)card.interests-i.id else card.interests)}}
        }
        FormSection("Make a little time"){
            Choice("From",card.earliest.toString(),(360..1380 step 30).map{it.toString() to timeLabel(it)}){card=card.copy(earliest=it.toInt())}
            Choice("Until",card.latest.toString(),(390..1440 step 30).map{it.toString() to timeLabel(it)}){card=card.copy(latest=it.toInt())};Caption("Allow at least 90 minutes together.")
        }
        FormSection("What matters"){SwitchField("A quiet setting",card.quiet){card=card.copy(quiet=it)};SwitchField("Keep it indoors",card.indoors){card=card.copy(indoors=it)};SwitchField("Confirmed step-free access",card.stepFree){card=card.copy(stepFree=it)}}
        Action("Review before sharing",enabled=!m.busy){runCatching{card.valid(m.data);note="";m.reviewCard=card;m.sheet="review"}.onFailure{m.message=it.localizedMessage}}
        Caption("Room members can see your approved card. Your private note is excluded.")
    }
}
@OptIn(ExperimentalMaterial3Api::class)
@Composable fun MeetSheet(m:MeetModel){val context=LocalContext.current
    ModalBottomSheet(onDismissRequest={if(!m.busy)m.sheet=null},containerColor=MHDesign.canvas,shape=androidx.compose.foundation.shape.RoundedCornerShape(topStart=28.dp,topEnd=28.dp)){
        Column(Modifier.fillMaxWidth().heightIn(max=780.dp).verticalScroll(rememberScrollState()).imePadding().padding(horizontal=20.dp).padding(bottom=28.dp),verticalArrangement=Arrangement.spacedBy(20.dp)){
            when(m.sheet){
                "create"->CreateForm(m)
                "join"->JoinForm(m)
                "option"->OptionForm(m)
                "idea"->m.preview?.let{idea->Photo(idea,Modifier.fillMaxWidth().height(220.dp));Heading(idea.name,27);Caption(idea.venue+" · Toronto sample idea");Text(idea.description,fontSize=14.sp);Caption("Illustrative photo. Costs, hours, access and travel are sample data. Shared preferences decide which ideas qualify.");Action("Make it a plan"){m.seed=idea.name;m.sheet="create"};Action("Explore the sample group",true){m.sheet=null;m.open("sample-toronto")}}
                "details"->{val rank=m.rankings.firstOrNull{it.id==m.selected};val room=m.room;if(rank!=null&&room!=null){PlanCard(rank){};Text(rank.candidate.description,fontSize=14.sp);Heading("A fit for each person",20);rank.fits.forEach{f->Row{Text(room.members.firstOrNull{it.id==f.memberId}?.name?:"Member",fontSize=12.sp);Spacer(Modifier.weight(1f));Caption("${f.score}/100 · ~${f.travel} min")}};Caption("Scores are planning estimates, not probabilities. Costs, hours and access are sample or host-reported. Verify current details.");if(rank.candidate.url.startsWith("https://"))Action("Visit venue website",true){context.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse(rank.candidate.url)))};if(m.isHost)Action("Put this to the group",enabled=room.members.size>=2&&!m.busy){m.run{m.propose(rank)}}}else Caption("The shortlist changed. Close this sheet and review the current plan.")}
                "review"->m.reviewCard?.let{card->Heading("Your card, your call.",27);Caption("Only these preferences will be shared with room members. Your private note is excluded.");FormSection("Approved preferences"){listOf("Neighbourhood" to (m.data.areas.firstOrNull{it.id==card.areaId}?.name?:card.areaId),"Spending limit" to "$${card.maxSpend} CAD","Travel limit" to "${card.maxTravel} min · ${card.mode}","Interests" to card.interests.joinToString(", "),"Available" to "${timeLabel(card.earliest)}–${timeLabel(card.latest)}","Quiet" to if(card.quiet)"Required"else"Flexible","Indoors" to if(card.indoors)"Required"else"Flexible","Step-free" to if(card.stepFree)"Confirmed access required"else"Flexible").forEach{(key,value)->Column{Text(key,fontSize=11.sp,color=MHDesign.secondary);Text(value,fontSize=14.sp)}}};Action(if(m.room==null)"Save on this device"else"Share this card",enabled=!m.busy){m.run{m.share(card)}};Caption("Updating a room card reopens the decision and makes earlier votes obsolete.")}
                "cloud"->{Heading("A little more context.",26);Text("This sends the room’s approved preference cards and three eligible ideas to Firebase AI Logic. The model explains the shortlist; it cannot override shared limits. Your private note is excluded.",fontSize=14.sp,color=MHDesign.secondary);Action("Explain these plans",enabled=!m.busy){m.run{m.explain()}};if(m.busy){CircularProgressIndicator();Caption("Preparing a cloud explanation…")}}
            }
        }
    }
}
@OptIn(ExperimentalMaterial3Api::class)
@Composable private fun ColumnScope.CreateForm(m:MeetModel){
    var title by remember{mutableStateOf(m.seed.ifBlank{"Saturday, sorted."})};var name by remember{mutableStateOf(if(m.name=="You")""else m.name)};var date by remember{mutableStateOf(nextSaturday())};var live by remember{mutableStateOf(m.configured)};var pickDate by remember{mutableStateOf(false)}
    Heading("Make a little time.",28);Caption("Start a plan. Bring your people. Find your halfway.")
    Field("Plan name",title,70){title=it};Field("Your first name",name,30){name=it}
    Action("Which day?  $date",true){pickDate=true}
    SwitchField("Live room",live){live=it&&m.configured};Caption(if(live)"Friends join from their own phones or browsers with a private link."else"Explore the flow on this device with sample people.")
    Action("Make a plan",enabled=!m.busy){m.run{m.create(title,date,name,live)}}
    if(pickDate){val state=rememberDatePickerState(initialSelectedDateMillis=LocalDate.parse(date).atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli());DatePickerDialog(onDismissRequest={pickDate=false},confirmButton={TextButton(onClick={state.selectedDateMillis?.let{date=Instant.ofEpochMilli(it).atZone(ZoneOffset.UTC).toLocalDate().toString()};pickDate=false}){Text("Choose day")}},dismissButton={TextButton(onClick={pickDate=false}){Text("Cancel")}}){DatePicker(state)}}
}
@Composable private fun ColumnScope.JoinForm(m:MeetModel){var link by remember{mutableStateOf("")};var name by remember{mutableStateOf(if(m.name=="You")""else m.name)}
    Heading("There’s room for you.",27);Caption("Paste the invitation your friend shared.");Field("Invitation link or code",link,1500){link=it};Field("Your first name",name,30){name=it};Caption("Joined members can see the room’s approved cards. Review your own card after joining.");Action("Join the room",enabled=!m.busy){m.run{m.join(link,name)}}
}
@Composable private fun ColumnScope.OptionForm(m:MeetModel){var name by remember{mutableStateOf("")};var venue by remember{mutableStateOf("")};var desc by remember{mutableStateOf("")};var url by remember{mutableStateOf("")};var area by remember{mutableStateOf("downtown")};var tag by remember{mutableStateOf("games")};var cost by remember{mutableIntStateOf(20)};var noise by remember{mutableIntStateOf(2)};var opens by remember{mutableIntStateOf(960)};var closes by remember{mutableIntStateOf(1320)};var indoor by remember{mutableStateOf(true)};var stepFree by remember{mutableStateOf(false)}
    Heading("Bring an idea to the table.",25);Caption("You provide the details. The first real activity replaces sample options.")
    Field("Activity name",name,70){name=it};Field("Venue or meeting place",venue,100){venue=it};Choice("Neighbourhood",area,m.data.areas.map{it.id to it.name}){area=it};Choice("Main interest",tag,m.data.interests.map{it.id to it.name}){tag=it};Stepper("~$$cost CAD per person",cost,0,200){cost=it};Field("What will you do?",desc,300,false){desc=it};Field("Venue link (optional HTTPS)",url,1000){url=it}
    Choice("From",opens.toString(),(360..1350 step 30).map{it.toString() to timeLabel(it)}){opens=it.toInt()};Choice("Until",closes.toString(),(450..1440 step 30).map{it.toString() to timeLabel(it)}){closes=it.toInt()};Choice("Setting",noise.toString(),listOf("1" to "Quiet","2" to "Conversation","3" to "Lively")){noise=it.toInt()};SwitchField("Indoors",indoor){indoor=it};SwitchField("I confirmed step-free access",stepFree){stepFree=it};Caption("Leave access off when unknown. Details are labelled host-reported. Adding an activity reopens voting.")
    Action("Add this activity",enabled=!m.busy){m.run{require(name.isNotBlank()&&venue.isNotBlank()&&desc.isNotBlank()&&(url.isEmpty()||url.startsWith("https://"))&&closes-opens>=90){"Check the activity details and allow 90 minutes."};val a=m.data.areas.first{it.id==area};m.addOption(ActivityIdea("",name,venue,a.name,a.lat,a.lng,cost,listOf(tag),noise,indoor,if(stepFree)true else null,themeFor(tag),desc,url,90,listOf(opens to closes),"host"),area)}}
}
