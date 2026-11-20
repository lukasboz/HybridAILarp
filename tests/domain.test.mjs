import test from 'node:test';
import assert from 'node:assert/strict';
import { CATALOG, DEMO_MEMBERS } from '../web/src/catalog.js';
import { DEFAULT_CARD, validateCard, publicCard, rankPlans, rankRoom, validateOption, cloudPayload, validateExplanations, canConfirm, calendarFile, nextSaturday } from '../web/src/domain.js';

test('sample group has eligible plans in stable maximin order',()=>{
  const first=rankPlans(DEMO_MEMBERS),second=rankPlans([...DEMO_MEMBERS].reverse());
  assert.ok(first.eligible.length>=3);
  assert.deepEqual(first.eligible.map(x=>x.candidate.id),second.eligible.map(x=>x.candidate.id));
  for(let i=1;i<first.eligible.length;i++)assert.ok(first.eligible[i-1].minFit>=first.eligible[i].minFit);
});
test('no hard budget limit can be averaged away',()=>{
  const members=structuredClone(DEMO_MEMBERS);members[0].card.maxSpend=0;
  const result=rankPlans(members);assert.ok(result.eligible.length);assert.ok(result.eligible.every(r=>r.candidate.cost===0));
  assert.ok(result.rejected.find(r=>r.candidate.id==='college-games').reasons.some(r=>r.includes('spending')));
});
test('a hard travel limit is respected for every eligible result',()=>{
  const members=structuredClone(DEMO_MEMBERS);members[1].card.maxTravel=15;
  for(const r of rankPlans(members).eligible)assert.ok(r.fits.every(f=>f.travel<=members.find(m=>m.id===f.memberId).card.maxTravel));
});
test('unknown accessibility is excluded and fiction is explicitly labelled',()=>{
  const members=structuredClone(DEMO_MEMBERS);members.forEach(m=>{m.card.stepFree=true;m.card.maxSpend=40;m.card.maxTravel=120;});
  const result=rankPlans(members);assert.deepEqual(result.eligible.map(r=>r.candidate.id),['sample-studio']);
  assert.match(result.eligible[0].candidate.area,/fictional/);
});
test('disjoint time windows produce no recommendation',()=>{
  const members=structuredClone(DEMO_MEMBERS);members[0].card.earliest=600;members[0].card.latest=720;
  assert.equal(rankPlans(members).eligible.length,0);
});
test('waiting participants block the shortlist',()=>{
  assert.equal(rankPlans([{id:'a',card:DEFAULT_CARD},{id:'b',card:null}]).eligible.length,0);
});
test('quiet and indoor constraints filter before scoring',()=>{
  const members=structuredClone(DEMO_MEMBERS);members[0].card.quiet=true;members[1].card.indoors=true;
  assert.ok(rankPlans(members).eligible.every(r=>r.candidate.noise===1&&r.candidate.indoor));
});
test('card validation rejects pollution, missing fields, duplicates, types and extremes',()=>{
  for(const delta of [{note:'secret'},{maxSpend:-1},{maxSpend:NaN},{maxTravel:999},{quiet:'true'},{interests:['games','games']},{interests:['unknown']},{areaId:'home-address'},{earliest:1300,latest:1320}])assert.throws(()=>validateCard({...DEFAULT_CARD,...delta}));
  const missing={...DEFAULT_CARD};delete missing.mode;assert.throws(()=>validateCard(missing));
});
test('approved payload never includes private notes, precise location or extra member fields',()=>{
  const members=structuredClone(DEMO_MEMBERS);members[0].privateNote='NEVER_SEND_ME';members[0].exactLocation={lat:1,lng:2};
  const room={members,date:'2026-11-28',privateNote:'NEVER_SEND_ME'},ranked=rankPlans(members).eligible;
  const payload=cloudPayload(room,ranked),text=JSON.stringify(payload);
  assert.ok(!text.includes('NEVER_SEND_ME'));assert.ok(!text.includes('exactLocation'));assert.ok(!text.includes('"lat":'));assert.ok(!text.includes('"lng":'));
  assert.deepEqual(Object.keys(payload.members[0]),['id','card']);
});
test('public card uses an explicit allowlist',()=>{
  assert.deepEqual(publicCard({...DEFAULT_CARD,privateNote:'secret',exactLocation:{}}),DEFAULT_CARD);
});
test('AI explanations cannot inject a new venue or duplicate a candidate',()=>{
  assert.throws(()=>validateExplanations({explanations:[{id:'new-place',reason:'Try here',tradeoff:''}]},['ago']));
  assert.throws(()=>validateExplanations({explanations:[{id:'ago',reason:'One',tradeoff:''},{id:'ago',reason:'Two',tradeoff:''}]},['ago']));
  assert.deepEqual(validateExplanations({explanations:[{id:'ago',reason:'Fits the group.',tradeoff:'Costs more.'}]},['ago']),[{id:'ago',reason:'Fits the group.',tradeoff:'Costs more.'}]);
});
test('confirmation requires every current member accepting the exact current proposal',()=>{
  const room={members:structuredClone(DEMO_MEMBERS),proposal:{candidateId:'ago',revision:4},votes:{}};
  for(const m of room.members)room.votes[m.id]={candidateId:'ago',revision:4,choice:'yes'};
  assert.equal(canConfirm(room),true);room.votes.maya.revision=3;assert.equal(canConfirm(room),false);
  room.votes.maya.revision=4;room.votes.maya.candidateId='music';assert.equal(canConfirm(room),false);
  room.votes.maya.candidateId='ago';room.votes.maya.choice='maybe';assert.equal(canConfirm(room),false);
});
test('calendar uses Toronto time, escapes user text and contains a stable event ID',()=>{
  const candidate={...CATALOG[0],name:'Coffee, games; friends\nhello'};
  const ics=calendarFile({id:'room1',date:'2026-11-28',proposal:{revision:2,startMinute:1020}},candidate);
  assert.match(ics,/DTSTART;TZID=America\/Toronto:20261128T170000/);
  assert.match(ics,/UID:room1-2@meethalfway.app/);
  assert.ok(ics.includes('Coffee\\, games\\; friends\\nhello'));
  assert.match(ics,/BEGIN:VTIMEZONE/);
});
test('next Saturday is an ISO local calendar date even across a year boundary',()=>{
  assert.equal(nextSaturday(new Date(2026,11,31,12)),'2027-01-02');
});
test('host activities replace fixtures and are subject to the same hard limits',()=>{
  const option=validateOption({name:'Board games',venue:'Host-selected venue',areaId:'downtown',cost:20,tags:['games'],noise:1,indoor:true,stepFree:null,description:'A quiet game.',url:'https://example.org',opens:960,closes:1380});
  let result=rankRoom({members:DEMO_MEMBERS,options:[{id:'option-01',...option}]});
  assert.deepEqual(result.eligible.map(r=>r.candidate.id),['option-01']);assert.equal(result.eligible[0].candidate.dataSource,'host');
  option.cost=40;result=rankRoom({members:DEMO_MEMBERS,options:[{id:'option-01',...option}]});assert.equal(result.eligible.length,0);
  assert.throws(()=>validateOption({...option,url:'javascript:alert(1)'}));
});
