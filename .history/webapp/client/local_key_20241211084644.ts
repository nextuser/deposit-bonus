import * as fs from 'fs';
let fd = fs.openSync('.key','r')
let buffer = new Buffer();
let len = 32;
let local_key = fs.readSync(fd,buffer,len);

fs.closeSync(fd);
console.log(local_key)


