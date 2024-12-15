import * as fs from 'fs';
let fd = fs.openSync('.key','r')
let buffer = new Buffer();
let buffer_size = 32;
let local_key = fs.readSync(fd,buffer,buffer_size);

fs.closeSync(fd);
console.log(local_key)


