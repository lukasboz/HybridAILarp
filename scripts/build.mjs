import { cp, mkdir, rm, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { build } from 'esbuild';
import './sync-shared.mjs';
const workspace=process.cwd();
const targets=['dist'];
for(const relative of ['native/android/app/src/main/assets/www','native/ios/Resources/Web']){
  const legacy=path.resolve(workspace,relative);
  if(!legacy.startsWith(workspace+path.sep))throw new Error('Legacy output escaped the workspace');
  await rm(legacy,{recursive:true,force:true});
}
// Every deletion is a fixed build output inside this workspace.
for(const relative of targets){
  const output=path.resolve(workspace,relative);
  if(!output.startsWith(workspace+path.sep))throw new Error('Build output escaped the workspace.');
  await rm(output,{recursive:true,force:true});await mkdir(output,{recursive:true});
  await cp(path.join(workspace,'web'),output,{recursive:true,filter:source=>!source.endsWith('firebase-config.example.json')});
  await build({absWorkingDir:workspace,entryPoints:[path.join(workspace,'web/src/app.js')],tsconfigRaw:{},bundle:true,format:'iife',platform:'browser',target:'es2022',outfile:path.join(output,'app.js'),minify:true,legalComments:'none'});
  const html=await readFile(path.join(output,'index.html'),'utf8');
  await writeFile(path.join(output,'index.html'),html.replace('<script type="module" src="./src/app.js"></script>','<script defer src="./app.js"></script>'));
  const sw=await readFile(path.join(output,'sw.js'),'utf8');
  await writeFile(path.join(output,'sw.js'),sw.replace("const FILES=[","const FILES=['./app.js',"));

}
// Generate non-secret native identifiers separately for each registered platform.
// platform IDs are filled by scripts/configure-firebase.mjs after CLI provisioning.
await mkdir('native/ios/Resources',{recursive:true});
try{await readFile('native/ios/Resources/NativeConfig.plist');}catch{
  await writeFile('native/ios/Resources/NativeConfig.plist','<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict></dict></plist>');
}
console.log('Built web distribution and synchronized native SwiftUI/Compose design resources.');
