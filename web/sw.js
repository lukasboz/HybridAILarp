const CACHE='meethalfway-v3-native-design';
const FILES=['./tokens.css','./fonts.css','./assets/fonts/Inter-Regular.ttf','./assets/fonts/Inter-Medium.ttf','./assets/fonts/Inter-SemiBold.ttf','./','./index.html','./styles.css','./yumi.css','./manifest.webmanifest','./assets/mark.svg','./src/app.js','./src/domain.js','./src/catalog.js','./src/storage.js','./src/visuals.js','./src/ai.js','./src/firebase.js','./src/native.js','./src/discovery.js','./assets/activities/games.jpg','./assets/activities/art.jpg','./assets/activities/coffee.jpg','./assets/activities/food.jpg','./assets/activities/park.jpg','./assets/activities/water.jpg','./assets/activities/market.jpg'];
self.addEventListener('install',event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(FILES)).then(()=>self.skipWaiting())));
self.addEventListener('activate',event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',event=>{
  const url=new URL(event.request.url);
  // Invitations, SDK calls, config, Firebase data and private input aren't cached.
  if(event.request.method!=='GET'||url.origin!==self.location.origin||url.search||url.pathname.includes('firebase-config.local'))return;
  event.respondWith(fetch(event.request).then(response=>{
    if(response.ok&&FILES.some(f=>new URL(f,self.registration.scope).pathname===url.pathname)){
      const copy=response.clone();caches.open(CACHE).then(cache=>cache.put(event.request,copy));
    }return response;
  }).catch(()=>caches.match(event.request).then(cached=>cached||new Response('You are offline. Open a previously saved page.',{status:503}))));
});
