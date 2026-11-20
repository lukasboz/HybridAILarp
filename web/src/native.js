const waiting=new Map();
let sequence=0;
// The native bridge is deliberately limited to inference, capabilities and sharing.
// It is never a generic URL fetcher, shell, or arbitrary native invocation API.
export const platform=window.webkit?.messageHandlers?.meethalfway?'ios':window.MeetHalfwayAndroid?'android':'web';
window.meethalfwayNativeResult=(id,result,error)=>{
  const pending=waiting.get(String(id));if(!pending)return;
  clearTimeout(pending.timeout);waiting.delete(String(id));
  error?pending.reject(new Error(error)):pending.resolve(result);
};
export function nativeCall(method,payload={}) {
  if(platform==='web')return Promise.reject(new Error('Native integration is unavailable in this browser.'));
  const id=String(++sequence);
  return new Promise((resolve,reject)=>{
    const timeout=setTimeout(()=>{waiting.delete(id);reject(new Error('The device took too long. Your private input has not been sent to the cloud.'));},90000);
    waiting.set(id,{resolve,reject,timeout});
    const message=JSON.stringify({id,method,payload});
    try {if(platform==='ios')window.webkit.messageHandlers.meethalfway.postMessage(message);else window.MeetHalfwayAndroid.postMessage(message);}
    catch(error){clearTimeout(timeout);waiting.delete(id);reject(error);}
  });
}
export async function shareText(title,text,url) {
  if(platform!=='web')return nativeCall('share',{title,text,url});
  if(navigator.share)return navigator.share({title,text,url});
  await navigator.clipboard.writeText([text,url].filter(Boolean).join('\n'));return {copied:true};
}
