
#include <iostream>
#include <bitset>

union float_to_int{
    float f;
    uint32_t i;
};

int32_t NUM_DIGITS = 22;

int32_t fl_f(float number){

    float_to_int in_union;
    in_union.f = number;

    uint8_t sign = (in_union.i >> 31) & 0x1;
    uint8_t exponent = (in_union.i >> 23) & 0xFF; // Exp 127 ----> val = 0

    // Don't need the Mantissa because the value cannot diverge from this ( Undefined Bahviour will not be accounted for )
    if (exponent == 128 && sign == 1) return ( 0x1 << (NUM_DIGITS-1)); 
    
    // Mantissa Shifted out, no point in shifting it.
    if (exponent < (127-(NUM_DIGITS-2))) return 0;

    int32_t mantissa = (1 << 23) | (in_union.i & 0x7FFFFF); // 24  bit mantissa value

    // Shift to decimal place      bit 23 ends up on bit NUM_DIGITS-2
    int32_t val = (NUM_DIGITS > 24) ? (mantissa << ( (NUM_DIGITS-2) - 23 )) : (mantissa >> ( 23 - (NUM_DIGITS-2) )); 

    int32_t AND_VAL = 0;
    for (int i = 0; i < NUM_DIGITS; i++){
        AND_VAL = AND_VAL | (0x1 << i);
    }

    std::cout << std::bitset<32>(AND_VAL) << std::endl;

    return (sign ? (~(val >> (127 - exponent)) + 1) : val >> (127 - exponent)) & AND_VAL; // Twos complementify
}

float f_fl(int32_t number){

    if (number == ( 0x1 << (NUM_DIGITS-1))) return 0xC0000000; // The number is the maximum negative (-2)
    if (number == 0x0) return 0x0; // The input number was 0 (or too small)

    uint32_t sign = (number >> (NUM_DIGITS-1)) ? 1 : 0;
    uint32_t v = sign ? ( (~number) + 1) : number; // Remove Twos complement
    uint32_t exponent = 127; // 2^0 = 1

    while ( ((v >> (NUM_DIGITS-2)) & 0x1) != 0x1){
        v = v << 1;
        exponent--;
    }

    float_to_int out_union;
    out_union.i = (sign << 31) | (exponent << 23) | (  (NUM_DIGITS-2) > 23 ? (v >> ( (NUM_DIGITS-2) - 23)) : (v << ( 23 - (NUM_DIGITS-2)) ) & 0x7FFFFF);
    // std::cout << std::bitset<32>(out_union.i) << std::endl;
    return out_union.f;
}

int main() {

    int32_t fixed = 0x3f3db0;

    std::cout << f_fl(fixed) << std::endl;

    return 0;
}