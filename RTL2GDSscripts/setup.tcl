# Set environment variable DESIGN_NAME
#
set DESIGN_NAME=fifo
set DESIGN_HOME=/home/class/vinod011/da2/project/fifo
set DC_DIR=${DESIGN_HOME}/pnr/dc
set DP_DIR=${DESIGN_HOME}/pnr/dp
set DCTOPO_DIR=${DESIGN_HOME}/pnr/dc_topo

# Create directories
file mkdir ${DESIGN_HOME}/pnr/dc
file mkdir ${DESIGN_HOME}/pnr/dp
file mkdir ${DESIGN_HOME}/pnr/dc_topo

#synthesis
file mkdir ${DESIGN_HOME}/pnr/dc/inputs
file mkdir ${DESIGN_HOME}/pnr/dc/scripts
file copy /home/class/vinod011/da2/project/fifo/pnr/dc/scripts/* ./pnr/dc/scripts/
file mkdir ${DESIGN_HOME}/pnr/dc/inputs/rtl
file mkdir ${DESIGN_HOME}/pnr/dc/inputs/constraints
file mkdir ${DESIGN_HOME}/pnr/dc/inputs/switching_activity
file copy /home/class/vinod011/da2/project/fifo/pnr/dc/inputs/constraints/fifo.constraints.tcl ${DESIGN_HOME}/pnr/dc/inputs/constraints/${DESIGN_NAME}.constraints.tcl
file copy /home/class/vinod011/da2/project/fifo/pnr/dc/inputs/switching_activity/fifo.switching_activity.tcl ${DESIGN_HOME}/pnr/dc/inputs/switching_activity/${DESIGN_NAME}.switching_activity.tcl
file copy /home/class/vinod011/da2/project/fifo/dc/.synopsys_dc.setup ${DC_DIR}/.synopsys_dc.setup

file copy /home/class/vinod011/da2/project/crossbar128x128/pnr/dc/inputs/rtl/crossbar.sv ${DC_DIR}/inputs/rtl/

#cd $DC_DIR
#exec dc_shell -64 -f $DC_DIR/scripts/dc_flow.tcl
#
#cd ${DESIGN_HOME}/pnr/
#
##after synthesis
#file link -symbolic ${DESIGN_HOME}/pnr/dc/outputs/${DESIGN_NAME}.vg ${DESIGN_HOME}/pnr/dp/inputs/${DESIGN_NAME}_syn.vg
#file link -symbolic ${DESIGN_HOME}/pnr/dc/outputs/${DESIGN_NAME}.sdc ${DESIGN_HOME}/pnr/dp/inputs/${DESIGN_NAME}_syn.sdc
#file link -symbolic ${DESIGN_HOME}/pnr/dc/outputs/${DESIGN_NAME}.scan.def ${DESIGN_HOME}/pnr/dp/inputs/${DESIGN_NAME}_syn.scan.def


