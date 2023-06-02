clock Definition
create_clock -name CLK -period 2 clk 
##############################################
## Input Constraints
set_driving_cell -lib_cell IBUFFX2_RVT -input_transition_rise 0.1 -input_transition_fall 0.1 [all_inputs]
set_input_delay 0.08 -clock [get_clocks CLK] [all_inputs]
###############################################
# Output Constraints
set_load [expr [load_of [get_lib_pins */IBUFFX2_RVT/A]] * 4] [all_outputs]
set_output_delay 0.12 -clock [get_clocks CLK] [all_outputs]

###############################################
## Set Max Area Constraint
set_max_area 0
