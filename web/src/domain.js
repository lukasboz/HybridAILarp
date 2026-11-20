import { AREAS, CATALOG, INTERESTS } from './catalog.js';

export const CARD_KEYS = ['areaId','maxSpend','maxTravel','mode','interests','earliest','latest','quiet','indoors','stepFree'];
export const DEFAULT_CARD = {areaId:'annex',maxSpend:30,maxTravel:45,mode:'transit',interests:['games','art','coffee'],earliest:960,latest:1320,quiet:false,indoors:false,stepFree:false};
export function validateCard(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw new Error('Preference card must be an object.');
  if (Object.keys(input).some(key => !CARD_KEYS.includes(key))) throw new Error('This card contains an unapproved field.');
  const card = structuredClone(input);
  if (!AREAS.some(a=>a.id===card.areaId)) throw new Error('Choose a Toronto neighbourhood.');
  for (const [key,min,max] of [['maxSpend',0,200],['maxTravel',5,120],['earliest',360,1380],['latest',390,1440]]) {
    if (!Number.isInteger(card[key]) || card[key]<min || card[key]>max) throw new Error(`Invalid ${key}.`);
  }
  if (card.latest-card.earliest<90) throw new Error('Allow at least 90 minutes for your plan.');
  if (!['transit','walk','bike'].includes(card.mode)) throw new Error('Choose a travel mode.');
  if (!Array.isArray(card.interests) || card.interests.length<1 || card.interests.length>6 || new Set(card.interests).size!==card.interests.length || card.interests.some(t=>!INTERESTS.some(i=>i.id===t))) throw new Error('Choose one to six different interests.');
  for (const key of ['quiet','indoors','stepFree']) if (typeof card[key]!=='boolean') throw new Error(`Invalid ${key}.`);
  return card;
}
export function publicCard(input) {
  return validateCard(Object.fromEntries(CARD_KEYS.map(k=>[k,input[k]])));
}
export function kmBetween(a,b) {
  const rad=x=>x*Math.PI/180;
  const x=Math.sin(rad(b.lat-a.lat)/2)**2+Math.cos(rad(a.lat))*Math.cos(rad(b.lat))*Math.sin(rad(b.lng-a.lng)/2)**2;
  return 6371*2*Math.atan2(Math.sqrt(x),Math.sqrt(1-x));
}
export function travelMinutes(card,candidate) {
  const area=AREAS.find(a=>a.id===card.areaId);
  if (!area) return Infinity;
  const speeds={transit:18,walk:4.5,bike:12};
  const overhead=card.mode==='transit'?10:3;
  return Math.ceil(kmBetween(area,candidate)*1.35/speeds[card.mode]*60+overhead);
}
export function evaluateCandidate(candidate,members) {
  const reasons=[];
  if (!members.length || members.some(m=>!m.card)) return {candidate,eligible:false,reasons:['Waiting for everyone’s preferences.'],fits:[],start:null};
  const cards=members.map(m=>validateCard(m.card));
  const earliest=Math.max(...cards.map(c=>c.earliest));
  const latest=Math.min(...cards.map(c=>c.latest));
  const slot=candidate.windows.map(([a,b])=>[Math.max(a,earliest),Math.min(b,latest)]).find(([a,b])=>b-a>=candidate.duration);
  if (!slot) reasons.push('No shared 90-minute time window.');
  if (cards.some(c=>candidate.cost>c.maxSpend)) reasons.push('Above someone’s shared spending limit.');
  const travels=cards.map(c=>travelMinutes(c,candidate));
  if (cards.some((c,i)=>travels[i]>c.maxTravel)) reasons.push('Beyond someone’s travel limit.');
  if (cards.some(c=>c.quiet)&&candidate.noise>1) reasons.push('Doesn’t meet the quiet-setting requirement.');
  if (cards.some(c=>c.indoors)&&!candidate.indoor) reasons.push('An indoor setting is required.');
  if (cards.some(c=>c.stepFree)&&candidate.stepFree!==true) reasons.push('Step-free access hasn’t been confirmed.');
  const fits=cards.map((c,i)=>{
    const matches=c.interests.filter(t=>candidate.tags.includes(t)).length;
    const interest=matches/Math.min(c.interests.length,candidate.tags.length);
    const affordability=c.maxSpend===0?1:1-candidate.cost/Math.max(c.maxSpend,1);
    const convenience=1-Math.min(travels[i]/c.maxTravel,1);
    const score=Math.max(0,Math.min(100,Math.round(45+interest*30+affordability*10+convenience*15)));
    return {memberId:members[i].id,score,travel:travels[i],matches};
  });
  return {candidate,eligible:!reasons.length,reasons,fits,start:slot?.[0]??null,
    minFit:Math.min(...fits.map(f=>f.score)),meanFit:Math.round(fits.reduce((n,f)=>n+f.score,0)/fits.length),
    maxTravel:Math.max(...travels)};
}
export function rankPlans(members,catalog=CATALOG) {
  const all=catalog.map(c=>evaluateCandidate(c,members));
  const eligible=all.filter(r=>r.eligible).sort((a,b)=>b.minFit-a.minFit || b.meanFit-a.meanFit || a.maxTravel-b.maxTravel || a.candidate.cost-b.candidate.cost || a.candidate.id.localeCompare(b.candidate.id));
  return {eligible,rejected:all.filter(r=>!r.eligible)};
}
export function validateOption(input) {
  const keys=['name','venue','areaId','cost','tags','noise','indoor','stepFree','description','url','opens','closes'];
  if(!input||typeof input!=='object'||Object.keys(input).some(k=>!keys.includes(k)))throw new Error('The activity contains an unsupported field.');
  for(const [field,min,max] of [['name',1,70],['venue',1,100],['description',1,300],['url',0,1000]]){
    if(typeof input[field]!=='string'||input[field].length<min||input[field].length>max)throw new Error(`Check the activity ${field}.`);
  }
  if(input.url&&!/^https:\/\//.test(input.url))throw new Error('Venue links must use HTTPS.');
  if(!AREAS.some(a=>a.id===input.areaId))throw new Error('Choose a Toronto neighbourhood.');
  if(!Number.isInteger(input.cost)||input.cost<0||input.cost>200)throw new Error('Activity cost must be between $0 and $200.');
  if(!Array.isArray(input.tags)||!input.tags.length||input.tags.length>6||new Set(input.tags).size!==input.tags.length||input.tags.some(t=>!INTERESTS.some(i=>i.id===t)))throw new Error('Choose valid activity interests.');
  if(![1,2,3].includes(input.noise)||typeof input.indoor!=='boolean'||![true,null].includes(input.stepFree))throw new Error('Check the activity setting and access details.');
  if(!Number.isInteger(input.opens)||!Number.isInteger(input.closes)||input.opens<360||input.closes>1440||input.closes-input.opens<90)throw new Error('The activity needs a valid 90-minute opening window.');
  return structuredClone(input);
}
export function optionCandidate(option) {
  const area=AREAS.find(a=>a.id===option.areaId);
  return {...option,area:area.name,lat:area.lat,lng:area.lng,duration:90,windows:[[option.opens,option.closes]],dataSource:'host',theme:{games:'games',art:'art',food:'market',coffee:'library',outdoors:'park',music:'water'}[option.tags[0]]};
}
export function roomCatalog(room) {return room.options?.length?room.options.map(optionCandidate):CATALOG;}
export function rankRoom(room) {return rankPlans(room.members,roomCatalog(room));}
export function cloudPayload(room,ranked) {
  // An explicit allowlist is the boundary: private notes never enter this payload.
  return {city:'Toronto',date:room.date,
    members:room.members.filter(m=>m.card).map(m=>({id:m.id,card:publicCard(m.card)})),
    candidates:ranked.slice(0,3).map(r=>({id:r.candidate.id,name:r.candidate.name,description:r.candidate.description,estimatedCost:r.candidate.cost,minFit:r.minFit,startMinute:r.start,fits:r.fits})),
    dataWarning:ranked.every(r=>r.candidate.dataSource==='host')?'Activities, costs, hours and access were provided by the host. Travel is an approximate neighbourhood estimate. Do not invent live availability, bookings or independently verified access.':'All prices, hours and travel are demonstration estimates. Do not invent live availability, bookings or accessibility information.'};
}
export function validateExplanations(data,allowedIds) {
  if (!data || !Array.isArray(data.explanations) || !data.explanations.length || data.explanations.length>3) throw new Error('AI returned an invalid explanation.');
  const seen=new Set();
  return data.explanations.map(e=>{
    if (!allowedIds.includes(e.id) || seen.has(e.id) || typeof e.reason!=='string' || e.reason.length<1 || e.reason.length>450 || typeof e.tradeoff!=='string' || e.tradeoff.length>250) throw new Error('AI returned an unsupported plan or explanation.');
    seen.add(e.id);return {id:e.id,reason:e.reason,tradeoff:e.tradeoff};
  });
}
export function parseJson(text) {
  if (typeof text!=='string' || text.length>16000) throw new Error('AI response was too large or empty.');
  return JSON.parse(text.replace(/^\s*```(?:json)?\s*/i,'').replace(/\s*```\s*$/,''));
}
export function canConfirm(room) {
  return !!room.proposal && room.members.length>=2 && room.members.every(m=>m.card && room.votes?.[m.id]?.choice==='yes' && room.votes[m.id].revision===room.proposal.revision && room.votes[m.id].candidateId===room.proposal.candidateId);
}
export function formatTime(minutes) {
  const h=Math.floor(minutes/60)%24,m=minutes%60;
  return `${h%12||12}${m?':'+String(m).padStart(2,'0'):''}${h<12?'am':'pm'}`;
}
export function nextSaturday(now=new Date()) {
  const date=new Date(now.getFullYear(),now.getMonth(),now.getDate()+((6-now.getDay()+7)%7||7),12);
  return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`;
}
export function formatDate(value) { return new Date(`${value}T12:00:00`).toLocaleDateString('en-CA',{weekday:'long',month:'short',day:'numeric'}); }
export function calendarFile(room,candidate) {
  const minute=room.proposal.startMinute;
  const stamp=n=>`${room.date.replaceAll('-','')}T${String(Math.floor(n/60)).padStart(2,'0')}${String(n%60).padStart(2,'0')}00`;
  const escape=s=>String(s).replace(/\\/g,'\\\\').replace(/\n/g,'\\n').replace(/,/g,'\\,').replace(/;/g,'\\;');
  return ['BEGIN:VCALENDAR','VERSION:2.0','PRODID:-//MeetHalfway//Toronto//EN','BEGIN:VTIMEZONE','TZID:America/Toronto','BEGIN:STANDARD','DTSTART:19701101T020000','RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU','TZOFFSETFROM:-0400','TZOFFSETTO:-0500','TZNAME:EST','END:STANDARD','BEGIN:DAYLIGHT','DTSTART:19700308T020000','RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU','TZOFFSETFROM:-0500','TZOFFSETTO:-0400','TZNAME:EDT','END:DAYLIGHT','END:VTIMEZONE','BEGIN:VEVENT',`UID:${room.id}-${room.proposal.revision}@meethalfway.app`,`DTSTAMP:${new Date().toISOString().replace(/[-:]/g,'').split('.')[0]}Z`,`DTSTART;TZID=America/Toronto:${stamp(minute)}`,`DTEND;TZID=America/Toronto:${stamp(minute+candidate.duration)}`,`SUMMARY:${escape(candidate.name)}`,`LOCATION:${escape(candidate.venue+', Toronto')}`,'DESCRIPTION:MeetHalfway group plan. Confirm venue hours\, prices and access before travelling.','END:VEVENT','END:VCALENDAR'].join('\r\n');
}
