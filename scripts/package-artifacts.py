"""Package known Flutter outputs and portable source, excluding credentials/caches."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import shutil

root = Path(__file__).resolve().parents[1]
out = root / 'artifacts'
out.mkdir(exist_ok=True)
apk = root / 'app/build/app/outputs/flutter-apk/app-debug.apk'
if apk.exists():
    shutil.copy2(apk, out / 'MeetHalfway-android-debug.apk')
if (root / 'dist/flutter_bootstrap.js').exists():
    with ZipFile(out / 'MeetHalfway-flutter-web.zip', 'w', ZIP_DEFLATED) as archive:
        for file in (root / 'dist').rglob('*'):
            if file.is_file():
                archive.write(file, file.relative_to(root / 'dist'))

with ZipFile(out / 'MeetHalfway-flutter-source.zip', 'w', ZIP_DEFLATED) as archive:
    for base in ['app', 'shared', 'scripts', 'docs', '.github', 'web/assets']:
        for file in (root / base).rglob('*'):
            if not file.is_file():
                continue
            relative = file.relative_to(root)
            parts = relative.parts
            if any(part.startswith('.') and part not in {'.github','.gitignore','.metadata'} for part in parts):
                continue
            if any(part in {'build','node_modules','failures','ephemeral','Pods','__pycache__'} for part in parts):
                continue
            if file.name in {'firebase.json','local.properties','GoogleService-Info.plist','google-services.json','Generated.xcconfig','flutter_export_environment.sh','GeneratedPluginRegistrant.h','GeneratedPluginRegistrant.m'}:
                continue
            archive.write(file, relative)
    for name in ['README.md','LICENSE','package.json','package-lock.json','firebase.json','firestore.rules','firestore.indexes.json','remoteconfig.template.json']:
        archive.write(root / name, name)
print('Packaged Flutter source, built web app and Android APK. No signing credentials or cached tools included.')
