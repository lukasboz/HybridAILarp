package app.meethalfway.mobile

import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.*
import java.time.LocalDate
import java.time.ZoneId

data class PreferenceCard(val areaId:String,val maxSpend:Int,val maxTravel:Int,val mode:String,val interests:List<String>,val earliest:Int,val latest:Int,val quiet:Boolean,val indoors:Boolean,val stepFree:Boolean) {
    fun fields():Map<String,Any> = mapOf("areaId" to areaId,"maxSpend" to maxSpend,"maxTravel" to maxTravel,"mode" to mode,"interests" to interests,"earliest" to earliest,"latest" to latest,"quiet" to quiet,"indoors" to indoors,"stepFree" to stepFree)
    fun valid(data:Experience):PreferenceCard {
        require(data.areas.any{it.id==areaId} && maxSpend in 0..200 && maxTravel in 5..120 && mode in listOf("transit","walk","bike") && interests.size in 1..6 && interests.toSet().size==interests.size && interests.all{key->data.interests.any{it.id==key}} && earliest in 360..1380 && latest in 390..1440 && latest-earliest>=90){"Check your preferences and allow at least 90 minutes."};return this
    }
    companion object {
        val keys=setOf("areaId","maxSpend","maxTravel","mode","interests","earliest","latest","quiet","indoors","stepFree")
        fun parse(v:JSONObject):PreferenceCard {
            require(v.keys().asSequence().toSet()==keys){"The draft contains an unsupported field. Your private note was not shared."}
            for(key in listOf("maxSpend","maxTravel","earliest","latest"))require(v.get(key) is Number && v.getDouble(key)==v.getInt(key).toDouble()){"Invalid numeric preference."}
            for(key in listOf("quiet","indoors","stepFree"))require(v.get(key) is Boolean){"Invalid setting."}
            return PreferenceCard(v.getString("areaId"),v.getInt("maxSpend"),v.getInt("maxTravel"),v.getString("mode"),v.getJSONArray("interests").strings(),v.getInt("earliest"),v.getInt("latest"),v.getBoolean("quiet"),v.getBoolean("indoors"),v.getBoolean("stepFree"))
        }
    }
}
data class Area(val id:String,val name:String,val lat:Double,val lng:Double)
data class Interest(val id:String,val name:String)
data class ActivityIdea(val id:String,val name:String,val venue:String,val area:String,val lat:Double,val lng:Double,val cost:Int,val tags:List<String>,val noise:Int,val indoor:Boolean,val stepFree:Boolean?,val theme:String,val description:String,val url:String,val duration:Int,val windows:List<Pair<Int,Int>>,val dataSource:String?=null) {
    val imageName get()=mapOf("games" to "games","art" to "art","studio" to "art","library" to "coffee","market" to "food","park" to "park","picnic" to "park","water" to "water")[theme]?:"coffee"
    fun json():JSONObject=JSONObject(mapOf("id" to id,"name" to name,"venue" to venue,"area" to area,"lat" to lat,"lng" to lng,"cost" to cost,"tags" to tags,"noise" to noise,"indoor" to indoor,"stepFree" to (stepFree?:JSONObject.NULL),"theme" to theme,"description" to description,"url" to url,"duration" to duration,"windows" to windows.map{listOf(it.first,it.second)},"dataSource" to (dataSource?:JSONObject.NULL)))
    companion object {fun parse(v:JSONObject)=ActivityIdea(v.getString("id"),v.getString("name"),v.getString("venue"),v.getString("area"),v.getDouble("lat"),v.getDouble("lng"),v.getInt("cost"),v.getJSONArray("tags").strings(),v.getInt("noise"),v.getBoolean("indoor"),if(v.isNull("stepFree"))null else v.getBoolean("stepFree"),v.getString("theme"),v.getString("description"),v.getString("url"),v.getInt("duration"),v.getJSONArray("windows").objectsOrArrays().map{val a=it as JSONArray;a.getInt(0) to a.getInt(1)},v.optString("dataSource").takeIf{it.isNotEmpty()&&it!="null"})}
}
data class Member(val id:String,val name:String,val card:PreferenceCard?,val inviteId:String?=null) {
    fun json()=JSONObject(mapOf("id" to id,"name" to name,"card" to (card?.fields()?:JSONObject.NULL),"inviteId" to (inviteId?:JSONObject.NULL)))
    companion object {fun parse(v:JSONObject)=Member(v.getString("id"),v.getString("name"),v.optJSONObject("card")?.let{PreferenceCard.parse(it)},v.optString("inviteId").takeIf{it.isNotEmpty()&&it!="null"})}
}
data class Proposal(val candidateId:String,val startMinute:Int,val revision:Int)
data class Vote(val choice:String,val candidateId:String,val revision:Int)
data class PlanRoom(val id:String,val title:String,val date:String,val ownerId:String,val memberIds:List<String>,val status:String="gathering",val revision:Int=0,val proposal:Proposal?=null,val members:List<Member> = emptyList(),val votes:Map<String,Vote> = emptyMap(),val options:List<ActivityIdea> = emptyList(),val inviteId:String?=null,val local:Boolean=true) {
    val allReady get()=members.isNotEmpty()&&members.size==memberIds.size&&members.all{it.card!=null}
    val canConfirm get()=proposal?.let{p->members.size>=2&&allReady&&members.all{m->votes[m.id]?.let{it.choice=="yes"&&it.candidateId==p.candidateId&&it.revision==p.revision}==true}}==true
    fun reset()=copy(status="gathering",revision=revision+1,proposal=null,votes=emptyMap())
    fun json():JSONObject=JSONObject(mapOf("id" to id,"title" to title,"date" to date,"ownerId" to ownerId,"memberIds" to memberIds,"status" to status,"revision" to revision,"proposal" to (proposal?.let{mapOf("candidateId" to it.candidateId,"startMinute" to it.startMinute,"revision" to it.revision)}?:JSONObject.NULL),"members" to members.map{it.json()},"votes" to votes.mapValues{(_,v)->mapOf("choice" to v.choice,"candidateId" to v.candidateId,"revision" to v.revision)},"options" to options.map{it.json()},"inviteId" to (inviteId?:JSONObject.NULL),"local" to local))
    companion object {fun parse(v:JSONObject):PlanRoom {
        val p=v.optJSONObject("proposal");val vs=v.optJSONObject("votes")?:JSONObject()
        return PlanRoom(v.getString("id"),v.getString("title"),v.getString("date"),v.getString("ownerId"),v.getJSONArray("memberIds").strings(),v.getString("status"),v.getInt("revision"),p?.let{Proposal(it.getString("candidateId"),it.getInt("startMinute"),it.getInt("revision"))},v.getJSONArray("members").objects().map{Member.parse(it)},vs.keys().asSequence().associateWith{key->vs.getJSONObject(key).let{Vote(it.getString("choice"),it.getString("candidateId"),it.getInt("revision"))}},v.getJSONArray("options").objects().map{ActivityIdea.parse(it)},v.optString("inviteId").takeIf{it.isNotEmpty()&&it!="null"},v.getBoolean("local"))
    }}
}
data class Experience(val areas:List<Area>,val catalog:List<ActivityIdea>,val interests:List<Interest>,val members:List<Member>,val defaultCard:PreferenceCard) {
    companion object {fun parse(text:String):Experience {val v=JSONObject(text);return Experience(v.getJSONArray("areas").objects().map{Area(it.getString("id"),it.getString("name"),it.getDouble("lat"),it.getDouble("lng"))},v.getJSONArray("catalog").objects().map{ActivityIdea.parse(it)},v.getJSONArray("interests").objects().map{Interest(it.getString("id"),it.getString("name"))},v.getJSONArray("members").objects().map{Member.parse(it)},PreferenceCard.parse(v.getJSONObject("defaultCard")))}}
}
data class IndividualFit(val memberId:String,val score:Int,val travel:Int,val matches:Int)
data class RankedPlan(val candidate:ActivityIdea,val eligible:Boolean,val reasons:List<String>,val fits:List<IndividualFit>,val start:Int?) {
    val id get()=candidate.id
    val minFit get()=fits.minOfOrNull{it.score}?:0
    val meanFit get()=if(fits.isEmpty())0 else floor(fits.map{it.score}.average()+0.5).toInt()
    val maxTravel get()=fits.maxOfOrNull{it.travel}?:0
}
object Planner {
    fun evaluate(c:ActivityIdea,members:List<Member>,data:Experience):RankedPlan {
        if(members.isEmpty()||members.any{it.card==null||runCatching{it.card.valid(data)}.isFailure})return RankedPlan(c,false,listOf("Waiting for everyone’s preferences."),emptyList(),null)
        val cards=members.map{it.card!!};val earliest=cards.maxOf{it.earliest};val latest=cards.minOf{it.latest}
        val slot=c.windows.firstOrNull{min(it.second,latest)-max(it.first,earliest)>=c.duration}
        val travel=cards.map{p->val a=data.areas.first{it.id==p.areaId};val rad=PI/180;val v=sin((c.lat-a.lat)*rad/2).pow(2)+cos(a.lat*rad)*cos(c.lat*rad)*sin((c.lng-a.lng)*rad/2).pow(2);val km=6371*2*atan2(sqrt(v),sqrt(1-v));ceil(km*1.35/(mapOf("transit" to 18.0,"walk" to 4.5,"bike" to 12.0).getValue(p.mode))*60+(if(p.mode=="transit")10 else 3)).toInt()}
        val reasons=mutableListOf<String>()
        if(slot==null)reasons+="No shared 90-minute time window."
        if(cards.any{c.cost>it.maxSpend})reasons+="Above someone’s shared spending limit."
        if(cards.indices.any{travel[it]>cards[it].maxTravel})reasons+="Beyond someone’s travel limit."
        if(cards.any{it.quiet}&&c.noise>1)reasons+="Doesn’t meet the quiet-setting requirement."
        if(cards.any{it.indoors}&&!c.indoor)reasons+="An indoor setting is required."
        if(cards.any{it.stepFree}&&c.stepFree!=true)reasons+="Step-free access hasn’t been confirmed."
        val fits=cards.mapIndexed{i,p->val matches=p.interests.count{it in c.tags};val interest=matches.toDouble()/min(p.interests.size,c.tags.size);val affordability=if(p.maxSpend==0)1.0 else 1-c.cost.toDouble()/max(p.maxSpend,1);val convenience=1-min(travel[i].toDouble()/p.maxTravel,1.0);IndividualFit(members[i].id,floor(45+interest*30+affordability*10+convenience*15+0.5).toInt().coerceIn(0,100),travel[i],matches)}
        return RankedPlan(c,reasons.isEmpty(),reasons,fits,slot?.let{max(it.first,earliest)})
    }
    fun rank(members:List<Member>,catalog:List<ActivityIdea>,data:Experience)=catalog.map{evaluate(it,members,data)}.filter{it.eligible}.sortedWith(compareByDescending<RankedPlan>{it.minFit}.thenByDescending{it.meanFit}.thenBy{it.maxTravel}.thenBy{it.candidate.cost}.thenBy{it.id})
    fun rank(room:PlanRoom,data:Experience)=rank(room.members,room.options.ifEmpty{data.catalog},data)
}
data class Explanation(val id:String,val reason:String,val tradeoff:String)
data class AIReceipt(val provider:String,val milliseconds:Long)
fun JSONArray.strings()=(0 until length()).map{getString(it)}
fun JSONArray.objects()=(0 until length()).map{getJSONObject(it)}
fun JSONArray.objectsOrArrays()=(0 until length()).map{get(it)}
fun timeLabel(n:Int):String {val hour=n/60%24;return "${if(hour%12==0)12 else hour%12}${if(n%60==0)"" else ":%02d".format(n%60)}${if(hour<12)"am" else "pm"}"}
fun nextSaturday():String {val today=LocalDate.now(ZoneId.of("America/Toronto"));val delta=(6-today.dayOfWeek.value+7)%7;return today.plusDays((if(delta==0)7 else delta).toLong()).toString()}
