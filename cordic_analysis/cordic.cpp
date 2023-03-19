#include <iostream>
#include <bitset>
#include <math.h>
#include <tuple>
#include <random>
#include <utility>
#include <numeric>
#include <fstream>
#include <iomanip>

// Implement Cordic

/* Fixed Point Representation

    Agree on where the decimal point is.
    
After multiplication the point will move, so shift up and truncate to return to the correct value
    
    Cordic inputs: [-1, 1], signed, <= 1.
    
*/

class Cordic_Stage
{
private:
    int i;
    int thetai;
    
    int32_t inv_sign(int32_t num, bool en){
        return en ? (~num) + 1 : num;
    }
    
    int32_t xi_p(int32_t xi, int32_t yi, int32_t zi){
        return xi - inv_sign( (yi >> i), (zi < 0) );
    }
    
    int32_t yi_p(int32_t xi, int32_t yi, int32_t zi){
        return yi + inv_sign( (xi >> i), (zi < 0) );
    }
    
    int32_t zi_p(int32_t zi){
        std::cout << "I_VAL: " << i << " zi_p: " << std::hex << ( (zi - inv_sign( thetai , (zi < 0) ) ) & 0x3FFFFF) << " z_i: " << std::hex << (zi & 0x3FFFFF) << " THETA_I: " << std::hex << (thetai & 0x3FFFFF) << std::endl;
        return zi - inv_sign( thetai , (zi < 0) );
    }
    
public:
    
    Cordic_Stage(int _i, int _thetai){
        i = _i;
        thetai = _thetai;
    }
    
    std::tuple<int32_t, int32_t, int32_t> calc_p(std::tuple<int32_t, int32_t, int32_t> values) {
        return std::make_tuple( xi_p(std::get<0>(values), std::get<1>(values), std::get<2>(values)),
                                yi_p(std::get<0>(values), std::get<1>(values), std::get<2>(values)),
                                zi_p(std::get<2>(values) ) );
    }
};

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

    return (sign ? (~(val >> (127 - exponent)) + 1) : val >> (127 - exponent)); // Twos complementify
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
    out_union.i = (sign << 31) | (exponent << 23) | ((NUM_DIGITS-2) > 23 ? (v >> ( (NUM_DIGITS-2) - 23)) : (v << ( 23 - (NUM_DIGITS-2)) )) & 0x7FFFFF;

    return out_union.f;
}

int main() {
    // Write C++ code here
    
    int32_t n = 16;
    
    int32_t input_dist_number = 1;
    int32_t MSE_RUNS = 1;
    
    // Cordic Setup and Processing
    
    int32_t K = fl_f(1);
    Cordic_Stage* stages[n];
    
    // Create Each Cordic Stage
    for (int i = 0; i < n; i++){
        float tanangle = atan( pow(2, -i) );
        int32_t angle = fl_f( tanangle ); // Should be precomputed

        // std::cout << tanangle << " " << std::hex << angle << std::endl;

        long double temp = 1;
        for (int l = 0; l <= i; l++){
            temp = temp * cosl(atanl( pow(2, -l) )); 
        }
        
        K = fl_f((float)temp); // Should be precomputed

        // std::cout << i << " " << std::hex << (K & 0x3FFFFF) << " " << std::hex << (angle & 0x3FFFFF) << std::endl;
        
        stages[i] = new Cordic_Stage(i, angle);
    }
    
    // Statistical Processing

    std::ofstream outputFile;
    outputFile.open("out_file");
    
    std::random_device rd;  // Will be used to obtain a seed for the random number engine
    std::mt19937 gen(rd()); // Standard mersenne_twister_engine seeded with rd()
    std::uniform_real_distribution<> dis(-1.0, 1.0);
    
    outputFile << MSE_RUNS << " " << input_dist_number << " " << n << std::endl; // Set Parameters
    
    for (int l = 0; l < MSE_RUNS; l++){

        for (int j = 0; j < input_dist_number; j++){
        
            float a = 1; //(float)dis(gen); // Generate a random input value
            
            std::tuple<int32_t, int32_t, int32_t> passer = std::make_tuple(K, 0, fl_f(a));
            for (int i = 0; i < n; i++){
                passer = stages[i]->calc_p(passer); 
            }
            
            float out_val = f_fl(std::get<0>(passer)); // Get Sine Value
            double actual_val = cos( (double)a);

            std::cout << out_val << " " << actual_val << std::endl;

            double calc = pow((double)out_val - actual_val, 2);
            outputFile << calc << " ";
        }
        outputFile << std::endl;
    }

    outputFile.close();

    return 0;
}