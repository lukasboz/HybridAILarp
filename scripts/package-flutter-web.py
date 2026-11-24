#!/usr/bin/env python3
"""Prepare the Flutter web build for the existing Firebase Hosting target."""
from pathlib import Path
import shutil
import hashlib
import json

root = Path(__file__).resolve().parents[1]
source, target = root / 'app/build/web', root / 'dist'
if not (source / 'flutter_bootstrap.js').is_file():
    raise SystemExit('Build Flutter web before packaging.')
if target.exists():
    shutil.rmtree(target)
shutil.copytree(source, target)
# Version the app shell, leaving model caches owned by the inference runtime.
files = sorted(p.relative_to(target).as_posix() for p in target.rglob('*')
               if p.is_file() and p.name not in ['sw.js', 'flutter_service_worker.js']
               and not p.name.endswith('.map') and '.well-known' not in p.parts)
digest = hashlib.sha256()
for name in files:
    digest.update(name.encode())
    digest.update((target / name).read_bytes())
worker = (root / 'app/web/sw.js').read_text()
worker = worker.replace("'meethalfway-shell-development'", repr('meethalfway-shell-' + digest.hexdigest()[:16]))
worker = worker.replace('const SHELL = [];', 'const SHELL = ' + json.dumps(files) + ';')
(target / 'sw.js').write_text(worker)
print('Packaged Flutter web in dist/ for the existing Firebase Hosting configuration.')
