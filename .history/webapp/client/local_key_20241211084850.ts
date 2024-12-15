import * as fs from 'fs';
let fd = fs.openSync('.key','r')
let buffer = new Buffer();
let buffer_size = 100;
let read_len = fs.readSync(fd,buffer,0,buffer_size,null);
console.log(read_len);
fs.closeSync(fd);



