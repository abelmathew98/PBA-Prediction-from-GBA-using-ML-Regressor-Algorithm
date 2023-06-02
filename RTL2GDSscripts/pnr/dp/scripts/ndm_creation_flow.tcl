############################################################
### Set search_path
set_app_var search_path [concat $search_path /home/vlsilab/synopsys/SAED32_EDK/lib/stdcell_rvt/db_nldm/]
set_app_var search_path [concat $search_path /home/vlsilab/synopsys/SAED32_EDK/lib/stdcell_hvt/db_nldm/]
set_app_var search_path [concat $search_path /home/vlsilab/synopsys/SAED32_EDK/lib/stdcell_lvt/db_nldm/]
set_app_var search_path [concat $search_path /home/vlsilab/synopsys/SAED32_EDK/lib/io_std/db_nldm/]
#########
#########
## Set Target Library & Min Versions for each target library
set target_library "saed32rvt_ss0p95v125c.db saed32hvt_ss0p95v125c.db saed32lvt_ss0p95v125c.db saed32io_wb_ss0p95v125c_2p25v.db saed32rvt_ff0p95vn40c.db saed32hvt_ff0p95vn40c.db saed32lvt_ff0p95vn40c.db saed32io_wb_ss0p95vn40c_2p25v.db"
set_app_var link_library "$target_library"
##### Set lef #######
set lef_library { /home/vlsilab/synopsys/SAED32_EDK/lib/stdcell_rvt/lef/saed32nm_rvt_1p9m.lef  /home/vlsilab/synopsys/SAED32_EDK/lib/stdcell_lvt/lef/saed32nm_lvt_1p9m.lef /home/vlsilab/synopsys/SAED32_EDK/lib/stdcell_hvt/lef/saed32nm_hvt_1p9m.lef /home/vlsilab/synopsys/SAED32_EDK/lib/io_std/lef/saed32_io_wb_all.lef /home/vlsilab/synopsys/SAED32_EDK/lib/io_std/lef/saed32_io_fc_all.lef }

# Prepare work/log directories
file mkdir "./work"

echo "\n\nLibrary Settings:"
echo "========================================"
echo "search_path:     \"$search_path\""
echo "link_library:    \"$link_library\""
echo "target_library:  \"$target_library\""
echo "========================================\n\n"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# # General setup
# # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

file delete -force "./logs"
file mkdir "./logs"
file mkdir "./ndms"

# Create log files with datestamp
set timestamp [clock format [clock scan now] -format "%Y-%m-%d_%H-%M"]
set sh_output_log_file "./logs/${synopsys_program_name}.log.$timestamp"

set GDS_OUT_LAYER_MAP           /home/vlsilab/synopsys/SAED32_EDK/tech/milkyway/saed32nm_1p9m_gdsout_mw.map
set MW_TECH_FILE                /home/vlsilab/synopsys/SAED32_EDK/tech/milkyway/saed32nm_1p9m_mw.tf
set MAX_TLUPLUS_FILE            /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus
set MIN_TLUPLUS_FILE            /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus
set TLUPLUS_MAP_FILE            /home/vlsilab/synopsys/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map
set MW_POWER_NET                "VDD"
set MW_GROUND_NET               "VSS"


## some to guide the tool ###
set auto_restore_mw_cel_lib_setup true
set mw_logic1_net $MW_POWER_NET
set mw_logic0_net $MW_GROUND_NET
set legalize_auto_x_keepout_margin 0
set legalize_auto_y_keepout_margin 0
set no_row_gap 1
set_host_options -max_cores 4
set_app_options -name  lib.workspace.save_design_views  -value true
set_app_options -name  lib.workspace.save_layout_views  -value true
set DESIGN_NAME [getenv "DESIGN_NAME"]

## Removing the previous LIB ### 
if {[file exists ${DESIGN_NAME}]} { sh rm -rf ${DESIGN_NAME} }

### Creating the workspace #### 
create_workspace ${DESIGN_NAME} -flow exploration  -technology $MW_TECH_FILE
read_ndm /home/vlsilab/synopsys/icc2_R-2020.09/libraries/syn/gtech.nlib
read_ndm /home/vlsilab/synopsys/icc2_R-2020.09/libraries/syn/dw_foundation.nlib
read_ndm /home/vlsilab/synopsys/icc2_R-2020.09/libraries/syn/standard.nlib
read_lef $lef_library
read_db $link_library
read_parasitic_tech -tlup $MAX_TLUPLUS_FILE -name tlu_max
read_parasitic_tech -tlup $MIN_TLUPLUS_FILE  -name tlu_min
read_parasitic_tech -tlup $MAX_TLUPLUS_FILE   -layermap $TLUPLUS_MAP_FILE
read_parasitic_tech -tlup $MIN_TLUPLUS_FILE  -layermap $TLUPLUS_MAP_FILE

group_libs
## checking workspace ## 
check_workspace
## commiting the workspace ## 
commit_workspace -output  ${DESIGN_NAME} -directory ndms/
exit
