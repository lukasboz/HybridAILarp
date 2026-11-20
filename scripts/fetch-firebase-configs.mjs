// Read existing registrations only. This never creates projects/apps or deploys.
import {spawnSync} from 'node:child_process';
import {readFile,writeFile,mkdir,rename} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const args=process.argv.slice(2);
const option=(name,fallback)=>args.includes(name)?args[args.indexOf(name)+1]:fallback;
if(args.includes('--help')){
  console.log('Usage: node scripts/fetch-firebase-configs.mjs [--project ID] [--ios-bundle-id ID] [--android-package ID]');
  process.exit(0);
}
const project=option('--project','meethalfway-2026-e43ca6');
const bundle=option('--ios-bundle-id','app.meethalfway.mobile');
const packageName=option('--android-package','app.meethalfway.mobile');
if(!/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(project)||![bundle,packageName].every(v=>typeof v==='string'&&/^[A-Za-z0-9.-]+$/.test(v))){
  throw new Error('Supply valid project and app identifiers.');
}
function firebase(command){
  const result=spawnSync('npx',['--cache',path.join(root,'.cache/npm'),'--yes','firebase-tools@latest',...command,'--project',project,'--non-interactive','--json'],{
    cwd:root,encoding:'utf8',maxBuffer:8*1024*1024});
  if(result.error)throw result.error;
  let parsed;try{parsed=JSON.parse(result.stdout);}catch{}
  if(result.status!==0||parsed?.status==='error'){
    const message=String(parsed?.error||parsed?.message||'Firebase CLI could not read this project. Run firebase login first.');
    // Successful SDK configuration payloads and account credentials are never logged.
    throw new Error(message);
  }
  if(!parsed)throw new Error('Firebase CLI returned an unexpected result.');
  return parsed.result??parsed;
}
function configText(result){
  const value=result.fileContents??result.sdkConfig??result.config;
  if(value==null)throw new Error('Firebase returned no SDK configuration.');
  return typeof value==='string'?value:JSON.stringify(value,null,2);
}
function plistValue(xml,key){
  const value=xml.match(new RegExp(`<key>${key}</key>\\s*<string>([^<]+)</string>`))?.[1];
  if(!value)throw new Error(`The iOS client configuration is missing ${key}.`);
  return value;
}
const listed=firebase(['apps:list']);
const apps=Array.isArray(listed)?listed:listed.apps??[];
let previous={};try{previous=JSON.parse(await readFile(path.join(root,'web/firebase-config.local.json'),'utf8'));}catch{}
function pick(platform,predicate){
  const candidates=apps.filter(app=>app.platform===platform);
  const matching=candidates.filter(predicate);
  const chosen=matching.length===1?matching[0]:candidates.length===1?candidates[0]:null;
  if(!chosen?.appId)throw new Error(`Could not select the existing ${platform} app. Check the requested bundle/package identifier.`);
  return chosen;
}
const web=pick('WEB',app=>app.appId===previous.firebase?.appId||app.displayName==='MeetHalfway-Web');
const android=pick('ANDROID',app=>app.packageName===packageName||app.namespace===packageName);
const ios=pick('IOS',app=>app.bundleId===bundle||app.namespace===bundle);
const webResult=firebase(['apps:sdkconfig','WEB',web.appId]);
const webConfig=typeof webResult.sdkConfig==='object'?webResult.sdkConfig:JSON.parse(configText(webResult));
const androidText=configText(firebase(['apps:sdkconfig','ANDROID',android.appId]));
const androidConfig=JSON.parse(androidText);
if(!androidConfig.client?.some(c=>c.client_info?.android_client_info?.package_name===packageName))throw new Error('The Android registration does not match the requested package.');
const iosText=configText(firebase(['apps:sdkconfig','IOS',ios.appId]));
if(plistValue(iosText,'BUNDLE_ID')!==bundle)throw new Error('The iOS registration does not match the requested signed bundle ID.');
const webText=JSON.stringify({...previous,firebase:webConfig,appCheckSiteKey:previous.appCheckSiteKey??'',
  cloudModel:previous.cloudModel??'gemini-3.8-flash',publicWebUrl:`https://${project}.web.app/`,emulator:false},null,2)+'\n';
for(const [relative,content] of [
  ['web/firebase-config.local.json',webText],
  ['native/android/app/google-services.json',androidText],
  ['native/ios/Resources/GoogleService-Info.plist',iosText],
]){
  const target=path.join(root,relative);await mkdir(path.dirname(target),{recursive:true});
  await writeFile(target+'.tmp',content,{mode:0o600});await rename(target+'.tmp',target);
}
console.log('Retrieved the existing web, Android and iOS public client configurations. Run scripts/flutter.sh to bundle them.');
