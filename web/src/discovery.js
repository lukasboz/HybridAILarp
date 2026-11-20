import { avatar, icon, escapeHtml as e } from './visuals.js';

const photos={games:'games',art:'art',studio:'art',library:'coffee',market:'food',park:'park',picnic:'park',water:'water'};
export function activityImage(candidate,extra='') {
  return `<img class="activity-photo ${extra}" src="./assets/activities/${photos[candidate.theme]||'coffee'}.jpg" alt="" loading="lazy" decoding="async">`;
}

// The orbit is an alternate view of the actual catalogue and participant state.
// Decorative movement never runs inference or changes recommendation order.
export function orbitMarkup({members,ideas,selected=null,home=false,ready=true,local=false}) {
  return `<div class="orbit-stage ${home?'orbit-home':'orbit-room'}" aria-label="${home?'Toronto sample activity ideas':'Your group and activity options'}">
    <div class="orbit-aura" aria-hidden="true"></div>
    <div class="orbit-guide" aria-hidden="true"></div>
    <div class="orbit-ring">
      ${ideas.map((idea,i)=>{
        const candidate=idea.candidate||idea,angle=2*Math.PI*i/ideas.length-Math.PI/2;
        const ruledOut=!home&&ready&&idea.eligible===false;
        const action=home?'preview-idea':ruledOut?'orbit-filter':'select-plan';
        return `<div class="orbit-node" style="--x:${Math.cos(angle).toFixed(5)};--y:${Math.sin(angle).toFixed(5)};--delay:${i*60}ms"><button class="orbit-tile ${candidate.id===selected?'is-selected':''} ${ruledOut?'is-ruled-out':''}" data-action="${action}" data-id="${e(candidate.id)}" aria-label="${e(candidate.name)}${ruledOut?': outside shared limits':''}" ${!home&&!ready?'disabled':''} ${candidate.id===selected?'aria-pressed="true"':''}>${activityImage(candidate)}<span class="orbit-tile-label">${e(candidate.name)}</span>${!home&&idea.eligible?`<span class="orbit-fit">${idea.minFit}</span>`:''}</button></div>`;
      }).join('')}
    </div>
    <div class="orbit-people">
      ${members.slice(0,8).map((member,i)=>{
        const angle=2*Math.PI*i/members.length-Math.PI/2;
        const clickable=home||local;
        return `<${clickable?'button':'div'} class="orbit-person ${member.card?'is-ready':''}" style="--x:${Math.cos(angle).toFixed(5)};--y:${Math.sin(angle).toFixed(5)}" ${clickable?`data-action="${home?'preview-person':'persona'}" data-id="${e(member.id)}"`:''}>${avatar(member)}<span>${e(member.name)}${home?'<small>Sample</small>':`<small>${member.card?'Ready':'Adding preferences'}</small>`}</span></${clickable?'button':'div'}>`;
      }).join('')}
    </div>
    <div class="orb-centre">
      <${home?'button':'div'} class="glass-orb" ${home?'data-action="open-demo" aria-label="Explore the sample group"':'aria-hidden="true"'}><span class="orb-sheen"></span><span class="orb-lens"></span><span class="orb-spark"></span></${home?'button':'div'}>
      <span class="orb-caption">${home?'Find your halfway':ready?'Common ground, found.':'Bringing everyone together.'}</span>
    </div>
    <div class="orbit-legend">${icon(home?'spark':'users')}<span>${home?'A world of possibilities. One plan together.':ready?'Bright ideas meet everyone’s shared limits.':'Your shortlist appears when everyone shares a card.'}</span></div>
  </div>`;
}
