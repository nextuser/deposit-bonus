import * as fs from 'fs';
let fd = fs.openSync('.key','r')
let local_key = fs.readSync(fd);
fs.closeSync(fd);
console.log(local_key)
export local_key;

