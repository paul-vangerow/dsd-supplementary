#!/bin/bash

iverilog -g2012 -o build/inner_expr src/converters.sv src/cordic_architectures.sv src/tb.sv && vvp build/inner_expr