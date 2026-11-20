import {spawnSync} from 'node:child_process';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import path from 'node:path';

const args=process.argv.slice(2),value=flag=>args[args.indexOf(flag)+1];
if(!args.includes('--project'))throw new Error('Supply --project and a globally unique Firebase project ID. Add --create to create it.');
const project=value('--project'),bundle=args.includes('--ios-bundle-id')?value('--ios-bundle-id'):'app.meethalfway.mobile';
if(!/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(project))throw new Error('Invalid Firebase project ID.');
if(!/^[A-Za-z0-9.-]+$/.test(bundle))throw new Error('Invalid iOS bundle ID.');
const workspace=process.cwd();
function cli(command){
  // Only public, validated identifiers enter arguments. Config and credentials
  // are written with filesystem APIs, never command substitution or interpolation.
  const all=['-y','firebase-tools@latest',...command,'--json'];
  if(all.some(a=>!/^[-A-Za-z0-9_@.:/()=]+$/.test(a)))throw new Error('Unsafe CLI argument.');
  const result=process.platform==='win32'
    ?spawnSync('cmd.exe',['/d','/s','/c',`npx ${all.map(a=>`"${a}"`).join(' ')}`],{cwd:workspace,encoding:'utf8',maxBuffer:12*1024*1024})
    :spawnSync('npx',all,{cwd:workspace,encoding:'utf8',maxBuffer:12*1024*1024});
  if(result.error)throw result.error;
  let parsed;try{parsed=JSON.parse(result.stdout);}catch{}
  if(result.status!==0||parsed?.status==='error'){
    // Firebase errors may be printed, but never print successful config payloads.
    throw new Error(parsed?.error||parsed?.message||result.stderr||`Firebase ${command[0]} failed.`);
  }
  if(!parsed)throw new Error(`Firebase ${command[0]} returned unexpected output.`);
  return parsed.result??parsed;
}
function items(value){return Array.isArray(value)?value:value?.apps||value?.results||value?.databases||[];}
function configText(result){const config=result.fileContents??result.sdkConfig??result.config??result;return typeof config==='string'?config:JSON.stringify(config,null,2);}
function xmlEscape(value){return String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[c]));}

console.log('Checking Firebase sign-in and project access…');
const projects=items(cli(['projects:list']));
if(!projects.some(p=>p.projectId===project)){
  if(!args.includes('--create'))throw new Error('Project is not accessible. Sign in or use --create for a new project.');
  cli(['projects:create',project,'--display-name','MeetHalfway']);
}
await writeFile('.firebaserc',JSON.stringify({projects:{default:project}},null,2)+'\n');
let apps=items(cli(['apps:list','--project',project]));
async function ensure(platform,displayName,extra=[]){
  let found=apps.find(a=>a.platform===platform&&a.displayName===displayName);
  if(!found){cli(['apps:create',platform,displayName,...extra,'--project',project]);apps=items(cli(['apps:list','--project',project]));found=apps.find(a=>a.platform===platform&&a.displayName===displayName);}
  if(!found?.appId)throw new Error(`Could not resolve the ${platform} app ID.`);
  return found;
}
const web=await ensure('WEB','MeetHalfway-Web');
const android=await ensure('ANDROID','MeetHalfway-Android',['--package-name','app.meethalfway.mobile']);
const ios=await ensure('IOS','MeetHalfway-iOS',['--bundle-id',bundle]);
const webResult=cli(['apps:sdkconfig','WEB',web.appId,'--project',project]);
const webConfig=typeof webResult.sdkConfig==='object'?webResult.sdkConfig:JSON.parse(typeof webResult.sdkConfig==='string'?webResult.sdkConfig:configText(webResult));
let previous={};try{previous=JSON.parse(await readFile('web/firebase-config.local.json','utf8'));}catch{}
await writeFile('web/firebase-config.local.json',JSON.stringify({firebase:webConfig,appCheckSiteKey:previous.appCheckSiteKey||'',cloudModel:'gemini-3.8-flash',firebaseVersion:'13.3.0',publicWebUrl:`https://${project}.web.app/`,emulator:false},null,2)+'\n');
await mkdir('native/android/app',{recursive:true});
await writeFile('native/android/app/google-services.json',configText(cli(['apps:sdkconfig','ANDROID',android.appId,'--project',project])));
await mkdir('native/ios/Resources',{recursive:true});
const iosPlist=configText(cli(['apps:sdkconfig','IOS',ios.appId,'--project',project]));
await writeFile('native/ios/Resources/GoogleService-Info.plist',iosPlist);
const keys=['GOOGLE_APP_ID','GCM_SENDER_ID','API_KEY','PROJECT_ID'];
const nativeConfig=Object.fromEntries(keys.map(key=>{
  const match=iosPlist.match(new RegExp(`<key>${key}<\\/key>\\s*<string>([^<]*)<\\/string>`));
  if(!match)throw new Error(`The iOS SDK config is missing ${key}.`);return [key,match[1]];
}));
await writeFile('native/ios/Resources/NativeConfig.plist',`<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict>${Object.entries(nativeConfig).map(([k,v])=>`<key>${k}</key><string>${xmlEscape(v)}</string>`).join('')}</dict></plist>`);
console.log('Registered all three apps and wrote ignored client configurations. Provisioning Firebase AI Logic…');
console.log('The current Firebase CLI asks which app to provision. Select MeetHalfway-Web; the API is enabled for this project. Native App Check registration follows separately.');
const initArgs=['-y','firebase-tools@latest','init','ailogic','--project',project];
const initialized=process.platform==='win32'
  ?spawnSync('cmd.exe',['/d','/s','/c',`npx ${initArgs.map(a=>`"${a}"`).join(' ')}`],{cwd:workspace,stdio:'inherit'})
  :spawnSync('npx',initArgs,{cwd:workspace,stdio:'inherit'});
if(initialized.error)throw initialized.error;
if(initialized.status!==0)throw new Error('Firebase AI Logic provisioning did not complete. Run npx -y firebase-tools@latest init ailogic with this project before continuing.');
console.log('AI Logic is provisioned. Checking Firestore…');
const databases=items(cli(['firestore:databases:list','--project',project]));
if(!databases.some(d=>String(d.name||d.databaseId||'').endsWith('(default)'))){
  cli(['firestore:databases:create','(default)','--location','northamerica-northeast2','--project',project]);
}
console.log(`Configured MeetHalfway in ${project}. No paid billing was enabled. Configure App Check before testing live AI; then build, test and deploy.`);
