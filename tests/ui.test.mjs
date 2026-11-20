import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {build} from 'esbuild';
import {Window} from 'happy-dom';
import path from 'node:path';

test('the real interface supports private card review, three-person consensus and feedback',async()=>{
  const bundle=await build({absWorkingDir:process.cwd(),entryPoints:[path.resolve('web/src/app.js')],tsconfigRaw:{},bundle:true,write:false,format:'iife',platform:'browser',target:'es2022'});
  const window=new Window({url:'http://localhost:4173',settings:{disableCSSFileLoading:true,disableJavaScriptFileLoading:true}});
  window.structuredClone=structuredClone;
  window.scrollTo=()=>{};
  const network=[];window.fetch=async(url)=>{network.push(String(url));throw new Error('No external services in this test.');};
  const html=(await readFile('web/index.html','utf8')).replace(/<script\b[^>]*>[\s\S]*?<\/script>/g,'');
  window.document.write(html);
  const settle=()=>new Promise(resolve=>setTimeout(resolve,20));
  const find=(action,id)=>window.document.querySelector(`[data-action="${action}"]${id?`[data-id="${id}"]`:''}`);
  async function click(action,id){const target=find(action,id);assert.ok(target,`Missing ${action} ${id||''}`);assert.ok(!target.disabled,`Disabled ${action}`);target.click();await settle();}
  try{
    window.eval(bundle.outputFiles[0].text);await settle();
    assert.match(window.document.body.textContent,/Make time for your people/);
    assert.equal(window.document.querySelectorAll('.orbit-tile').length,12);
    const seed=window.document.querySelector('#plan-seed');
    seed.value='Board games <with friends>';
    window.document.querySelector('#plan-seed-form').dispatchEvent(new window.Event('submit',{bubbles:true,cancelable:true}));await settle();
    assert.equal(window.document.querySelector('#new-title').value,'Board games <with friends>');
    assert.equal(window.document.querySelectorAll('[role=dialog] friends').length,0);
    await click('close-modal');
    await click('open-demo');
    assert.ok(window.document.querySelectorAll('.candidate').length>=3);
    assert.match(window.document.body.textContent,/sample group/);
    await click('edit-preferences');
    const note=window.document.querySelector('#private-note');note.value='RAW_PRIVATE_CANARY_918273';note.dispatchEvent(new window.Event('input',{bubbles:true}));
    const spend=window.document.querySelector('#spend');spend.value='20';spend.dispatchEvent(new window.Event('input',{bubbles:true}));
    await click('save-preferences');
    assert.match(window.document.querySelector('[role=dialog]').textContent,/Only the preferences below/);
    assert.ok(!window.document.querySelector('[role=dialog]').textContent.includes('RAW_PRIVATE_CANARY_918273'));
    await click('approve-share');
    assert.ok(!Object.values(window.localStorage).join(' ').includes('RAW_PRIVATE_CANARY_918273'));
    assert.ok(!network.some(url=>url.includes('RAW_PRIVATE_CANARY_918273')));
    const candidateId=find('plan-details').dataset.id;
    await click('plan-details',candidateId);await click('propose',candidateId);
    assert.ok(find('confirm').disabled);
    await click('vote','yes');
    await click('persona','maya');await click('vote','maybe');
    assert.equal(find('confirm'),null,'Only the host can confirm');
    await click('vote','yes');
    await click('persona','jordan');await click('vote','yes');
    await click('persona','alex');assert.ok(!find('confirm').disabled);
    await click('confirm');assert.match(window.document.body.textContent,/It’s a plan/);
    assert.ok(find('calendar'));
    await click('feedback');await click('feedback-like');
    assert.ok(window.localStorage.getItem('meethalfway.preferences.alex'));
    assert.ok(!window.document.querySelector('[role=dialog]'));
  }finally{await window.happyDOM.abort();window.close();}
});

test('a local room can be created and gains a shortlist only when the host shares a card',async()=>{
  const bundle=await build({absWorkingDir:process.cwd(),entryPoints:[path.resolve('web/src/app.js')],tsconfigRaw:{},bundle:true,write:false,format:'iife',platform:'browser',target:'es2022'});
  const window=new Window({url:'http://localhost:4173',settings:{disableCSSFileLoading:true,disableJavaScriptFileLoading:true}});
  window.structuredClone=structuredClone;window.scrollTo=()=>{};
  window.fetch=async()=>({ok:false});
  window.document.write((await readFile('web/index.html','utf8')).replace(/<script\b[^>]*>[\s\S]*?<\/script>/g,''));
  const settle=()=>new Promise(r=>setTimeout(r,20));
  try{
    window.eval(bundle.outputFiles[0].text);await settle();
    window.document.querySelector('[data-action="new-room"]').click();await settle();
    window.document.querySelector('#new-name').value='Sam';
    window.document.querySelector('#new-title').value='<script>friendly plan</script>';
    window.document.querySelector('#new-room-form').dispatchEvent(new window.Event('submit',{bubbles:true,cancelable:true}));await settle();
    assert.match(window.document.body.textContent,/friendly plan/);
    assert.equal(window.document.querySelectorAll('#main script').length,0,'User text must not become markup');
    assert.equal(window.document.querySelectorAll('.candidate').length,0);
    window.document.querySelector('[data-action="add-sample"]').click();await settle();
    window.document.querySelector('[data-action="edit-preferences"]').click();await settle();
    window.document.querySelector('[data-action="save-preferences"]').click();await settle();
    window.document.querySelector('[data-action="approve-share"]').click();await settle();
    assert.ok(window.document.querySelectorAll('.candidate').length>0);
    window.document.querySelector('[data-action="add-option"]').click();await settle();
    window.document.querySelector('#option-name').value='Our actual game night';
    window.document.querySelector('#option-venue').value='Host-selected café';
    window.document.querySelector('#option-description').value='A real group choice with host-provided details.';
    assert.equal(window.document.querySelector('#option-opens option[selected]').value,'960');
    assert.equal(window.document.querySelector('#option-closes option[selected]').value,'1320');
    // Happy DOM 21 mis-selects the second option while parsing selects inside
    // forms. Normalize to the declared HTML selection before testing submission.
    for(const select of window.document.querySelectorAll('#option-form select'))select.value=(select.querySelector('option[selected]')||select.options[0]).value;
    window.document.querySelector('#option-form').dispatchEvent(new window.Event('submit',{bubbles:true,cancelable:true}));await settle();
    assert.match(window.document.body.textContent,/Our actual game night/);
    assert.match(window.document.body.textContent,/provided by the host/);
    assert.equal(window.document.querySelectorAll('.shortlist-grid .candidate').length,1,'A real activity replaces the sample catalogue');
  }finally{await window.happyDOM.abort();window.close();}
});
