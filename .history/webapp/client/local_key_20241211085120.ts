import * as fs from 'fs';
let fd = fs.openSync('.key','r')
let buffer = Buffer.alloc(100);
let buffer_size = 100;
let read_len = fs.readSync(fd,buffer,0,buffer_size,null);

console.log(read_len);
console.log(buffer.toString());
fs.closeSync(fd);



