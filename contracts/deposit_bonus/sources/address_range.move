module deposit_bonus::utils;
use std::u256;
use deposit_bonus::err_consts;
public struct Range has copy,drop{
    start : u256,
    end  : u256
}

public(package) fun create_range(start : u256,end : u256) :Range {
    Range{
        start,
        end
    }
}

public(package) fun get_range(addr : address, length : u256) : vector<Range>{
    let point : u256 = addr.to_u256();
    let mut result : vector<Range> = vector[];
    let max = u256::max_value!();
    if( max -  point < length ){
        vector::push_back(&mut result,Range{
            start : point,
            end : max
        });
        vector::push_back(&mut result ,Range{
            start : 0,
            end :   length -( max - point)
        });
    }
    else{
        vector::push_back(&mut result,Range{
            start : point,
            end : point + length
        });
    };
    result
}

fun get_overlap_len(left : &Range, right : &Range) : u256{
    /*assert!(left.start <= left.end);
    assert!(right.start <= right.end);
    if(left.end < right.start || left.start > right.end){
        return 0
    };*/

    /*
      -------------------|-------------|---------------  
      -----------|-------------|---------------
    */
    let start = std::macros::num_max!(left.start,right.start);
    let end = std::macros::num_min!(left.end,right.end);
    if(start > end ){
        0
    }
    else
    {
        end - start
    } 
}
public(package) fun get_overlap_length(left : &vector<Range>,
                                   right : &vector<Range>) : u256{
    assert!(vector::length(left) >0 && vector::length(right) > 0,err_consts::empty_range!());
    let mut l : u64 = 0;
    let mut r : u64 = 0;
    let mut overlap_len : u256 = 0;
    while(l < left.length()){
        while(r < right.length()){
            
            overlap_len = overlap_len + get_overlap_len( vector::borrow(left,l), vector::borrow(right,r));
            r = r + 1;
        };
        l = l + 1;
    };
    return overlap_len

}

#[test_only] use  sui::test_utils as tu;
#[test]
fun test_range()
{
    assert!(get_overlap_len(&create_range(34, 100),
                            &create_range(50, 80)) == 30);
    assert!(get_overlap_len(&create_range(34, 100),
                            &create_range(50, 120)) == 50);
    assert!(get_overlap_len(&create_range(34, 100),
                            &create_range(50, 50)) == 0);
    let max = std::u256::max!();
    tu::assert_eq(get_overlap_len(&create_range(max - 30, max),
                        &create_range(50, 80)),0);
    tu::assert_eq(get_overlap_len(&create_range(max - 30, max),
                    &create_range(max - 20, max)),30);
    tu::assert_eq(get_overlap_len(&create_range(max - 30, max),
                    &create_range(max - 20, max)) == 30);
    
}
#[test]
fun test_ranges(){

}