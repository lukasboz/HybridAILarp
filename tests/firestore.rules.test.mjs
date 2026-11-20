import test, {before,after,beforeEach} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,getDocs,collection,query,where,updateDoc,deleteDoc,writeBatch,serverTimestamp,Timestamp,arrayUnion,increment} from 'firebase/firestore';
import {DEFAULT_CARD} from '../web/src/domain.js';

const enabled=!!process.env.FIRESTORE_EMULATOR_HOST;
let env;
const roomId='a'.repeat(36),inviteId='b'.repeat(48);
const db=uid=>env.authenticatedContext(uid).firestore();
const member=(uid,name=uid)=>({name,card:null,inviteId,updatedAt:serverTimestamp()});
async function create(uid='host'){
  const store=db(uid),batch=writeBatch(store);
  batch.set(doc(store,'rooms',roomId),{title:'Saturday, sorted.',date:'2026-11-28',city:'Toronto',ownerId:uid,memberIds:[uid],status:'gathering',revision:0,proposal:null,lastJoinInviteId:inviteId,createdAt:serverTimestamp()});
  batch.set(doc(store,'rooms',roomId,'members',uid),member(uid));
  batch.set(doc(store,'invites',inviteId),{roomId,title:'Saturday, sorted.',createdBy:uid,expiresAt:Timestamp.fromMillis(Date.now()+6*86400000)});
  await batch.commit();
}
async function join(uid,token=inviteId){
  const store=db(uid),batch=writeBatch(store);
  batch.set(doc(store,'rooms',roomId,'members',uid),{...member(uid),inviteId:token});
  batch.update(doc(store,'rooms',roomId),{memberIds:arrayUnion(uid),lastJoinInviteId:token,status:'gathering',proposal:null,revision:increment(1)});
  return batch.commit();
}
async function share(uid,card=DEFAULT_CARD){const store=db(uid),batch=writeBatch(store);batch.update(doc(store,'rooms',roomId,'members',uid),{card,updatedAt:serverTimestamp()});batch.update(doc(store,'rooms',roomId),{status:'gathering',proposal:null,revision:increment(1)});return batch.commit();}
async function propose(){const store=db('host'),snap=await getDoc(doc(store,'rooms',roomId)),revision=snap.data().revision+1;await updateDoc(doc(store,'rooms',roomId),{status:'voting',revision,proposal:{candidateId:'college-games',startMinute:1020,revision}});return revision;}
async function vote(uid,revision,choice='yes',as=uid){return setDoc(doc(db(as),'rooms',roomId,'votes',uid),{choice,revision,candidateId:'college-games',updatedAt:serverTimestamp()});}

before(async()=>{if(enabled)env=await initializeTestEnvironment({projectId:'demo-meethalfway',firestore:{rules:await readFile(new URL('../firestore.rules',import.meta.url),'utf8')}});});
beforeEach(async()=>{if(enabled)await env.clearFirestore();});
after(async()=>{if(env)await env.cleanup();});
const rules=(name,fn)=>test(name,{skip:!enabled},fn);

rules('room creation is atomic and ownership-bound',async()=>{
  await assertSucceeds(create());
  await assertSucceeds(getDoc(doc(db('host'),'rooms',roomId)));
  await assertFails(updateDoc(doc(db('host'),'rooms',roomId),{ownerId:'attacker'}));
  await assertFails(deleteDoc(doc(db('host'),'rooms',roomId)));
});
rules('outsiders and unauthenticated users cannot read rooms or enumerate invites',async()=>{
  await create();
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'rooms',roomId)));
  await assertFails(getDoc(doc(db('outsider'),'rooms',roomId)));
  await assertFails(getDocs(collection(db('outsider'),'rooms',roomId,'members')));
  await assertFails(getDocs(collection(db('outsider'),'invites')));
  await assertSucceeds(getDoc(doc(db('invitee'),'invites',inviteId)));
});
rules('valid capability joins atomically; guessed tokens and partial joins fail',async()=>{
  await create();
  await assertFails(join('guesser','f'.repeat(48)));
  await assertFails(setDoc(doc(db('partial'),'rooms',roomId,'members','partial'),member('partial')));
  await assertSucceeds(join('friend'));
  await assertSucceeds(getDoc(doc(db('friend'),'rooms',roomId)));
});
rules('an invite cannot grant access to a different room',async()=>{
  await create();const other='c'.repeat(36);
  await assertFails(setDoc(doc(db('attacker'),'rooms',other,'members','attacker'),member('attacker')));
});
rules('room capacity is eight and members cannot remove or add other people',async()=>{
  await create();for(let i=1;i<8;i++)await join(`friend${i}`);
  await assertFails(join('ninth'));
  await assertFails(updateDoc(doc(db('friend1'),'rooms',roomId),{memberIds:['friend1']}));
  await assertFails(updateDoc(doc(db('host'),'rooms',roomId),{memberIds:arrayUnion('injected')}));
});
rules('approved-card writes reject raw notes, pollution and invalid updates',async()=>{
  await create();await assertSucceeds(share('host'));
  await assertFails(share('host',{...DEFAULT_CARD,privateNote:'secret'}));
  await assertFails(share('host',{...DEFAULT_CARD,maxSpend:-1}));
  await assertFails(share('host',{...DEFAULT_CARD,quiet:'true'}));
  await assertFails(share('host',{...DEFAULT_CARD,interests:['games','games']}));
  await assertFails(updateDoc(doc(db('host'),'rooms',roomId,'members','host'),{name:'x'.repeat(10000),updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db('host'),'rooms',roomId),{privateNote:'secret'}));
});
rules('preferences cannot change without resetting the proposal revision',async()=>{
  await create();await join('friend');await share('host');await share('friend');const revision=await propose();
  await vote('host',revision);await vote('friend',revision);
  await assertFails(updateDoc(doc(db('friend'),'rooms',roomId,'members','friend'),{card:{...DEFAULT_CARD,maxSpend:0},updatedAt:serverTimestamp()}));
  await assertSucceeds(share('friend',{...DEFAULT_CARD,maxSpend:0}));
  await assertFails(updateDoc(doc(db('host'),'rooms',roomId),{status:'confirmed'}));
});
rules('votes cannot be forged for another member or replayed for a new proposal',async()=>{
  await create();await join('friend');await share('host');await share('friend');const first=await propose();
  await assertFails(vote('friend',first,'yes','host'));
  await assertSucceeds(vote('host',first));
  const second=await propose();await assertFails(vote('friend',first));await assertSucceeds(vote('friend',second));
});
rules('confirmation needs current unanimous acceptance and cannot be performed by a guest',async()=>{
  await create();await join('friend');await share('host');await share('friend');const revision=await propose();
  await assertFails(updateDoc(doc(db('host'),'rooms',roomId),{status:'confirmed'}));
  await vote('host',revision);await vote('friend',revision,'maybe');
  await assertFails(updateDoc(doc(db('host'),'rooms',roomId),{status:'confirmed'}));
  await vote('friend',revision,'yes');
  await assertFails(updateDoc(doc(db('friend'),'rooms',roomId),{status:'confirmed'}));
  await assertSucceeds(updateDoc(doc(db('host'),'rooms',roomId),{status:'confirmed'}));
  await assertFails(vote('friend',revision,'no'));
});
rules('all eight participants can accept within Firestore access-call limits',async()=>{
  await create();for(let i=1;i<8;i++)await join(`friend${i}`);
  for(const uid of ['host',...Array.from({length:7},(_,i)=>`friend${i+1}`)])await share(uid);
  const revision=await propose();for(const uid of ['host',...Array.from({length:7},(_,i)=>`friend${i+1}`)])await vote(uid,revision);
  await assertSucceeds(updateDoc(doc(db('host'),'rooms',roomId),{status:'confirmed'}));
});
rules('the application membership query works without exposing other rooms',async()=>{
  await create();await join('friend');
  await assertSucceeds(getDocs(query(collection(db('friend'),'rooms'),where('memberIds','array-contains','friend'))));
  await assertFails(getDocs(collection(db('friend'),'rooms')));
});
rules('host activity slots are bounded, schema-validated and reopen the decision atomically',async()=>{
  await create();await join('friend');
  const option={name:'A real group option',venue:'A place the host chose',areaId:'downtown',cost:20,tags:['games'],noise:1,indoor:true,stepFree:null,description:'A relaxed activity.',url:'https://example.org',opens:960,closes:1320,createdBy:'host',updatedAt:serverTimestamp()};
  async function add(as='host',id='option-01',delta={}){
    const store=db(as),batch=writeBatch(store);
    batch.set(doc(store,'rooms',roomId,'options',id),{...option,...delta});
    batch.update(doc(store,'rooms',roomId,'members',as),{updatedAt:serverTimestamp()});
    batch.update(doc(store,'rooms',roomId),{status:'gathering',proposal:null,revision:increment(1)});
    return batch.commit();
  }
  await assertFails(add('friend'));
  await assertFails(add('host','option-13'));
  await assertFails(add('host','option-01',{privateNote:'secret'}));
  await assertFails(setDoc(doc(db('host'),'rooms',roomId,'options','option-01'),option));
  await assertSucceeds(add());
  await assertSucceeds(getDocs(collection(db('friend'),'rooms',roomId,'options')));
  await assertFails(getDocs(collection(db('outsider'),'rooms',roomId,'options')));
  const snapshot=await getDoc(doc(db('host'),'rooms',roomId));
  const revision=snapshot.data().revision+1;
  await assertSucceeds(updateDoc(doc(db('host'),'rooms',roomId),{status:'voting',revision,proposal:{candidateId:'option-01',startMinute:1020,revision}}));
  await assertFails(updateDoc(doc(db('host'),'rooms',roomId),{status:'voting',revision:revision+1,proposal:{candidateId:'option-02',startMinute:1020,revision:revision+1}}));
});
