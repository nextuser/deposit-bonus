import * as fs from 'fs';
import * as  dotenv from 'dotenv';

export function get_key() : string{
    let fd = fs.openSync('.key','r')
    let buffer = Buffer.alloc(100);
    let buffer_size = 100;
    let read_len = fs.readSync(fd,buffer,0,buffer_size,null);

    fs.closeSync(fd);
    let ret = buffer.toString().trim().substring(0,read_len);
    return ret;
}


export function get_keys() : string[] {
    dotenv.config();
    process.env.HOME
    let dir = 
}


