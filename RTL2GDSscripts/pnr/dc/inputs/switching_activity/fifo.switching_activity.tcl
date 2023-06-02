###################################
### Define the swicthing activity for
## the primary ports
## ###################################
set_switching_activity -static_probability 0.995 -toggle_rate 0.015625 -period 1000 [get_ports rst]
set_switching_activity -static_probability 0 -toggle_rate 0 -period 1000 [get_ports test_se]
set_switching_activity -static_probability 0 -toggle_rate 0 -period 1000 [get_ports test_si]

