// Upload only: no recipient invitations, email notifications or automated tests.
import {readFile, access} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const binary = path.resolve(process.argv[2] ?? path.join(root, 'app/build/app/outputs/flutter-apk/app-release.apk'));
if (!binary.endsWith('.apk')) throw new Error('Supply a signed APK. AAB distribution requires a linked Google Play app.');
await access(binary);
const config = JSON.parse(await readFile(path.join(root, 'app/assets/firebase.json'), 'utf8'));
const app = config.android?.appId;
const project = config.android?.projectId;
if (!/^1:\d+:android:[a-f0-9]+$/.test(app ?? '') || !project) throw new Error('Sync the registered Android Firebase client configuration first.');
const result = spawnSync('npx', [
  '--cache', path.join(root, '.cache/npm'), '--yes', 'firebase-tools@latest',
  'appdistribution:distribute', binary, '--app', app, '--project', project,
  '--release-notes-file', path.join(root, 'docs/RELEASE-NOTES.md'), '--non-interactive',
], {cwd: root, stdio: 'inherit'});
if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
