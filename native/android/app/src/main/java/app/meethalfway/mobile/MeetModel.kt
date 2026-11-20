package app.meethalfway.mobile

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.compose.runtime.*
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.ListenerRegistration
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.ZoneId

class MeetModel(app:Application):AndroidViewModel(app) {
    val data=Experience.parse(app.assets.open("shared/experience.json").bufferedReader().use{it.readText()})
    private val prefs=app.getSharedPreferences("meethalfway.native",0)
    private val service=FirebaseService()
    var tab by mutableStateOf("home")
    var roomId by mutableStateOf<String?>(null)
    var room by mutableStateOf<PlanRoom?>(null)
    var localRooms by mutableStateOf(runCatching{JSONArray(prefs.getString("rooms","[]")).objects().map{PlanRoom.parse(it)}}.getOrDefault(emptyList()))
    var cloudRooms by mutableStateOf<List<PlanRoom>>(emptyList())
    var uid by mutableStateOf("")
    var persona by mutableStateOf("alex")
    var name by mutableStateOf(prefs.getString("name","You")?:"You")
    var sheet by mutableStateOf<String?>(null)
    var busy by mutableStateOf(false)
    var message by mutableStateOf<String?>(null)
    var seed by mutableStateOf("")
    var selected by mutableStateOf("")
    var preview by mutableStateOf<ActivityIdea?>(null)
    var showPreferences by mutableStateOf(false)
    var reviewCard by mutableStateOf<PreferenceCard?>(null)
    var explanations by mutableStateOf<List<Explanation>>(emptyList())
    var explanationRevision:Int?=null
    var receipts by mutableStateOf<List<AIReceipt>>(emptyList())
    var localAI by mutableStateOf(false)
    val configured get()=FirebaseApp.getApps(getApplication()).isNotEmpty()
    val myId get()=if(room?.local==true)persona else uid
    val isHost get()=room?.ownerId==myId
    val rankings get()=room?.let{Planner.rank(it,data)}?:emptyList()
    val currentCard get()=room?.members?.firstOrNull{it.id==myId}?.card?:runCatching{PreferenceCard.parse(JSONObject(prefs.getString("card","")!!)).valid(data)}.getOrNull()?:data.defaultCard
    init {
        if(localRooms.none{it.id=="sample-toronto"})localRooms=listOf(PlanRoom("sample-toronto","Saturday, sorted.",nextSaturday(),"alex",data.members.map{it.id},members=data.members))+localRooms
        viewModelScope.launch{localAI=runCatching{NativeAI.localAvailable()}.getOrDefault(false)}
        if(configured)viewModelScope.launch{runCatching{uid=service.signIn();cloudRooms=service.rooms(uid)}.onFailure{message="Live connection unavailable. Samples remain available."}}
    }
    fun run(action:suspend()->Unit) {if(busy)return;busy=true;viewModelScope.launch{try{action()}catch(e:CancellationException){throw e}catch(e:Exception){message=e.localizedMessage?:"Something went wrong. Try again."}finally{busy=false}}}
    fun navigate(id:String){tab=id;showPreferences=false;if(id=="home"||id=="plans"){roomId=null;room=null}}
    fun open(id:String,asMember:String?=null){roomId=id;room=(localRooms+cloudRooms).firstOrNull{it.id==id};persona=asMember?:if(id=="sample-toronto")"alex" else room?.ownerId?:"";selected="";explanations=emptyList();explanationRevision=null;showPreferences=false;tab="plans"}
    fun watch(id:String):()->Unit {
        var registrations=emptyList<ListenerRegistration>()
        val job=viewModelScope.launch {
            if(localRooms.any{it.id==id})return@launch
            try {uid=service.signIn();ensureActive();registrations=service.watch(id,data,{value->if(roomId==id){room=value;if(explanationRevision!=value.revision)explanations=emptyList()}},{message=it})}catch(e:CancellationException){throw e}catch(e:Exception){message=e.localizedMessage}
        }
        return {job.cancel();registrations.forEach{it.remove()}}
    }
    private fun persist(){prefs.edit().putString("rooms",JSONArray(localRooms.map{it.json()}).toString()).apply()}
    fun mutate(change:(PlanRoom)->PlanRoom){val id=roomId?:return;localRooms=localRooms.map{if(it.id==id)change(it)else it};room=localRooms.firstOrNull{it.id==id};persist();if(explanationRevision!=room?.revision)explanations=emptyList()}
    suspend fun create(title:String,date:String,displayName:String,live:Boolean){
        val t=title.trim();val n=displayName.trim();require(t.isNotEmpty()&&t.length<=70&&n.isNotEmpty()&&n.length<=30&&LocalDate.parse(date)>=LocalDate.now(ZoneId.of("America/Toronto"))){"Add a plan name, your first name, and a date today or later."}
        name=n;prefs.edit().putString("name",n).apply()
        if(live){uid=service.signIn();val id=service.create(t,date,n,uid);cloudRooms=service.rooms(uid);sheet=null;open(id)}else {val me="device-"+FirebaseService.randomHex(8);val value=PlanRoom(FirebaseService.randomHex(18),t,date,me,listOf(me),members=listOf(Member(me,n,null)));localRooms=localRooms+value;persist();sheet=null;open(value.id)}
    }
    suspend fun join(input:String,displayName:String){val n=displayName.trim();require(n.isNotEmpty()&&n.length<=30){"Add your first name."};name=n;prefs.edit().putString("name",n).apply();uid=service.signIn();val id=service.join(input,n,uid);cloudRooms=service.rooms(uid);sheet=null;open(id)}
    suspend fun share(card:PreferenceCard){card.valid(data);val value=room;if(value!=null){if(value.local){val id=myId;mutate{it.copy(members=it.members.map{m->if(m.id==id)m.copy(card=card)else m}).reset()}}else service.share(value,uid,name,card)};prefs.edit().putString("card",JSONObject(card.fields()).toString()).apply();sheet=null;showPreferences=false;message=if(value!=null)"Your card is shared. Your private note stayed on this device."else"Preferences saved on this device."}
    suspend fun propose(plan:RankedPlan){val value=room?:return;val fresh=rankings.firstOrNull{it.id==plan.id}?:error("Review the current shortlist first.");check(isHost){"Only the host can propose a plan."};if(value.local)mutate{it.copy(status="voting",revision=it.revision+1,proposal=Proposal(fresh.id,fresh.start?:960,it.revision+1),votes=emptyMap())}else service.propose(value,fresh);sheet=null}
    suspend fun vote(choice:String){val value=room?:return;val p=value.proposal?:return;if(value.local){val id=myId;mutate{it.copy(votes=it.votes+(id to Vote(choice,p.candidateId,p.revision)))}}else service.vote(value,uid,choice)}
    suspend fun confirm(){val value=room?:return;check(value.canConfirm&&isHost){"Everyone needs to accept this version of the plan."};if(value.local)mutate{it.copy(status="confirmed")}else service.confirm(value)}
    fun addSample(){val value=room?:return;if(!value.local||value.members.size>=8)return;val n=value.members.size;val m=Member("sample-$n",listOf("Sam","Riley","Casey","Taylor","Jamie","Avery","Morgan","Robin")[n],data.defaultCard);mutate{it.copy(members=it.members+m,memberIds=it.memberIds+m.id).reset()}}
    suspend fun addOption(idea:ActivityIdea,area:String){val value=room?:return;check(isHost){"Only the host can add an activity."};if(value.local){val id=(1..12).map{"option-%02d".format(it)}.firstOrNull{id->value.options.none{it.id==id}}?:error("A room can hold twelve activities.");mutate{it.copy(options=it.options+idea.copy(id=id)).reset()}}else service.addOption(value,uid,idea,area);sheet=null}
    suspend fun explain(){val value=room?:return;val result=NativeAI.explain(value,rankings);receipts=receipts+result.second;check(room?.revision==value.revision&&room?.id==value.id){"The group changed. Explain the current shortlist instead."};explanations=result.first;explanationRevision=value.revision;sheet=null}
}
