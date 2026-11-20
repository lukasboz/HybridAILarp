package app.meethalfway.mobile

import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.*
import com.google.firebase.Timestamp
import kotlinx.coroutines.tasks.await
import java.security.SecureRandom
import org.json.JSONObject

class FirebaseService {
    private val db get()=FirebaseFirestore.getInstance()
    suspend fun signIn():String {check(FirebaseApp.getApps(appContext).isNotEmpty()){"Live rooms are unavailable in this build."};return FirebaseAuth.getInstance().currentUser?.uid?:FirebaseAuth.getInstance().signInAnonymously().await().user!!.uid}
    suspend fun rooms(uid:String)=db.collection("rooms").whereArrayContains("memberIds",uid).get().await().documents.mapNotNull{decodeRoom(it.id,it.data?:emptyMap())}
    suspend fun create(title:String,date:String,name:String,uid:String):String {
        val id=randomHex(18);val token=randomHex(24);val ref=db.collection("rooms").document(id);val batch=db.batch()
        batch.set(ref,mapOf("title" to title,"date" to date,"city" to "Toronto","ownerId" to uid,"memberIds" to listOf(uid),"status" to "gathering","revision" to 0,"proposal" to null,"lastJoinInviteId" to token,"createdAt" to FieldValue.serverTimestamp()))
        batch.set(ref.collection("members").document(uid),mapOf("name" to name,"card" to null,"inviteId" to token,"updatedAt" to FieldValue.serverTimestamp()))
        batch.set(db.collection("invites").document(token),mapOf("roomId" to id,"title" to title,"createdBy" to uid,"expiresAt" to Timestamp(java.util.Date(System.currentTimeMillis()+7*86400000L))))
        batch.commit().await();return id
    }
    suspend fun join(input:String,name:String,uid:String):String {
        val token=runCatching{android.net.Uri.parse(input).getQueryParameter("invite")}.getOrNull()?:input.trim()
        require(token.matches(Regex("^[a-f0-9]{48}$"))){"Paste a valid invitation link or code."}
        val invite=db.collection("invites").document(token).get().await();val id=invite.getString("roomId")?:error("The invitation is unavailable.")
        check((invite.getTimestamp("expiresAt")?.toDate()?.time?:0)>System.currentTimeMillis()){"That invitation has expired."}
        val ref=db.collection("rooms").document(id);val member=ref.collection("members").document(uid)
        if(runCatching{member.get().await().exists()}.getOrDefault(false))return id
        val batch=db.batch();batch.set(member,mapOf("name" to name,"card" to null,"inviteId" to token,"updatedAt" to FieldValue.serverTimestamp()))
        batch.update(ref,mapOf("memberIds" to FieldValue.arrayUnion(uid),"lastJoinInviteId" to token,"status" to "gathering","proposal" to null,"revision" to FieldValue.increment(1)))
        batch.commit().await();return id
    }
    suspend fun share(room:PlanRoom,uid:String,name:String,card:PreferenceCard) {
        val ref=db.collection("rooms").document(room.id);val batch=db.batch()
        batch.update(ref.collection("members").document(uid),mapOf("card" to card.fields(),"name" to name,"updatedAt" to FieldValue.serverTimestamp()))
        batch.update(ref,mapOf("proposal" to null,"status" to "gathering","revision" to FieldValue.increment(1)));batch.commit().await()
    }
    suspend fun propose(room:PlanRoom,rank:RankedPlan) {
        val ref=db.collection("rooms").document(room.id)
        db.runTransaction{tx->check(tx.get(ref).getLong("revision")==room.revision.toLong()){"The group changed. Review the updated shortlist."};val revision=room.revision+1;tx.update(ref,mapOf("status" to "voting","revision" to revision,"proposal" to mapOf("candidateId" to rank.id,"startMinute" to rank.start,"revision" to revision)))}.await()
    }
    suspend fun vote(room:PlanRoom,uid:String,choice:String) {val p=room.proposal?:error("There is no current proposal.");db.collection("rooms").document(room.id).collection("votes").document(uid).set(mapOf("choice" to choice,"candidateId" to p.candidateId,"revision" to p.revision,"updatedAt" to FieldValue.serverTimestamp())).await()}
    suspend fun confirm(room:PlanRoom){db.collection("rooms").document(room.id).update("status","confirmed").await()}
    suspend fun addOption(room:PlanRoom,uid:String,idea:ActivityIdea,areaId:String) {
        val slot=(1..12).map{"option-%02d".format(it)}.firstOrNull{id->room.options.none{it.id==id}}?:error("A room can hold twelve activities.")
        val ref=db.collection("rooms").document(room.id);val batch=db.batch()
        batch.set(ref.collection("options").document(slot),mapOf("name" to idea.name,"venue" to idea.venue,"areaId" to areaId,"cost" to idea.cost,"tags" to idea.tags,"noise" to idea.noise,"indoor" to idea.indoor,"stepFree" to idea.stepFree,"description" to idea.description,"url" to idea.url,"opens" to idea.windows[0].first,"closes" to idea.windows[0].second,"createdBy" to uid,"updatedAt" to FieldValue.serverTimestamp()))
        batch.update(ref.collection("members").document(uid),"updatedAt",FieldValue.serverTimestamp());batch.update(ref,mapOf("status" to "gathering","proposal" to null,"revision" to FieldValue.increment(1)));batch.commit().await()
    }
    fun watch(id:String,data:Experience,change:(PlanRoom)->Unit,error:(String)->Unit):List<ListenerRegistration> {
        val ref=db.collection("rooms").document(id);var root:PlanRoom?=null;var members=emptyList<Member>();var votes=emptyMap<String,Vote>();var options=emptyList<ActivityIdea>()
        fun emit(){root?.let{change(it.copy(members=members,votes=votes,options=options))}}
        return listOf(
            ref.addSnapshotListener{snap,e->if(e!=null)error(e.localizedMessage?:"Room unavailable")else {root=snap?.data?.let{decodeRoom(id,it)};emit()}},
            ref.collection("members").addSnapshotListener{snap,e->if(e!=null)error(e.localizedMessage?:"Members unavailable")else {members=snap?.documents?.mapNotNull{doc->val v=doc.data?:return@mapNotNull null;val name=v["name"] as? String?:return@mapNotNull null;Member(doc.id,name,(v["card"] as? Map<*,*>)?.let{runCatching{PreferenceCard.parse(JSONObject(it)).valid(data)}.getOrNull()},v["inviteId"] as? String)}?:emptyList();emit()}},
            ref.collection("votes").addSnapshotListener{snap,e->if(e!=null)error(e.localizedMessage?:"Votes unavailable")else {votes=snap?.documents?.mapNotNull{doc->val v=doc.data?:return@mapNotNull null;val choice=v["choice"] as? String?:return@mapNotNull null;val c=v["candidateId"] as? String?:return@mapNotNull null;doc.id to Vote(choice,c,(v["revision"] as Number).toInt())}?.toMap()?:emptyMap();emit()}},
            ref.collection("options").addSnapshotListener{snap,e->if(e!=null)error(e.localizedMessage?:"Activities unavailable")else {options=snap?.documents?.mapNotNull{doc->val v=doc.data?:return@mapNotNull null;val area=data.areas.firstOrNull{it.id==v["areaId"]}?:return@mapNotNull null;val tags=(v["tags"] as? List<*>)?.filterIsInstance<String>()?:return@mapNotNull null;ActivityIdea(doc.id,v["name"] as String,v["venue"] as String,area.name,area.lat,area.lng,(v["cost"] as Number).toInt(),tags,(v["noise"] as Number).toInt(),v["indoor"] as Boolean,v["stepFree"] as? Boolean,themeFor(tags.firstOrNull()?:""),v["description"] as String,v["url"] as String,90,listOf((v["opens"] as Number).toInt() to (v["closes"] as Number).toInt()),"host")}?:emptyList();emit()}}
        )
    }
    companion object {
        lateinit var appContext:android.content.Context
        fun randomHex(n:Int):String {val bytes=ByteArray(n);SecureRandom().nextBytes(bytes);return bytes.joinToString(""){"%02x".format(it)}}
        fun decodeRoom(id:String,v:Map<String,Any>):PlanRoom? {
            val title=v["title"] as? String?:return null;val date=v["date"] as? String?:return null;val owner=v["ownerId"] as? String?:return null;val ids=(v["memberIds"] as? List<*>)?.filterIsInstance<String>()?:return null
            val p=v["proposal"] as? Map<*,*>
            return PlanRoom(id,title,date,owner,ids,v["status"] as? String?:"gathering",(v["revision"] as? Number)?.toInt()?:0,p?.let{Proposal(it["candidateId"] as String,(it["startMinute"] as Number).toInt(),(it["revision"] as Number).toInt())},inviteId=v["lastJoinInviteId"] as? String,local=false)
        }
    }
}
fun themeFor(tag:String)=mapOf("games" to "games","art" to "art","coffee" to "library","food" to "market","outdoors" to "park","music" to "water")[tag]?:"library"
