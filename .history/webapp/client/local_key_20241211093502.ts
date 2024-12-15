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

import * as path from 'path'

export function get_keys() : string[] {
    dotenv.config();
    let home_dir = process.env.HOME || "~/";

    let file = path.join(home_dir, ".sui/sui_config/sui.keystore");
    console.log(file);
    let buffer = fs.readFileSync(file);
    let keys = JSON.parse(buffer.toString());
    //console.log(keys);
    return keys as unknown as string[];
}

export function get_first_key(){
    return get_keys()[0];
}

console.log(get_keys());

