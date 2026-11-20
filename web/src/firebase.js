import { publicCard, validateOption } from './domain.js';
import { randomId } from './storage.js';
import { platform, nativeCall } from './native.js';

let connection=null;
export async function readConfig() {
  try {
    const response=await fetch(new URL('./firebase-config.local.json',document.baseURI),{cache:'no-store'});
    if(!response.ok)return null;return await response.json();
  }catch{return null;}
}
export async function connectFirebase() {
  if(connection)return connection;
  const config=await readConfig();
  if(!config?.firebase?.projectId || !config.firebase.apiKey)throw new Error('Firebase isn’t configured yet. Sample rooms work on this device.');
  const version=config.firebaseVersion||'13.3.0';
  if(!/^\d+\.\d+\.\d+$/.test(version))throw new Error('Invalid Firebase SDK version.');
  const module=name=>import(`https://www.gstatic.com/firebasejs/${version}/firebase-${name}.js`);
  const [core,authSdk,dbSdk,checkSdk,aiSdk,rcSdk]=await Promise.all(['app','auth','firestore','app-check','ai','remote-config'].map(module));
  const app=core.getApps().length?core.getApp():core.initializeApp(config.firebase);
  let appCheck;
  if(platform!=='web'){
    appCheck=checkSdk.initializeAppCheck(app,{provider:new checkSdk.CustomProvider({getToken:async()=>nativeCall('appCheck')}),isTokenAutoRefreshEnabled:true});
  }else if(config.appCheckSiteKey){
    appCheck=checkSdk.initializeAppCheck(app,{provider:new checkSdk.ReCaptchaEnterpriseProvider(config.appCheckSiteKey),isTokenAutoRefreshEnabled:true});
  }else if(!config.emulator){throw new Error('Set the public App Check site key before connecting this web app.');}
  const auth=authSdk.getAuth(app);
  const db=dbSdk.getFirestore(app);
  if(config.emulator){
    const host=location.hostname||'127.0.0.1';authSdk.connectAuthEmulator(auth,`http://${host}:9099`,{disableWarnings:true});dbSdk.connectFirestoreEmulator(db,host,8080);
  }
  await authSdk.signInAnonymously(auth);
  let modelName=config.cloudModel||'gemini-3.8-flash';
  let remoteConfig;
  if(await rcSdk.isSupported()){
    remoteConfig=rcSdk.getRemoteConfig(app);remoteConfig.defaultConfig={cloud_model:modelName,cloud_explanations_enabled:true,max_group_size:8};
    remoteConfig.settings.fetchTimeoutMillis=4000;
    try{await rcSdk.fetchAndActivate(remoteConfig);modelName=rcSdk.getValue(remoteConfig,'cloud_model').asString()||modelName;}catch{/* Bundled defaults keep the product usable. */}
  }
  const ai=aiSdk.getAI(app,{backend:new aiSdk.GoogleAIBackend(),appCheck});
  connection={app,auth,db,ai,aiSdk,dbSdk,authSdk,modelName,remoteConfig,rcSdk,config,uid:auth.currentUser.uid};
  return connection;
}
export function currentConnection(){return connection;}
export async function createCloudRoom(title,date,name) {
  const c=await connectFirebase(),s=c.dbSdk,id=randomId(),inviteId=randomId(24),room=s.doc(c.db,'rooms',id);
  const batch=s.writeBatch(c.db);
  batch.set(room,{title,date,city:'Toronto',ownerId:c.uid,memberIds:[c.uid],status:'gathering',revision:0,proposal:null,lastJoinInviteId:inviteId,createdAt:s.serverTimestamp()});
  batch.set(s.doc(c.db,'rooms',id,'members',c.uid),{name,card:null,inviteId,updatedAt:s.serverTimestamp()});
  batch.set(s.doc(c.db,'invites',inviteId),{roomId:id,title,createdBy:c.uid,expiresAt:s.Timestamp.fromMillis(Date.now()+7*86400000)});
  await batch.commit();return {id,inviteId};
}
export async function joinCloudRoom(inviteId,name) {
  if(!/^[a-f0-9]{48}$/.test(inviteId))throw new Error('This invitation is invalid.');
  const c=await connectFirebase(),s=c.dbSdk,snapshot=await s.getDoc(s.doc(c.db,'invites',inviteId));
  if(!snapshot.exists())throw new Error('This invitation has expired or is unavailable.');
  const {roomId,expiresAt}=snapshot.data();if(expiresAt.toMillis()<Date.now())throw new Error('This invitation has expired.');
  const memberRef=s.doc(c.db,'rooms',roomId,'members',c.uid);
  // An existing member can reconnect without modifying a locked room.
  try{const existing=await s.getDoc(memberRef);if(existing.exists())return roomId;}catch{}
  const batch=s.writeBatch(c.db);
  batch.set(memberRef,{name,card:null,inviteId,updatedAt:s.serverTimestamp()});
  batch.update(s.doc(c.db,'rooms',roomId),{memberIds:s.arrayUnion(c.uid),lastJoinInviteId:inviteId,proposal:null,status:'gathering',revision:s.increment(1)});
  await batch.commit();return roomId;
}
export async function watchCloudRoom(id,listener,onError) {
  const c=await connectFirebase(),s=c.dbSdk;
  let room=null,members=[],votes={},options=[];
  const emit=()=>{if(room)listener({...room,id,members:room.memberIds.map(uid=>members.find(m=>m.id===uid)||{id:uid,name:'Joining…',initials:'…',color:'sage',card:null}),votes,options,local:false});};
  const off=[
    s.onSnapshot(s.doc(c.db,'rooms',id),snap=>{room=snap.exists()?snap.data():null;emit();},onError),
    s.onSnapshot(s.collection(c.db,'rooms',id,'members'),snap=>{members=snap.docs.map((d,i)=>({id:d.id,...d.data(),color:['sage','peach','lavender','blue'][i%4],initials:(d.data().name||'?').slice(0,2).toUpperCase()}));emit();},onError),
    s.onSnapshot(s.collection(c.db,'rooms',id,'votes'),snap=>{votes=Object.fromEntries(snap.docs.map(d=>[d.id,d.data()]));emit();},onError),
    s.onSnapshot(s.collection(c.db,'rooms',id,'options'),snap=>{options=snap.docs.map(d=>({id:d.id,...d.data()}));emit();},onError)
  ];return ()=>off.forEach(fn=>fn());
}
export async function shareCloudCard(room,card,name){
  const c=await connectFirebase(),s=c.dbSdk,batch=s.writeBatch(c.db);
  batch.update(s.doc(c.db,'rooms',room.id,'members',c.uid),{card:publicCard(card),name,updatedAt:s.serverTimestamp()});
  batch.update(s.doc(c.db,'rooms',room.id),{proposal:null,status:'gathering',revision:s.increment(1)});
  await batch.commit();
}
export async function proposeCloud(room,rank){
  const c=await connectFirebase(),s=c.dbSdk;
  await s.runTransaction(c.db,async tx=>{
    const ref=s.doc(c.db,'rooms',room.id),snap=await tx.get(ref),fresh=snap.data();
    if(fresh.revision!==room.revision)throw new Error('The group changed. Review the updated shortlist first.');
    tx.update(ref,{status:'voting',revision:fresh.revision+1,proposal:{candidateId:rank.candidate.id,startMinute:rank.start,revision:fresh.revision+1}});
  });
}
export async function voteCloud(room,choice){
  const c=await connectFirebase(),s=c.dbSdk;
  if(!room.proposal)throw new Error('There is no active proposal.');
  await s.setDoc(s.doc(c.db,'rooms',room.id,'votes',c.uid),{choice,candidateId:room.proposal.candidateId,revision:room.proposal.revision,updatedAt:s.serverTimestamp()});
}
export async function confirmCloud(room){const c=await connectFirebase();await c.dbSdk.updateDoc(c.dbSdk.doc(c.db,'rooms',room.id),{status:'confirmed'});}
export async function addCloudOption(room,option){
  const c=await connectFirebase(),s=c.dbSdk,batch=s.writeBatch(c.db);
  const id=Array.from({length:12},(_,i)=>`option-${String(i+1).padStart(2,'0')}`).find(id=>!room.options?.some(o=>o.id===id));
  if(!id)throw new Error('This room already has twelve activities.');
  batch.set(s.doc(c.db,'rooms',room.id,'options',id),{...validateOption(option),createdBy:c.uid,updatedAt:s.serverTimestamp()});
  batch.update(s.doc(c.db,'rooms',room.id,'members',c.uid),{updatedAt:s.serverTimestamp()});
  batch.update(s.doc(c.db,'rooms',room.id),{proposal:null,status:'gathering',revision:s.increment(1)});
  await batch.commit();
}
export async function listCloudRooms(){
  const c=await connectFirebase(),s=c.dbSdk;
  const snap=await s.getDocs(s.query(s.collection(c.db,'rooms'),s.where('memberIds','array-contains',c.uid)));
  return snap.docs.map(d=>({id:d.id,...d.data(),local:false,members:[],votes:{}}));
}
