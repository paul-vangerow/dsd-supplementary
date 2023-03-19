
# Cause CPP don't wanna work nicely we have to do it this way :(
import numpy as np

def main():

    f = open('out_file', 'r')
    start_params = f.readline().split(" ")

    MSE_RUNS = start_params[0]
    INPUT_DIST_NUM = start_params[1]
    NUM_CORDIC_STAGE = start_params[2]

    mse_vals = []
    mse_mean = 0

    for lines in f:
        local_sum = 0.0
        for vals in lines.strip("\n").split(" "):
            if (vals != ''):
                local_sum = local_sum + float(vals)

        mse_vals.append(local_sum / float(INPUT_DIST_NUM))
        mse_mean += local_sum / float(INPUT_DIST_NUM)

    mse_mean = mse_mean / float(MSE_RUNS)
    mse_standard_deviation = 0

    for v in mse_vals:
        mse_standard_deviation = pow((v - mse_mean), 2)
    mse_standard_deviation = np.sqrt( mse_standard_deviation / (float(MSE_RUNS) - 1))

    confidence_interval_min = mse_mean - ( 2 * mse_standard_deviation )
    confidence_interval_max = mse_mean + ( 2 * mse_standard_deviation )

    print("Confidence Interval = [" + str(confidence_interval_min) + ", " + str(confidence_interval_max) + "] ")

    f.close()

if __name__ == '__main__':
    main()