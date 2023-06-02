###################################################################
# This variable needs to be modified before running this script:
#global DESIGN_NAME
set DESIGN_NAME [getenv "DESIGN_NAME"]
#source ${DESIGN_HOME}/design_name.tcl
###################################################################
# Setup
puts "Hostname : [info hostname]"

################################
# Directory housekeeping
foreach dir "outputs reports" {
  if {![file isdirectory $dir]} {
    file mkdir $dir
  }
}

redirect -file /dev/null {set start_time [clock seconds]}

################################
# setup tool cache so it doesn't clutter up working dir
if {![file exists ./synopsys_cache]} {file mkdir ./synopsys_cache}
set_app_var cache_write ./synopsys_cache
set_app_var cache_read ./synopsys_cache
set_app_var cache_file_chmod_octal 666
set_app_var cache_dir_chmod_octal 777

################################
# Create a name-mapping database to faithfully annotate SAIF data
saif_map -start

################################
# STEP: Analyze and elaborate the design, read the design constraints
set elapsed_time [expr { ([clock seconds] - $start_time) / 60.0 }]
puts [format "##### Analyzing the Design. Runtime: %.2f mins #####" $elapsed_time]

if {[file exists ./inputs/rtl/${DESIGN_NAME}.v]} {
  analyze {./inputs/rtl/} -autoread -recursive -verbose -rebuild -top $DESIGN_NAME
} else {
  puts "==>FATAL: ${DESIGN_NAME}.v rtl source file does not exist in ./inputs/rtl area. Exiting..."
}

elaborate ${DESIGN_NAME} -architecture verilog -library WORK -update
current_design ${DESIGN_NAME}

if {![eval {link}]} {
  puts "==>FATAL: Design Link Failed... Exiting..."
} else {
  link > ./reports/${DESIGN_NAME}.syn.link.rpt
}

###############################
# prevent assign statements
set_app_var verilogout_no_tri true
set_fix_multiple_port_nets -all
set_app_var uniquify_keep_original_design true

###############################
# Read IO, Loading and timing constraints
if {[file exists ./inputs/constraints/${DESIGN_NAME}.constraints.tcl]} {
  puts "==>INFORMATION: Sourcing the design constraints file"
  source -echo -verbose ./inputs/constraints/${DESIGN_NAME}.constraints.tcl
} else {
  puts "==>FATAL: Design Constraints file does not exists... Exiting..."
}

##############################
# Set the Clock/Scan_Enable network as Dont Touch Network
set_dont_touch_network [get_clocks]

###############################
# Set wire load model and operating condition
set_wire_load_model -name 8000 -library [get_libs]
set_operating_conditions -analysis_type bc_wc -max ss0p95v125c

###############################
# Path group setup
group_path -name inputs -from [all_inputs]
group_path -name output -to [all_outputs]
group_path -name comb -from [all_inputs] -to [all_outputs]
group_path -name reg2reg -from [all_registers -clock_pins] -to [all_registers -data_pins]

set_critical_range 2000 [current_design]

###############################
# Annotate Switching Activity data on to the design
if {[file exists ./inputs/switching_activity/${DESIGN_NAME}.switching_activity.tcl]} {
  source -echo -verbose ./inputs/switching_activity/${DESIGN_NAME}.switching_activity.tcl
} else {
  puts "Warning: Assuming default Switching Activity since no information is found..."
}

###############################
# Set Multithreshold Voltage Constraints
set_multi_vth_constraint -lvth_groups {saed32cell_lvt} -lvth_percentage 10 -type hard

###############################
# RTL Test DRC

set_scan_configuration -style multiplexed_flip_flop
set_dft_signal -view existing_dft -type ScanClock -timing {45 55} -port clk

create_test_protocol -infer_asynch -infer_clock

dft_drc -verbose 				> ./reports/${DESIGN_NAME}.RTLTestDRC.rpt

###############################
# STEP: Compile
set elapsed_time [expr { ([clock seconds] - $start_time) / 60.0} ]
puts [format "##### Running Compile. Runtime: %.2f mins #####" $elapsed_time]

###############################
# set fsm extraction and optimization directive
set_app_var fsm_auto_inferring true
set_app_var fsm_enable_state_minimization true
set_fsm_minimize true
set_fsm_encoding_style auto

##############################
# Set Clock Gating Style
set_clock_gating_style -pos integrated -neg integrated -control_point after 

#############################
# Enable Dynamic Power Optimization
set_dynamic_optimization true
 
#############################
# Launch Scan-Ready Compile
compile_ultra -exact_map -scan -gate_clock

#############################
# Connect Scan Chains
set_dft_signal -view existing_dft -type ScanDataIn -port test_si
set_dft_signal -view existing_dft -type ScanDataOut -port test_so
set_dft_signal -view existing_dft -type ScanEnable -port test_se

set_scan_configuration -replace false

create_test_protocol -infer_asynch -infer_clock

dft_drc -verbose				> ./reports/${DESIGN_NAME}.PreDFTDRC.rpt

insert_dft

dft_drc -verbose -coverage			> ./reports/${DESIGN_NAME}.PostSynthesis.PostDFTDRC.rpt
redirect -file ./reports/${DESIGN_NAME}.PostSynthesis.PostDFTDRC.rpt -append {getenv LOGNAME}
write_test_protocol -output ./outputs/${DESIGN_NAME}.spf

##############################
# STEP: Incremental Compile
set elapsed_time [expr { ([clock seconds] - $start_time) / 60.0} ]
puts [format "##### Running Incremental Compile. Runtime: %.2f mins #####" $elapsed_time]

#compile -incremental_mapping
compile_ultra -incremental -scan

##############################
# STEP: Outputs and Reports
set elapsed_time [expr { ([clock seconds] - $start_time) / 60.0} ]
puts [format "##### Running Outputs and Reports. Runtime: %.2f mins #####" $elapsed_time]

##############################
# change names
define_name_rules standard_names \
	-allowed "A-Za-z0-9_\[\]" \
	-equal_ports_nets \
	-remove_internal_net_bus \
	-target_bus_naming_style "%s\[%d\]" \
	-add_dummy_nets \
	-flatten_multi_dimension_busses

define_name_rules reg_names \
	-type cell \
	-map {{{"\]", "x"}, {"\[", "x"}}}

change_names -hierarchy -verbose -rules reg_names > ./logs/change_names_reg.log
change_names -hierarchy -verbose -rules standard_names > ./logs/change_names_standard.log

##############################
# Dump out the block level SCANDEF before pushing
# down the design. This enable to preserve the synthesized
# scan chain information during the process of pushing down
# the module logic. It aids in the smooth transition of 
# SCANDEF data on to ICC flow. (Synopsys recommended)
write_scan_def -output ./outputs/${DESIGN_NAME}.scan.def 

remove_test_model 

push_down_model full_chip_${DESIGN_NAME}

if {[file exists ./scripts/create_top_level_scandef.tcl]} {
  source ./scripts/create_top_level_scandef.tcl
  create_top_level_scandef -output ./outputs/full_chip_${DESIGN_NAME}.scan.def "./outputs/${DESIGN_NAME}.scan.def"
} else {
  puts "==>FATAL: Required script create_top_level_scandef.tcl does not exist in ./scripts area. Exiting..."
}

file rename -force ./outputs/full_chip_${DESIGN_NAME}.scan.def ./outputs/${DESIGN_NAME}.scan.def

###############################
# path group re-setup - some path graph may have become invalid during design compile
group_path -name inputs -from [all_inputs]
group_path -name output -to [all_outputs]
group_path -name comb -from [all_inputs] -to [all_outputs]
group_path -name reg2reg -from [all_registers -clock_pins] -to [all_registers -data_pins]

##############################
# change names
define_name_rules standard_names \
	-allowed "A-Za-z0-9_\[\]" \
	-equal_ports_nets \
	-remove_internal_net_bus \
	-target_bus_naming_style "%s\[%d\]" \
	-add_dummy_nets \
	-flatten_multi_dimension_busses

define_name_rules reg_names \
	-type cell \
	-map {{{"\]", "x"}, {"\[", "x"}}}

change_names -hierarchy -verbose -rules reg_names >> ./logs/change_names_reg.log
change_names -hierarchy -verbose -rules standard_names >> ./logs/change_names_standard.log

##############################
# Outputs
write_file -format verilog -hierarchy -output ./outputs/${DESIGN_NAME}.vg
write_file -format ddc -hierarchy -output ./outputs/${DESIGN_NAME}.ddc
# Setting variables to not write out load/resistance in sdc
set write_sdc_output_lumped_net_capacitance false
set write_sdc_output_net_resistance false
write_sdc -nosplit ./outputs/${DESIGN_NAME}.sdc
write_saif -propagated -output ./outputs/${DESIGN_NAME}.saif

##############################
# Reports
report_area					> ./reports/${DESIGN_NAME}.area.rpt
report_reference -hierarchy -nosplit		> ./reports/${DESIGN_NAME}.ref.rpt
report_qor					> ./reports/${DESIGN_NAME}.qor.rpt
report_power -analysis_effort high -verbose	> ./reports/${DESIGN_NAME}.PostSynthesis.power.rpt
redirect -file ./reports/${DESIGN_NAME}.PostSynthesis.power.rpt -append {getenv LOGNAME}
report_constraint -all_violators -nosplit	> ./reports/${DESIGN_NAME}.constraint.rpt
check_design					> ./reports/${DESIGN_NAME}.check_design.rpt
check_timing					> ./reports/${DESIGN_NAME}.check_timing.rpt
report_fsm					> ./reports/${DESIGN_NAME}.fsm.rpt
report_saif -hier				> ./reports/${DESIGN_NAME}.saif.rpt
report_clock_gating				> ./reports/${DESIGN_NAME}.clock_gating.rpt
report_timing -nosplit -capacitance \
-transition_time -significant_digits 2 \
-input_pins -nets 				> ./reports/${DESIGN_NAME}.PostSynthesis.timing.rpt
redirect -file ./reports/${DESIGN_NAME}.PostSynthesis.timing.rpt -append {getenv LOGNAME}
sh zip -j -u ../EE5327_Lab9_[getenv LOGNAME]_${DESIGN_NAME}.zip ./reports/*.PostSynthesis*
set elapsed_time [expr { ([clock seconds] - $start_time) / 60.0} ]
puts [format "##### Done. Runtime: %.2f mins, Memory Used: %.1f GB #####" $elapsed_time [expr [mem] / 1000000.0]]
exit
