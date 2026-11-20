#!/usr/bin/env python3
"""Prepare the Flutter web build for the existing Firebase Hosting target."""
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
source, target = root / 'app/build/web', root / 'dist'
if not (source / 'flutter_bootstrap.js').is_file():
    raise SystemExit('Build Flutter web before packaging.')
if target.exists():
    shutil.rmtree(target)
shutil.copytree(source, target)
# Existing installations may request the original worker before loading index.html.
(target / 'sw.js').write_text('''self.addEventListener('install',e=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('meethalfway-')).map(k=>caches.delete(k)))).then(()=>self.registration.unregister()).then(()=>self.clients.claim())));
''')
print('Packaged Flutter web in dist/ for the existing Firebase Hosting configuration.')
