package app.meethalfway.mobile
import android.animation.ValueAnimator
import android.graphics.BitmapFactory
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.semantics.*
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.*
import androidx.compose.ui.unit.*
import kotlin.math.*

val Inter=FontFamily(Font(R.font.inter_regular,FontWeight.Normal),Font(R.font.inter_medium,FontWeight.Medium),Font(R.font.inter_semibold,FontWeight.SemiBold))
@Composable fun MeetTheme(content: @Composable () -> Unit){MaterialTheme(colorScheme=lightColorScheme(primary=MHDesign.accent,background=MHDesign.canvas,surface=MHDesign.surface,onSurface=MHDesign.ink,onBackground=MHDesign.ink),typography=Typography(bodyLarge=TextStyle(fontFamily=Inter,fontSize=14.sp),bodyMedium=TextStyle(fontFamily=Inter,fontSize=13.sp),labelLarge=TextStyle(fontFamily=Inter,fontSize=13.sp,fontWeight=FontWeight.Medium))){CompositionLocalProvider(LocalTextStyle provides TextStyle(fontFamily=Inter,color=MHDesign.ink,fontSize=14.sp),content=content)}}
fun Modifier.glass(radius:Int=MHDesign.cardRadius):Modifier=shadow(5.dp,RoundedCornerShape(radius.dp),ambientColor=MHDesign.accent.copy(alpha=.04f),spotColor=MHDesign.accent.copy(alpha=.05f)).clip(RoundedCornerShape(radius.dp)).background(Brush.linearGradient(listOf(Color.White.copy(alpha=.95f),Color(0xFFF8F5FC).copy(alpha=.85f)))).border(1.dp,MHDesign.border,RoundedCornerShape(radius.dp))
@Composable fun Action(label:String,outlined:Boolean=false,enabled:Boolean=true,modifier:Modifier=Modifier,click:()->Unit){Button(onClick=click,enabled=enabled,modifier=modifier.heightIn(min=44.dp),shape=RoundedCornerShape(MHDesign.controlRadius.dp),colors=ButtonDefaults.buttonColors(containerColor=if(outlined)Color.White else MHDesign.accent,contentColor=if(outlined)MHDesign.secondary else Color.White),border=if(outlined)BorderStroke(1.dp,MHDesign.border)else null,contentPadding=PaddingValues(horizontal=14.dp,vertical=11.dp)){Text(label,fontSize=12.sp,fontFamily=Inter,fontWeight=FontWeight.Medium)}}
@Composable fun Heading(text:String,size:Int=MHDesign.headingSize){Text(text,fontSize=size.sp,fontWeight=FontWeight.SemiBold,lineHeight=(size+7).sp)}
@Composable fun Caption(text:String,modifier:Modifier=Modifier){Text(text,modifier,fontSize=11.sp,color=MHDesign.secondary,lineHeight=17.sp)}
@Composable fun Avatar(member:Member,index:Int=0,size:Int=34){val colors=listOf(Color(0xFFDDD9F2),Color(0xFFF7DDD2),Color(0xFFDCD5EE),Color(0xFFD4E0F2));Box(Modifier.size(size.dp).background(colors[index%4],CircleShape).border(2.dp,Color.White,CircleShape),contentAlignment=Alignment.Center){Text(member.name.take(2).uppercase(),fontSize=(size*.27).sp,fontWeight=FontWeight.SemiBold,color=MHDesign.secondary)}}
@Composable fun Photo(idea:ActivityIdea,modifier:Modifier=Modifier){val context=LocalContext.current;val bitmap=remember(idea.imageName){context.assets.open("shared/activities/${idea.imageName}.jpg").use{BitmapFactory.decodeStream(it).asImageBitmap()}};Image(bitmap,null,modifier,contentScale=ContentScale.Crop)}
@Composable fun Orb(modifier:Modifier=Modifier){val transition=rememberInfiniteTransition(label="orb");val scale by transition.animateFloat(.97f,1.03f,infiniteRepeatable(tween(3500),RepeatMode.Reverse),label="breathing");Box(modifier.graphicsLayer{scaleX=if(ValueAnimator.areAnimatorsEnabled())scale else 1f;scaleY=scaleX}.shadow(18.dp,CircleShape,ambientColor=MHDesign.accent.copy(alpha=.12f),spotColor=MHDesign.accent.copy(alpha=.1f)).clip(CircleShape).background(Brush.radialGradient(listOf(Color.White.copy(alpha=.9f),MHDesign.orb.copy(alpha=.8f),Color(0xFFBAC1E8).copy(alpha=.6f)),center=Offset(20f,15f),radius=240f)).border(1.dp,Color.White.copy(alpha=.7f),CircleShape)){Box(Modifier.fillMaxSize().padding(8.dp).border(1.dp,Color.White.copy(alpha=.5f),CircleShape));Box(Modifier.offset(16.dp,14.dp).size(30.dp,16.dp).blur(7.dp).background(Color.White.copy(alpha=.6f),CircleShape))}}
@Composable fun Orbit(members:List<Member>,ideas:List<ActivityIdea>,ranked:List<RankedPlan> = emptyList(),selected:String="",home:Boolean=false,ready:Boolean=true,height:Int=360,onMember:(Member)->Unit,onIdea:(ActivityIdea)->Unit,onCentre:()->Unit){
    BoxWithConstraints(Modifier.fillMaxWidth().height(height.dp)){
        val cx=maxWidth.value/2;val cy=height*.46f;val radius=min(maxWidth.value*.36f,min(height*.39f,210f));val people=min(radius*.53f,MHDesign.peopleRadius.toFloat());val tile=MHDesign.tileSize.toFloat()
        Box(Modifier.size(280.dp).offset((cx-140).dp,(cy-140).dp).background(Brush.radialGradient(listOf(MHDesign.orb.copy(alpha=.12f),Color.Transparent)),CircleShape))
        ideas.forEachIndexed{i,idea->val angle=i.toDouble()/ideas.size*2*PI-PI/2;val eligible=home||!ready||ranked.any{it.id==idea.id};Box(Modifier.offset((cx+cos(angle)*radius-tile/2).dp,(cy+sin(angle)*radius-(tile+4)/2).dp).size(tile.dp,(tile+4).dp).shadow(5.dp,RoundedCornerShape(12.dp)).clip(RoundedCornerShape(12.dp)).background(Color.White).border(if(selected==idea.id)2.dp else 1.dp,if(selected==idea.id)MHDesign.accent.copy(alpha=.5f)else MHDesign.border,RoundedCornerShape(12.dp)).alpha(if(eligible)1f else .25f).clickable(enabled=home||ready){onIdea(idea)}.semantics{contentDescription=idea.name+if(eligible)""else", outside shared limits";role=Role.Button}.padding(3.dp)){Photo(idea,Modifier.fillMaxSize().clip(RoundedCornerShape(9.dp)));if(!home)ranked.firstOrNull{it.id==idea.id}?.let{Text("${it.minFit}",fontSize=8.sp,color=MHDesign.accent,modifier=Modifier.align(Alignment.BottomEnd).background(Color.White,RoundedCornerShape(4.dp)).padding(2.dp))}}}
        Box(Modifier.offset((cx-MHDesign.orbSize/2).dp,(cy-MHDesign.orbSize/2).dp).size(MHDesign.orbSize.dp).then(if(home)Modifier.clickable(onClick=onCentre).semantics{contentDescription="Explore the sample group";role=Role.Button}else Modifier)){Orb(Modifier.fillMaxSize())}
        Text(if(home)"Find your halfway"else if(ready)"Common ground, found."else"Bringing everyone together.",fontSize=9.sp,color=MHDesign.secondary,modifier=Modifier.offset((cx-105).dp,(cy+MHDesign.orbSize/2+17).dp).width(210.dp),textAlign=androidx.compose.ui.text.style.TextAlign.Center)
        members.take(8).forEachIndexed{i,m->val angle=i.toDouble()/members.size*2*PI-PI/2;Column(Modifier.offset((cx+cos(angle)*people-42).dp,(cy+sin(angle)*people-25).dp).width(84.dp).clickable{onMember(m)},horizontalAlignment=Alignment.CenterHorizontally,verticalArrangement=Arrangement.spacedBy(4.dp)){Avatar(m,i,30);Text(m.name,fontSize=9.sp,color=MHDesign.secondary);Text(if(home)"Sample"else if(m.card==null)"Adding preferences"else"Ready",fontSize=7.sp,color=MHDesign.secondary.copy(alpha=.8f))}}
    }
}
@Composable fun PlanCard(rank:RankedPlan,explanation:Explanation?=null,click:()->Unit){Column(Modifier.fillMaxWidth().glass().padding(16.dp),verticalArrangement=Arrangement.spacedBy(13.dp)){
    Photo(rank.candidate,Modifier.fillMaxWidth().height(144.dp).clip(RoundedCornerShape(12.dp)))
    Row(verticalAlignment=Alignment.CenterVertically){Text("COMMON GROUND",fontSize=9.sp,color=MHDesign.accent);Spacer(Modifier.weight(1f));Text("${rank.minFit}",fontSize=22.sp,fontWeight=FontWeight.Medium,color=MHDesign.accent);Text("/100",fontSize=10.sp,color=MHDesign.secondary)}
    Heading(rank.candidate.name,20);Caption("${rank.candidate.venue} · ${rank.candidate.area}")
    Row(horizontalArrangement=Arrangement.spacedBy(12.dp)){Text(if(rank.candidate.cost==0)"Free"else"~$${rank.candidate.cost}",fontSize=10.sp);Text(timeLabel(rank.start?:960),fontSize=10.sp);Text("~${rank.maxTravel} min max",fontSize=10.sp)}
    explanation?.let{Text(it.reason,fontSize=13.sp);Caption("The tradeoff: "+it.tradeoff)}
    HorizontalDivider(color=MHDesign.border)
    Row(verticalAlignment=Alignment.CenterVertically){Text("✓ Within everyone’s limits",fontSize=10.sp,color=MHDesign.secondary);Spacer(Modifier.weight(1f));TextButton(onClick=click,contentPadding=PaddingValues(0.dp)){Text("Take a closer look",fontSize=10.sp)}}
}}
