import {readFile,writeFile,mkdir,cp} from 'node:fs/promises';
import {AREAS,CATALOG,INTERESTS,DEMO_MEMBERS} from '../web/src/catalog.js';
import {DEFAULT_CARD,rankPlans} from '../web/src/domain.js';
const tokens=JSON.parse(await readFile('shared/design-tokens.json','utf8'));
const experience={areas:AREAS,catalog:CATALOG,interests:INTERESTS,members:DEMO_MEMBERS,defaultCard:DEFAULT_CARD};
await writeFile('shared/experience.json',JSON.stringify(experience,null,2)+'\n');
const cases=[
  ['sample',DEMO_MEMBERS],
  ['zero-budget',DEMO_MEMBERS.map(m=>({...m,card:{...m.card,maxSpend:0}}))],
  ['quiet-indoors',DEMO_MEMBERS.map(m=>({...m,card:{...m.card,quiet:true,indoors:true}}))],
  ['confirmed-access',DEMO_MEMBERS.map(m=>({...m,card:{...m.card,stepFree:true}}))],
  ['no-overlap',DEMO_MEMBERS.map((m,i)=>({...m,card:{...m.card,earliest:i?1200:600,latest:i?1380:720}}))],
  ['missing-card',DEMO_MEMBERS.map((m,i)=>({...m,card:i?m.card:null}))],
  ['walking',DEMO_MEMBERS.map(m=>({...m,card:{...m.card,mode:'walk',maxTravel:30}}))]
].map(([name,members])=>({name,members,expected:rankPlans(members).eligible.map(r=>({id:r.candidate.id,minFit:r.minFit,meanFit:r.meanFit,maxTravel:r.maxTravel,start:r.start}))}));
await writeFile('shared/planner-cases.json',JSON.stringify(cases,null,2)+'\n');
await mkdir('web/assets/fonts',{recursive:true});
await writeFile('web/tokens.css',`/* Generated from shared/design-tokens.json. */\n:root{${Object.entries(tokens.colors).map(([k,v])=>`--mh-${k}:${v}`).join(';')};${Object.entries(tokens.sizes).map(([k,v])=>`--mh-${k}:${v}px`).join(';')}}\n`);
const swift=`// Generated from shared/design-tokens.json.\nimport SwiftUI\nenum MHDesign {\n${Object.entries(tokens.colors).map(([k,v])=>`    static let ${k} = Color(hex: 0x${v.slice(1)})`).join('\n')}\n${Object.entries(tokens.sizes).map(([k,v])=>`    static let ${k}: CGFloat = ${v}`).join('\n')}\n    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {\n        .custom(weight == .semibold || weight == .bold ? "Inter-SemiBold" : weight == .medium ? "Inter-Medium" : "Inter-Regular", size: size, relativeTo: .body)\n    }\n}\nextension Color { init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255)/255, green: Double((hex >> 8) & 255)/255, blue: Double(hex & 255)/255, opacity: 1) } }\n`;
await writeFile('native/ios/Sources/MeetHalfway/DesignTokens.swift',swift);
const kotlin=`// Generated from shared/design-tokens.json.\npackage app.meethalfway.mobile\nimport androidx.compose.ui.graphics.Color\nobject MHDesign {\n${Object.entries(tokens.colors).map(([k,v])=>`    val ${k} = Color(0xFF${v.slice(1)})`).join('\n')}\n${Object.entries(tokens.sizes).map(([k,v])=>`    const val ${k} = ${v}`).join('\n')}\n}\n`;
await writeFile('native/android/app/src/main/java/app/meethalfway/mobile/DesignTokens.kt',kotlin);
for(const base of ['native/ios/Resources/Shared','native/android/app/src/main/assets/shared']){
  await mkdir(base,{recursive:true});
  for(const file of ['design-tokens.json','experience.json','planner-cases.json'])await cp('shared/'+file,base+'/'+file);
  await cp('web/assets/activities',base+'/activities',{recursive:true});
  await cp('web/assets/fonts/OFL.txt',base+'/OFL-Inter.txt');
}
await cp('web/assets/fonts/OFL.txt','native/ios/Resources/Fonts/OFL.txt');
console.log('Synchronized design tokens, catalogue, photography, and seven cross-platform planner cases.');
