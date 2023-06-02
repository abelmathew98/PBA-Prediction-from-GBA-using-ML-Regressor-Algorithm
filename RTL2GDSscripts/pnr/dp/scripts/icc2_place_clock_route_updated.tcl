
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
}

redirect -file /dev/null {set start_time [clock seconds]}

################################
set GDS_OUT_LAYER_MAP           /home/vlsilab/synopsys/SAED32_EDK/tech/milkyway/saed32nm_1p9m_gdsout_mw.map
set MW_TECH_FILE                /home/vlsilab/synopsys/SAED32_EDK/tech/milkyway/saed32nm_1p9m_mw.tf
set MAX_TLUPLUS_FILE            /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus
set MIN_TLUPLUS_FILE            /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus
set TLUPLUS_MAP_FILE            /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map
set MW_POWER_NET                "VDD"
set MW_GROUND_NET               "VSS"

set no_row_gap 1
set_app_var timing_remove_clock_reconvergence_pessimism true
set_host_options -max_cores 16
#### compressing data db/lib tosave space ####
set_app_options  -name  lib.setting.compress_design_lib -value true
################################
set elapsed_time [expr { ([clock seconds] - $start_time) / 60.0 }]
puts [format "##### Analyzing the Design. Runtime: %.2f mins #####" $elapsed_time]

##### Opening the lib and reading and linking the design ######
set ref_lib [eval [list exec echo] [glob ndms/*.ndm]]
### creating the design lib ##### 
create_lib $DESIGN_NAME -technology $MW_TECH_FILE -ref_libs $ref_lib 

open_lib ${DESIGN_NAME}
read_verilog -top full_chip_$DESIGN_NAME ./inputs/${DESIGN_NAME}_syn.vg
current_block full_chip_${DESIGN_NAME}
link_block

### Defining the operating conditions ######
set_operating_conditions  -max ss0p95v125c -min ff0p95vn40c -max_library saed32hvt_c -min_library saed32lvt_c

#### Reading parasitic files #########
read_parasitic_tech -tlup /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus  -layermap /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map

read_parasitic_tech -tlup /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus  -layermap /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map

set_parasitic_parameters -early_spec /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus   -late_spec /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus

###### reading the sdc file #######
read_sdc ./inputs/${DESIGN_NAME}_syn.sdc

##### Some sanity checks and reporting ########
check_timing
report_clock -skew
report_clock
report_exceptions
report_disable_timing


#### Defining the the path groups ########
group_path -name inputs -from [all_inputs]
group_path -name output -to [all_outputs]
group_path -name comb -from [all_inputs] -to [all_outputs]
group_path -name reg2reg -from [all_registers -clock_pins] -to [all_registers -data_pins]


connect_pg_net -automatic
check_mv_design -pg_pin 

set_auto_disable_drc_nets -constant false -scan false -on_clock_network false


###############################
# Setting a false path on the SE, CGC bypass-pin (control point after latch)
# since it's a data-pin on the clock network and
# would typically be subjected false timing violations

set_false_path -to [filter_collection [get_pins -of_objects \
                   [filter_collection [get_cells -hierarchical ] \
                                       "ref_name =~ CGLPPS*"]] "name =~ SE"]
##### Check the below report for any exceptions #####
report_exceptions 

#### Defining the clock tree as ideal ###### 
set_ideal_network [all_fanout -flat -clock_tree]

#### Reading our def file from previous floorplan 
read_def outputs/${DESIGN_NAME}.PostFloorplan_full.DEF
### Direction of the layers ##### 
set VERTICAL_ROUTING_LAYER_LIST "M1 M3 M5 M7 M9"
set_attribute -object [get_layers $VERTICAL_ROUTING_LAYER_LIST] -name routing_direction -value vertical -quiet

set HORIZONTAL_ROUTING_LAYER_LIST "M2 M4 M6 M8 MRDL"
set_attribute -object [get_layers $HORIZONTAL_ROUTING_LAYER_LIST] -name routing_direction -value horizontal -quiet

set_ignored_layers  -min_routing_layer M2
#### Inserting the IO pads ###### 
#source scripts/IO_pads.tcl 
source scripts/IO_new.tcl

#### Reading the scan def ####### 
read_def inputs/${DESIGN_NAME}_syn.scan.def

connect_pg_net -automatic
check_mv_design

### checking the physcial constraint before moving to plaement #####
check_physical_constraints


#### scan chain reordering app options ##### 
 
set_app_options -name opt.dft.optimize_scan_chain -value true
set_app_options -name opt.dft.clock_aware_scan_repartition_reorder -value true
set_app_options -name opt.dft.clock_aware_scan_reorder -value true


##### setting input transition and load ######
remove_driving_cell [remove_from_collection [all_inputs] [all_outputs]]
set_input_transition 0.2 [remove_from_collection [all_inputs] [all_outputs]]
set_load 2500 [all_outputs]

#### Setting lvt voltage group and percentage of it #####
set_attribute [get_lib_cells *lvt*/*] threshold_voltage_group LVT
set_threshold_voltage_group_type -type low_vt LVT
set_multi_vth_constraint -low_vt_percentage 10 -cost area

##### Remove ignored layers #### 
remove_ignored_layers -all
set_ignored_layers -min_routing_layer M2 -max_routing_layer MRDL

#### App options for the place #######
set_app_options -name opt.common.user_instance_name_prefix -value "place"
set_app_options -name place_opt.flow.do_spg -value true

#### Clock net routing rules #######
create_routing_rule clock_routing_rule -spacings {M5 0.112  M4 0.112  M3 0.112} -widths {M3 0.112 M4 0.112 M5 0.112} 

check_mv_design

### optimizing the logical drc #####
 place_opt -from initial_drc -to initial_opto
#### Further incremental timing and legalization of the cells #### 
  place_opt -from final_place
### saving block after design ###### 
# save_block -as placement_done

report_congestion > ./reports/${DESIGN_NAME}.congestion.rpt 
report_timing   > ./reports/${DESIGN_NAME}.timing_setup.rpt
#### setting clock attributes and routing rules #######
set_clock_tree_options -target_skew 0.2  -clock [all_clocks]
set_clock_routing_rules -min_routing_layer M2  -max_routing_layer M7  -rules clock_routing_rule  -clocks [all_clocks ] -rules clock_routing_rule
set_max_capacitance 75   -clock_path [all_clocks ] 
set_max_transition 0.125 -clock_path [all_clocks ] 

##### Clock opt preparation ###### 
set CTS_CELLS_DEFAULT "INVX* IBUFFX* NBUFFX* INVX* IBUFFX* NBUFFX* AND* NAND* OR* NOR* CGLPPSX* CGLNPRX* IBUFFX* NBUFFX* DELLN*"
set_clock_tree_reference_subset -clocks [all_clocks ] -lib_cells [get_lib_cells $CTS_CELLS_DEFAULT]  
remove_clock_uncertainty [all_clocks]
remove_ideal_network [all_fanout -flat -clock_tree]
remove_ideal_network -all
set_app_options -name opt.common.user_instance_name_prefix -value "clock_opt"
set_app_options -name clock_opt.congestion.effort -value high 

clock_opt -from build_clock -to build_clock

update_clock_latency
optimize_dft -clock_aware

set DELAY_CELL_LIST "NBUFFX* DELLN*"
set_lib_cell_purpose -include hold [get_lib_cells "*/[join $DELAY_CELL_LIST { */}]"]
set_app_options -name clock_opt.flow.enable_global_route_opt -value false

clock_opt -from route_clock -to final_opto

mark_clock_tree -fix_sinks
set all_clock_nets  [get_nets -of [get_clock_tree_pins ]]
set_attribute -name physical_status -value locked -objects $all_clock_nets
########################################################
connect_pg_net -automatic 
update_clock_latency


#### clock timing reporting #######
report_timing -transition_time -capacitance
report_timing -delay_type min -transition_time -capacitance

#### post cts saving  block######## 
#save_block  -as ${DESIGN_NAME}_post_cts


if {[file exists [glob -nocomplain cpd_pre_route_opt*]]} \
                        { sh rm -rf [glob -nocomplain cpd_pre_route_opt*] }

####### routing related app option setting ######## 
set_app_option -name route.common.net_max_layer_mode -value  hard
set_app_option -name route.common.net_min_layer_mode_soft_cost -value low
set_app_option -name route.common.global_max_layer_mode -value hard
set_app_option -name route.common.global_min_layer_mode -value allow_pin_connection
set_app_options -name route.common.tie_off_mode -value all
set_app_options -name route.common.post_detail_route_redundant_via_insertion -value medium 
set_app_options -name route.common.rc_driven_setup_effort_level -value  medium
set_app_options -name route.global.timing_driven -value  false
set_app_options -name route.track.timing_driven -value false
set_app_options -name route.detail.antenna -value false
set_app_options  -name route.detail.timing_driven -value true
set_app_options -name  route.detail.optimize_wire_via_effort_level -value medium 
################################
###### Tie cell insertion #################
set_lib_cell_purpose -include optimization  [get_lib_cell saed32*/TIE* ]
set_attribute   [get_lib_cell saed32*/TIE* ] -name dont_touch -value false
set eco_pins [get_flat_pins -filter "net_name == $MW_POWER_NET"]
set TIE_HIGH_CELL "TIEH_HVT"
set TIE_LOW_CELL "TIEL_HVT"
add_tie_cells -objects [get_pins $eco_pins] -tie_high_lib_cells [get_lib_cell $TIE_HIGH_CELL] -tie_low_lib_cells [get_lib_cell  $TIE_LOW_CELL]
##########################
### routing first iteration ########
route_auto -reuse_existing_global_route true -route_nondefault_nets_first true -max_detail_route_iterations 10
connect_pg_net -automatic


###### Antenna fixing app options #####
set ANTENNA_DIODE "ANTENNA_HVT" 
set_app_options -name route.detail.diode_libcell_names -value "$ANTENNA_DIODE"
set_app_options -name route.detail.antenna -value true
set_app_options -name route.detail.default_gate_size -value 0
set_app_options -name route.detail.hop_layers_to_fix_antenna -value true
set_app_options -name route.detail.insert_diodes_during_routing -value true
source /home/vlsilab/synopsys/SAED32_EDK/tech/milkyway/saed32nm_ant_1p9m.tcl
############ 

#### dont touch on the Tie cells #####
if { [sizeof_collection [get_cells -hier -filter "ref_name == $TIE_HIGH_CELL"]] } {
  set_dont_touch [get_cells -hier -filter "ref_name == $TIE_HIGH_CELL"]
  set_dont_touch [get_nets -of_objects [get_pins -of_objects [get_cells -hier -filter "ref_name == $TIE_HIGH_CELL"]]]
}
### legalizing and incremental routing of tie cells #### 
legalize_placement -incremental
route_eco -open_net_driven true -reroute modified_nets_first_then_others
route_detail -incremental true 
#### spreading wires for physcial drc fixing #### 
spread_wires -timing_preserve_setup_slack_threshold 0.05 -timing_preserve_hold_slack_threshold 0.05 -pitch 0.5  -min_jog_length 2
widen_wires -timing_preserve_setup_slack_threshold 0.05  -timing_preserve_hold_slack_threshold 0.05

###### DECAP and FILLER cells insertions ###########
create_stdcell_fillers -lib_cells [get_lib_cell DCAP_HVT]
connect_pg_net -automatic
remove_stdcell_fillers_with_violation
create_stdcell_fillers -lib_cells [get_lib_cell "SHFILL128_HVT SHFILL64_HVT SHFILL3_HVT SHFILL2_HVT SHFILL1_HVT"]
connect_pg_net -automatic
########## legality check should pass after filler insertion ##########
check_legality

route_detail -incremental true -max_number_iteration 10

#### metal fill ######### Add ICV tool path to your $path variable #####  
set_app_options -name signoff.create_metal_fill.runset -value "/home/vlsilab/synopsys/SAED32_EDK/tech/icv_drc/saed32nm_1p9m_mfill_rules.rs"
set_app_options  -name signoff.create_metal_fill.space_to_nets    -value {{M2 2x} {M3 2x} {M4 2x} {M5 2x}  {M6 2x}  {M7 2x}   {M8 2x}  {M9 2x}  {M10 2x}}
signoff_create_metal_fill  -select_layers {M1 M2 M3 M4 M5 M6 M7 M8 M9}

##### rout_opt one more routing optimization pass can be done if drc/timing is still an issue ####
#route_opt

#### reporting ##################
report_qor  >  ./reports/${DESIGN_NAME}.qor.rpt
report_clock -skew -attributes -nosplit    >  ./reports/${DESIGN_NAME}.clock.rpt
report_clock -skew -attributes -nosplit  >  ./reports/${DESIGN_NAME}.clock.rpt
report_power >  ./reports/${DESIGN_NAME}.power.rpt
report_timing -transition_time -capacitance  -input_pins -nets -delay_type max  > ./reports/${DESIGN_NAME}.timing_setup.rpt
report_timing -transition_time -capacitance  -input_pins -nets -delay_type min     > ./reports/${DESIGN_NAME}.timing_hold.rpt

####### output files generations #######
write_sdc -nosplit -output outputs/${DESIGN_NAME}.sdc
write_verilog -exclude {scalar_wire_declarations leaf_module_declarations pg_objects end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells cover_cells} -hierarchy all outputs/${DESIGN_NAME}.v
write_parasitics -hierarchical -compress -format spef -output outputs/${DESIGN_NAME}.spef
write_sdf outputs/${DESIGN_NAME}.sdf
#write_gds -layer_map $GDS_OUT_LAYER_MAP -child_depth 1000 -fill include -output_pin geometry  -instance_property 112  -verbose_report_cell_source verbose_report_file_name -long_names -lib_cell_view frame outputs/${DESIGN_NAME}.gds
write_saif  outputs/${DESIGN_NAME}.saif
#########################################
save_block -as final_routed_design

set elapsed_time [expr { ([clock seconds] - $start_time) / 60.0} ]
puts [format "##### Done. Runtime: %.2f mins, Memory Used: %.1f GB #####" $elapsed_time [expr [mem] / 1000000.0]]
exit
