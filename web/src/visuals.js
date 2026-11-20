import { AREAS } from './catalog.js';
export const escapeHtml=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const paths={
  arrow:'M12 19V5m-6 6 6-6 6 6',
  home:'M3 10 12 3l9 7v10a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1Z',
  users:'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2m20 0v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75M13 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0Z',
  sliders:'M4 21v-7m0-4V3m8 18v-9m0-4V3m8 18v-5m0-4V3M1 14h6m2-6h6m2 8h6',
  spark:'m12 3 2.5 6.5L21 12l-6.5 2.5L12 21l-2.5-6.5L3 12l6.5-2.5Z',
  pin:'M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 1 1 16 0ZM15 10a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z',
  plus:'M12 5v14M5 12h14',check:'m5 12 4 4L19 6',close:'m6 6 12 12M18 6 6 18',
  lock:'M5 11h14v10H5Zm3 0V7a4 4 0 0 1 8 0v4',
  shield:'m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6Zm-4 9 3 3 5-6',
  clock:'M12 8v5l3 2M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0Z',
  calendar:'M4 5h16v16H4ZM16 3v4M8 3v4M4 11h16',
  chevron:'m9 5 7 7-7 7',down:'m6 9 6 6 6-6',back:'m15 5-7 7 7 7',
  link:'m10 13 4-4m-6 6-1 1a4 4 0 0 1-6-6l4-4a4 4 0 0 1 6 0m2 2 1-1a4 4 0 0 1 6 6l-4 4a4 4 0 0 1-6 0',
  globe:'M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0ZM2 12h20M12 2c6 6 6 14 0 20-6-6-6-14 0-20Z',
  phone:'M7 2h10v20H7ZM10 18h4',laptop:'M4 3h16v14H4ZM2 21h20',
  wifi:'M2 8a16 16 0 0 1 20 0M5 12a11 11 0 0 1 14 0m-10 4a5 5 0 0 1 6 0m-3 4h.01',
  cloud:'M7 18a5 5 0 1 1 0-10 6 6 0 0 1 11-1 5 5 0 1 1 1 11Z',
  dice:'M4 3h16v18H4ZM8 7h.01M16 7h.01M12 12h.01M8 17h.01M16 17h.01',
  art:'M12 3C1 3 1 20 11 21c5 0-1-6 3-6h3c7 0 5-12-5-12ZM7 9h.01M11 6h.01M16 8h.01',
  coffee:'M3 8h13v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4ZM16 9h2a3 3 0 1 1 0 6h-2M6 2v3m4-3v3',
  food:'M4 3v7a3 3 0 0 0 6 0V3M7 3v18M19 3c-5 4-5 9 0 9v9m0-18v9',
  sun:'M12 8a4 4 0 1 1 0 8 4 4 0 0 1 0-8ZM12 2v2m0 16v2M2 12h2m16 0h2M5 5l1 1m12 12 1 1M5 19l1-1M18 6l1-1',
  music:'M9 18V5l12-2v13M9 18a3 3 0 1 1-3-3c2 0 3 1 3 3Zm12-2a3 3 0 1 1-3-3c2 0 3 1 3 3Z',
  walk:'m13 4 .01 0M7 21l3-6m3-8-3 6 5 3 1 5M5 12l4-3 4-2 3 5 4 1',
  train:'M6 3h12v14H6ZM6 9h12M8 17l-3 4m11-4 3 4M9 13h.01M15 13h.01',
  info:'M12 11v6m0-10h.01M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0Z',
  settings:'M12 8a4 4 0 1 1 0 8 4 4 0 0 1 0-8ZM12 2v3m0 14v3M2 12h3m14 0h3M5 5l2 2m10 10 2 2M5 19l2-2M17 7l2-2',
  refresh:'M20 7V2m0 5h-5M4 17v5m0-5h5M3 10a9 9 0 0 1 16-4M21 14a9 9 0 0 1-16 4',
  heart:'M20 5c-3-3-7-1-8 2-1-3-5-5-8-2-5 5 8 16 8 16S25 10 20 5Z',
  share:'M18 8a3 3 0 1 1 0-6 3 3 0 0 1 0 6Zm0 14a3 3 0 1 1 0-6 3 3 0 0 1 0 6ZM6 15a3 3 0 1 1 0-6 3 3 0 0 1 0 6Zm2-5 7-4m-7 8 7 4',
  eye:'M2 12S6 4 12 4s10 8 10 8-4 8-10 8S2 12 2 12Zm13 0a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z',
  copy:'M9 9h12v12H9ZM15 5V3H3v12h2'
};
export function icon(name,cls=''){return `<svg class="icon ${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="${paths[name]||paths.spark}"/></svg>`;}
export function avatar(member,small=false){return `<span class="avatar ${escapeHtml(member.color||'sage')} ${small?'small':''}" aria-label="${escapeHtml(member.name)}">${escapeHtml(member.initials||member.name?.slice(0,2).toUpperCase()||'?')}</span>`;}
export function illustration(theme='games',className=''){
  const symbols={games:icon('dice'),art:icon('art'),park:icon('sun'),water:icon('walk'),library:icon('coffee'),market:icon('food'),picnic:icon('food'),studio:icon('art')};
  return `<div class="illustration ${theme} ${className}" aria-hidden="true"><span class="ill-orbit one"></span><span class="ill-orbit two"></span><span class="ill-dot"></span><div class="ill-object">${symbols[theme]||icon('spark')}</div><span class="ill-line"></span><span class="ill-tiny">${icon('spark')}</span></div>`;
}
export function mapMarkup(members,ranked,selectedId){
  const point=c=>({x:Math.max(30,Math.min(570,((c.lng+79.45)/.14)*600)),y:Math.max(35,Math.min(390,420-((c.lat-43.625)/.06)*400))});
  const selected=ranked.find(r=>r.candidate.id===selectedId)||ranked[0];
  const origins=members.filter(m=>m.card).map(m=>({...m,...point(AREAS.find(a=>a.id===m.card.areaId))}));
  return `<div class="map-canvas"><svg viewBox="0 0 600 450" role="img" aria-label="Schematic Toronto map showing approximate neighbourhoods and shortlisted plans. This is not a navigation map.">
    <defs><pattern id="blocks" width="34" height="31" patternUnits="userSpaceOnUse" patternTransform="rotate(-13)"><rect width="34" height="31" fill="#eef1e9"/><path d="M0 0h34v31H0Z" fill="none" stroke="#fff" stroke-width="5"/></pattern></defs>
    <rect width="600" height="450" fill="url(#blocks)"/>
    <path d="M0 379 135 366 215 389 300 365 395 342 600 364V450H0Z" fill="#c7e0e3"/>
    <path d="m0 357 145-14 83 19 169-39 203 19" fill="none" stroke="#fff" stroke-width="9"/>
    <path d="m-20 240 640-90M65 0l83 365M293 0l64 354M472 0l37 347" fill="none" stroke="#fff" stroke-width="11"/>
    <path d="m-20 240 640-90M65 0l83 365M293 0l64 354M472 0l37 347" fill="none" stroke="#e4d8a7" stroke-width="3"/>
    <path d="m425 0-21 110 39 62-27 130" fill="none" stroke="#b9d3ba" stroke-width="18"/>
    <rect x="90" y="246" width="49" height="67" rx="10" fill="#cfddc3" transform="rotate(-13 90 246)"/><rect x="286" y="206" width="28" height="42" rx="8" fill="#cfddc3"/>
    <g class="map-labels" fill="#7a8b7b" font-size="10" font-family="system-ui" letter-spacing="1.5"><text x="43" y="204">LITTLE ITALY</text><text x="211" y="171">THE ANNEX</text><text x="300" y="289">DOWNTOWN</text><text x="446" y="120">RIVERDALE</text><text x="50" y="340">LIBERTY VILLAGE</text><text x="360" y="414" fill="#69979e">LAKE ONTARIO</text></g>
    ${selected?origins.map(o=>{const p=point(selected.candidate);return `<path d="M${o.x} ${o.y} Q${(o.x+p.x)/2+35} ${(o.y+p.y)/2-30} ${p.x} ${p.y}" fill="none" stroke="#487462" stroke-width="1.8" stroke-dasharray="4 5" opacity=".55"/>`;}).join(''):''}
    ${origins.map(o=>`<g><circle cx="${o.x}" cy="${o.y}" r="16" fill="${o.color==='peach'?'#f1d6bf':o.color==='lavender'?'#ddd7ed':'#caddb5'}" stroke="#fff" stroke-width="3"/><text x="${o.x}" y="${o.y+4}" text-anchor="middle" font-size="9" font-family="system-ui" font-weight="700" fill="#254c3b">${escapeHtml(o.initials)}</text></g>`).join('')}
    ${ranked.slice(0,3).map((r,i)=>{const p=point(r.candidate),active=r.candidate.id===selected?.candidate.id;return `<g class="map-pin" data-action="select-plan" data-id="${r.candidate.id}" tabindex="0" role="button" aria-label="Show ${escapeHtml(r.candidate.name)}"><circle cx="${p.x}" cy="${p.y}" r="${active?24:18}" fill="${active?'#173e35':'#fff'}" stroke="${active?'#d0ef8e':'#173e35'}" stroke-width="3"/><text x="${p.x}" y="${p.y+5}" text-anchor="middle" font-size="13" font-family="system-ui" font-weight="700" fill="${active?'#fff':'#173e35'}">${i+1}</text></g>`;}).join('')}
  </svg><span class="map-caption">${icon('pin')} Neighbourhood centres · illustrative map</span></div>`;
}
