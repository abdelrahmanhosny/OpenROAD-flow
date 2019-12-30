export DESIGN_NAME = gcd
export PLATFORM    = gf14

export VERILOG_FILES = ./designs/src/gcd/gcd.v
export SDC_FILE      = ./designs/src/gcd/gcd.sdc

# These values must be multiples of placement site
export DIE_AREA    = 0 0 100 100.8
export CORE_AREA   = 10 12 90 91.2
export CORE_WIDTH  = 80
export CORE_HEIGHT = 79.2

export CLOCK_PERIOD = 10.000
export CLOCK_PORT   = clk
