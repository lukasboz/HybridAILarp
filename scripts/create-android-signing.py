#!/usr/bin/env python3
"""Create a local Android signing identity once; never overwrite existing keys."""
import os
from pathlib import Path
import secrets
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
properties = root / 'app/android/key.properties'
keystore = root / '.cache/signing/meethalfway-upload.jks'
if properties.exists() or keystore.exists():
    raise SystemExit('A local signing configuration or keystore already exists. Preserve it; do not regenerate an installed app identity.')
keytool = shutil.which('keytool')
if not keytool:
    raise SystemExit('Install a JDK and put keytool on PATH.')
keystore.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
password = secrets.token_urlsafe(36)
environment = dict(os.environ, MEETHALFWAY_KEY_PASSWORD=password)
subprocess.run([
    keytool, '-genkeypair', '-keystore', str(keystore), '-storetype', 'JKS',
    '-alias', 'meethalfway', '-keyalg', 'RSA', '-keysize', '4096',
    '-validity', '10000', '-dname', 'CN=MeetHalfway',
    '-storepass:env', 'MEETHALFWAY_KEY_PASSWORD', '-keypass:env', 'MEETHALFWAY_KEY_PASSWORD',
], env=environment, check=True, stdout=subprocess.DEVNULL)
keystore.chmod(0o600)
with properties.open('x') as output:
    os.chmod(properties, 0o600)
    output.write(f'storeFile={keystore}\nstorePassword={password}\nkeyAlias=meethalfway\nkeyPassword={password}\n')
print('Created ignored local signing files. Back up .cache/signing/ and app/android/key.properties securely before distributing this app.')
