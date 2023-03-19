#!/bin/bash

g++ -o file.out cordic.cpp -std=c++17
./file.out

python3 'analyse_data.py'