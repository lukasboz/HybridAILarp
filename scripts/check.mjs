import { spawnSync } from 'node:child_process';
import { readdir } from 'node:fs/promises';
for(const directory of ['web/src','scripts'])for(const name of await readdir(directory)){
  if(!/\.(m?js)$/.test(name))continue;
  const result=spawnSync(process.execPath,['--check',`${directory}/${name}`],{stdio:'inherit'});
  if(result.status!==0)process.exit(result.status||1);
}
console.log('All JavaScript modules passed syntax validation.');
