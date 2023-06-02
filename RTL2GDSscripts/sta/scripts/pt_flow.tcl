set COMMENTED_OUT [list ]
###################################################################
# This variable needs to be modified before running this script:
set DESIGN_NAME [getenv "DESIGN_NAME"]

###################################################################
# Setup
puts "Hostname : [info hostname]"

################################
# Directory housekeeping
foreach dir "outputs reports" {
  if {![file isdirectory $dir]} {
    file mkdir $dir
    
  }
  sh rm -rf $dir/*  
}

redirect -file /dev/null {set start_time [clock seconds]}

################################
# Read gate-level netlist obtained after APR
if {[file exists ./inputs/${DESIGN_NAME}.vg]} {
  puts "==>INFORMATION: Reading the gate-level netlist."
  read_verilog ./inputs/${DESIGN_NAME}.vg
} else {
  puts "==>FATAL: ${DESIGN_NAME}.vg synthesized gate-level netlist does not exist in ./inputs/ area. Exiting..."
}

#
###############################
# Setting the current deisgn
enable_primetime_icc_consistency_settings
current_design full_chip_${DESIGN_NAME}
set default_groups [get_path_groups]
#set_app_var power_model_preference ccs
#set_app_var rc_driver_model_mode advanced
#set_app_var rc_receiver_model_mode advanced
###############################
# Read the constraint file
if {[file exists ./inputs/${DESIGN_NAME}.sdc] } {
  puts "==>INFORMATION: Reading the constraints file."
  read_sdc ./inputs/${DESIGN_NAME}.sdc
} else {
  puts "==>FATAL: ${DESIGN_NAME}.sdc does not exist in ./inputs/ area. Exiting..."
}

###############################
# Read the back-annotated delay file from IC-Compiler
if {[file exists ./inputs/${DESIGN_NAME}.sdf] } {
  puts "==>INFORMATION: Reading the delay file."
  read_sdf -analysis_type bc_wc ./inputs/${DESIGN_NAME}.sdf
} else {
  puts "==>FATAL: ${DESIGN_NAME}.sdf does not exist in ./inputs/ area. Exiting..."
}

#############################
# Setting up for power analysis
set power_enable_analysis true

##############################
# Read the switching activity information

if {[file exists ./inputs/${DESIGN_NAME}.saif] } {
  puts "==>INFORMATION: Reading the switching activity file."
  read_saif ./inputs/${DESIGN_NAME}.saif -strip_path full_chip_${DESIGN_NAME}
} else {
  puts "==>FATAL: ${DESIGN_NAME}.saif does not exist in ./inputs/ area. Exiting..."
}

###############################
# Read the extracted parasitics from IC-Compiler post APR

if {([file exists ./inputs/${DESIGN_NAME}.spef.max.gz]) && ([file exists ./inputs/${DESIGN_NAME}.spef.min.gz])} {
  puts "==>INFORMATION: Reading the parasitics files."
  read_parasitics -format SPEF ./inputs/${DESIGN_NAME}.spef.max.gz
  
} else {
  puts "==>FATAL: ${DESIGN_NAME}.spef.max or ${DESIGN_NAME}.spef.min parasitics does not exist in ./inputs/ area. Exiting..."
}

###############################
# Setting the operating conditions
set_operating_conditions -max ss0p95v125c -min ff0p95vn40c



###############################
# Path group setup

group_path -name inputs -from [all_inputs]
group_path -name output -to [all_outputs]
group_path -name comb -from [all_inputs] -to [all_outputs]
group_path -name reg2reg -from [all_registers -clock_pins] -to [all_registers -data_pins]

###############################
# Generating timing reports for setup and hold analysis

foreach_in_collection group [remove_from_collection [get_path_groups] $default_groups] {
  set group_name [get_object_name $group]
  if { [sizeof_collection [get_timing_paths -group $group_name]] } {
    redirect -append -file ./reports/pba_${DESIGN_NAME}.timing_setup.rpt {
      report_timing \
                -pba_mode path \
				-nosplit \
                -capacitance \
                -transition_time \
                -significant_digits 10 \
                -input_pins -nets \
                -group $group_name
    }
  }
}

foreach_in_collection group [remove_from_collection [get_path_groups] $default_groups] {
  set group_name [get_object_name $group]
  if { [sizeof_collection [get_timing_paths -group $group_name]] } {
    redirect -append -file ./reports/gba_${DESIGN_NAME}.timing_setup.rpt {
      report_timing \
				-nosplit \
                -capacitance \
                -transition_time \
                -significant_digits 10 \
                -input_pins -nets \
                -group $group_name
    }
  }
}


remove_annotated_parasitics -all
read_parasitics -format SPEF ./inputs/${DESIGN_NAME}.spef.min.gz

foreach_in_collection group [remove_from_collection [get_path_groups] $default_groups]  {
  set group_name [get_object_name $group]
  if { [sizeof_collection [get_timing_paths -group $group_name]] } {
    redirect -append -file ./reports/pba_${DESIGN_NAME}.timing_hold.rpt {
      report_timing \
				-pba_mode path \
				-delay_type min \
                -nosplit \
                -capacitance \
                -transition_time \
                -significant_digits 10 \
                -input_pins -nets \
                -group $group_name
    }
  }
}

foreach_in_collection group [remove_from_collection [get_path_groups] $default_groups]  {
  set group_name [get_object_name $group]
  if { [sizeof_collection [get_timing_paths -group $group_name]] } {
    redirect -append -file ./reports/gba_${DESIGN_NAME}.timing_hold.rpt {
      report_timing \
				-delay_type min \
                -nosplit \
                -capacitance \
                -transition_time \
                -significant_digits 10 \
                -input_pins -nets \
                -group $group_name
    }
  }
}


remove_annotated_parasitics -all
read_parasitics -keep_capacitive_coupling -format SPEF ./inputs/${DESIGN_NAME}.spef.max.gz

lappend COMMENTED_OUT {

#############################
# Setting power analysis to averaged mode
set power_analysis_mode averaged

############################
# Power report
redirect -file ./reports/${DESIGN_NAME}.power.rpt {report_power }

############################
# Power report for multi-thresold voltages
redirect -file ./reports/${DESIGN_NAME}.power_vth.rpt {
	report_threshold_voltage_group
}
redirect -file ./reports/${DESIGN_NAME}.power_leakage_vth.rpt {
	report_power -threshold_voltage_group
}

############################
# Power report for clock-gating savings
redirect -file ./reports/${DESIGN_NAME}.power_clock_gating.rpt {report_clock_gate_savings}

############################
# Setting the operating conditions to OCV
set_operating_conditions -analysis_type on_chip_variation -max ss0p95v125c -min ff0p95vn40c

###############################
# Generating timing reports for setup analysis -OCV


foreach_in_collection group [remove_from_collection [get_path_groups] $default_groups] {
  set group_name [get_object_name $group]
  if { [sizeof_collection [get_timing_paths -group $group_name]] } {
    redirect -append -file ./reports/${DESIGN_NAME}.timing_ocv_setup.rpt {
      report_timing \
                -nosplit \
                -capacitance \
                -transition_time \
                -significant_digits 2 \
                -input_pins -nets  \
                -group $group_name
    }
  }
}

#lappend COMMENTED_OUT {}#
#################################
# Generating timing reports for hold analysis -OCV
remove_annotated_parasitics -all
read_parasitics -keep_capacitive_coupling -format SPEF ./inputs/${DESIGN_NAME}.spef.min.gz

foreach_in_collection group [remove_from_collection [get_path_groups] $default_groups] {
  set group_name [get_object_name $group]
  if { [sizeof_collection [get_timing_paths -group $group_name]] } {
    redirect -append -file ./reports/${DESIGN_NAME}.timing_ocv_hold.rpt {
      report_timing \
                -delay_type min \
                -nosplit \
                -capacitance \
                -transition_time \
                -significant_digits 2 \
                -input_pins -nets  \
                -group $group_name
    }
  }
}

remove_annotated_parasitics -all
read_parasitics -keep_capacitive_coupling -format SPEF ./inputs/${DESIGN_NAME}.spef.max.gz

#lappend COMMENTED_OUT {}#
##########################
# Setting the timing derating factors

set_timing_derate -cell_delay -early 0.9
set_timing_derate -cell_delay -late 1.05
set_timing_derate -net_delay -early 0.95
set_timing_derate -net_delay -early 1.1

###############################
# Generating timing reports for setup and hold analysis with timing derates

foreach_in_collection group [remove_from_collection [get_path_groups] $default_groups] {
  set group_name [get_object_name $group]
  if { [sizeof_collection [get_timing_paths -group $group_name]] } {
    redirect -append -file ./reports/${DESIGN_NAME}.timing_derated_setup.rpt {
      report_timing \
                -nosplit \
                -capacitance \
                -transition_time \
                -significant_digits 2 \
                -input_pins -nets  \
                -group $group_name
    }
  }
}

#lappend COMMENTED_OUT {}#
#################################
# Generating timing reports for hold analysis - with Derate
remove_annotated_parasitics -all
read_parasitics -keep_capacitive_coupling -format SPEF ./inputs/${DESIGN_NAME}.spef.min.gz

foreach_in_collection group [remove_from_collection [get_path_groups] $default_groups] {
  set group_name [get_object_name $group]
  if { [sizeof_collection [get_timing_paths -group $group_name]] } {
    redirect -append -file ./reports/${DESIGN_NAME}.timing_derated_hold.rpt {
      report_timing \
                -delay_type min \
                -nosplit \
                -capacitance \
                -transition_time \
                -significant_digits 2 \
                -input_pins -nets  \
                -group $group_name
    }
  }
}

remove_annotated_parasitics -all
read_parasitics -keep_capacitive_coupling -format SPEF ./inputs/${DESIGN_NAME}.spef.max.gz

#lappend COMMENTED_OUT {}#
############################
# Setting PT-SI app variable to enable SI analysis
set_app_var si_enable_analysis true
set timing_save_pin_arrival_and_slack true

############################
# Check crosstalk effects on the design (using max spef)
redirect -append -file ./reports/${DESIGN_NAME}.si_analysis.rpt {report_si_bottleneck}

#################################
# To check the crosstalk effect on the specific paths
# report_delay_calculation -crosstalk -from pin -to pin

#lappend COMMENTED_OUT {}#
###############################
# Set noise calculation related parameters and check noise
set_noise_parameters -include_beyond_rails -enable_propagation -analysis_type all
check_noise -beyond_rail
set_noise_lib_pin [get_pins -filter "direction==out"] [get_lib_pins *ss*/IBUFFX2_RVT/Y]
set_noise_lib_pin [get_pins -filter "direction==in"] [get_lib_pins *ss*/IBUFFX2_RVT/A]

redirect -append -file ./reports/${DESIGN_NAME}.check_noise.rpt {
      check_noise -beyond_rail
}

##############################
# Report noise (using max spef)
redirect -append -file ./reports/${DESIGN_NAME}.noise.rpt {
      report_noise
}

remove_annotated_parasitics -all
read_parasitics -keep_capacitive_coupling -format SPEF ./inputs/${DESIGN_NAME}.spef.min.gz

#lappend COMMENTED_OUT {}#
############################
# Check crosstalk effects on the design (using min spef)

redirect -append -file ./reports/${DESIGN_NAME}.si_analysis.rpt {report_si_bottleneck}

###############################
# check noise
check_noise -beyond_rail
set_noise_lib_pin [get_pins -filter "direction==out"] [get_lib_pins *ss*/INVX2_RVT/Y]
set_noise_lib_pin [get_pins -filter "direction==in"] [get_lib_pins *ss*/INVX2_RVT/A]

redirect -append -file ./reports/${DESIGN_NAME}.check_noise.rpt {
   check_noise -beyond_rail
}


##############################
# Report noise (using min spef)
redirect -append -file ./reports/${DESIGN_NAME}.noise.rpt {
      report_noise
}

###############################
# Saving the session
puts "Saving the session to./outputs "
save_session ./outputs/full_chip_${DESIGN_NAME}.session
sh zip -j -u ./reports/EE5327_Lab11_[getenv LOGNAME]_${DESIGN_NAME}.zip ./reports/*.timing*.rpt ./reports/*.power.rpt ./reports/*.power_leakage_vth.rpt ./reports/*.power_clock_gating.rpt ./reports/*.si_analysis.rpt ./reports/*.noise.rpt

set elapsed_time [expr { ([clock seconds] - $start_time) / 60.0} ]
puts [format "##### Done. Runtime: %.2f mins, Memory Used: %.1f GB #####" $elapsed_time [expr [mem] / 1000000.0]]
}

exit
