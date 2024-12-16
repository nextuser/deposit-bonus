import { format } from 'date-fns';

export function to_date_str(time_ms : number) : string{
  let d = new Date(time_ms);
  return format(d,'yyyy-MM-dd HH:mm');
}

const SUI_OVER_FROST = 1e9;
export function sui_show( amount : number) : string{
  amount = Math.abs(amount) < 1 ? 0 : amount; 
  let ret =   ` ${(amount/SUI_OVER_FROST).toFixed(9)} SUI`;
   
   return ret;
                         
}
