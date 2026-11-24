import fs from 'node:fs/promises';
import path from 'node:path';
const args = process.argv.slice(2);
const option = name => args.includes(name) ? args[args.indexOf(name) + 1] : undefined;
const target = option('--directory') ?? 'dist';
const sha = option('--android-sha256');
const team = option('--apple-team-id');
const bundle = option('--ios-bundle-id') ?? 'app.meethalfway.mobile';
if (!sha && !team) throw new Error('Provide --android-sha256 and/or --apple-team-id from your real signing identities.');
if (sha && !/^([A-Fa-f0-9]{2}:){31}[A-Fa-f0-9]{2}$/.test(sha)) throw new Error('Use the SHA-256 certificate fingerprint, with colons.');
if (team && !/^[A-Z0-9]{10}$/.test(team)) throw new Error('Use your 10-character Apple team identifier.');
const dir = path.join(target, '.well-known');
await fs.mkdir(dir, {recursive: true});
if (sha) await fs.writeFile(path.join(dir, 'assetlinks.json'), JSON.stringify([{
  relation: ['delegate_permission/common.handle_all_urls'],
  target: {namespace: 'android_app', package_name: 'app.meethalfway.mobile', sha256_cert_fingerprints: [sha.toUpperCase()]},
}], null, 2) + '\n');
if (team) await fs.writeFile(path.join(dir, 'apple-app-site-association'), JSON.stringify({
  applinks: {details: [{appIDs: [`${team}.${bundle}`], components: ['invite', 'friend', 'room'].map(key => ({'/': '/', '?': {[key]: '*'}, comment: 'MeetHalfway links'}))}]},
}, null, 2) + '\n');
console.log(`Prepared verified-app-link documents in ${dir}. Deploy them with the matching signed apps.`);
