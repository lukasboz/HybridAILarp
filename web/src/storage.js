import { DEMO_MEMBERS } from './catalog.js';
import { DEFAULT_CARD, nextSaturday, canConfirm, publicCard } from './domain.js';

const ROOM_KEY='meethalfway.rooms.v1';
export const identityKey='meethalfway.identity.v1';
export function randomId(bytes=18) { return Array.from(crypto.getRandomValues(new Uint8Array(bytes)),b=>b.toString(16).padStart(2,'0')).join(''); }
export function getIdentity() {
  try {const saved=JSON.parse(localStorage.getItem(identityKey)||'null');if(saved?.id&&saved?.name)return saved;}catch{}
  const id={id:randomId(12),name:'You',initials:'YO',color:'sage'};
  localStorage.setItem(identityKey,JSON.stringify(id));return id;
}
export function setIdentity(identity) {localStorage.setItem(identityKey,JSON.stringify(identity));}
function readRooms() {try{return JSON.parse(localStorage.getItem(ROOM_KEY)||'{}');}catch{return {};}}
function writeRooms(rooms) {localStorage.setItem(ROOM_KEY,JSON.stringify(rooms));window.dispatchEvent(new Event('meethalfway-change'));}
export function createDemo() {
  const room={id:'sample-toronto',title:'Saturday, sorted.',city:'Toronto',date:nextSaturday(),ownerId:'alex',members:structuredClone(DEMO_MEMBERS),status:'gathering',votes:{},proposal:null,revision:0,local:true,createdAt:Date.now()};
  saveRoom(room);return room;
}
export function createLocalRoom(title,date,identity) {
  const room={id:randomId(10),title,city:'Toronto',date,ownerId:identity.id,members:[{...identity,card:null}],status:'gathering',votes:{},proposal:null,revision:0,local:true,createdAt:Date.now()};
  saveRoom(room);return room;
}
export function getRoom(id) {return readRooms()[id]??null;}
export function listRooms() {return Object.values(readRooms()).sort((a,b)=>b.createdAt-a.createdAt);}
export function saveRoom(room) {const rooms=readRooms();rooms[room.id]=structuredClone(room);writeRooms(rooms);return room;}
export function updateLocal(id,update) {
  const room=getRoom(id);if(!room)throw new Error('This room is no longer available.');
  update(room);return saveRoom(room);
}
export function shareLocalCard(id,memberId,card) {return updateLocal(id,r=>{
  const member=r.members.find(m=>m.id===memberId);if(!member)throw new Error('Join this room first.');
  member.card=publicCard(card);r.proposal=null;r.votes={};r.status='gathering';r.revision++;
});}
export function proposeLocal(id,memberId,rank) {return updateLocal(id,r=>{
  if(r.ownerId!==memberId)throw new Error('The host proposes the group plan.');
  r.revision++;r.proposal={candidateId:rank.candidate.id,startMinute:rank.start,revision:r.revision};r.votes={};r.status='voting';
});}
export function voteLocal(id,memberId,choice) {return updateLocal(id,r=>{
  if(!r.proposal||!['yes','maybe','no'].includes(choice))throw new Error('Choose an active plan first.');
  if(!r.members.some(m=>m.id===memberId))throw new Error('Join the room first.');
  r.votes[memberId]={choice,revision:r.proposal.revision,candidateId:r.proposal.candidateId};
});}
export function confirmLocal(id,memberId) {return updateLocal(id,r=>{
  if(r.ownerId!==memberId)throw new Error('The host confirms the group plan.');
  if(!canConfirm(r))throw new Error('Everyone needs to accept the current proposal first.');r.status='confirmed';
});}
export function localPreferences(id) {try{return {...DEFAULT_CARD,...JSON.parse(localStorage.getItem(`meethalfway.preferences.${id}`)||'{}')};}catch{return structuredClone(DEFAULT_CARD);}}
export function rememberPreferences(id,card) {localStorage.setItem(`meethalfway.preferences.${id}`,JSON.stringify(publicCard(card)));}
export function clearDeviceData() {
  for(const key of Object.keys(localStorage))if(key.startsWith('meethalfway.'))localStorage.removeItem(key);
  window.dispatchEvent(new Event('meethalfway-change'));
}
