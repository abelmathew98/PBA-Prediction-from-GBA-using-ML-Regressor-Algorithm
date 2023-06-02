create_pg_ring_pattern R2  -vertical_layer M9 -horizontal_layer M8 -horizontal_width 2.5 -vertical_width 5 -side_spacing { {side: 1 2 3 4} {spacing: 2 } }
 
lappend pg_mesh_strategies ring2

set_pg_strategy ring2 -core -pattern  "{name: R2} {nets: {VDD VSS}} {offset:{15 15}}" -extension "{nets: {VDD VSS}} {side: 1 2 3 4} {stop: pad_rings}"

 

set PG_grid {
{M1	horizontal	0.576   0.064	0.0 }
{M2	horizontal	1.576   0.076	0.0 }
{M3	vertical	1.576   0.076	0.0 }
{M4	horizontal	1.576   0.076	0.0 }
{M5	vertical	1.72    0.144	0.0 }
{M6	horizontal	2.152   0.254	0.0 }
{M7	vertical	4.152   0.354	0.0 }
{M8	horizontal	6.304   0.484	0.0 }
{M9	vertical	8.88    0.396	0.0 }
{MRDL	horizontal	15.824  4.05	0.0 }
}

set supply_nets {
{VDD power}
{VSS ground}
}

connect_pg_net -automatic 
remove_routes -net_types power -lib_cell_pin_connect
remove_routes -net_types ground -lib_cell_pin_connect
remove_routes -net_types power -stripe
remove_routes -net_types ground -stripe

foreach mesh_patter $PG_grid {
	puts $mesh_patter
	set layer [lindex $mesh_patter 0]
	set direction [lindex $mesh_patter 1]
	set pitch [lindex $mesh_patter 2]
	set width [lindex $mesh_patter 3]
	set offset [lindex $mesh_patter 4]
	if {![regexp "M1$\|M2$\|M8$\|M9$" $layer]} {
		lappend pg_mesh_strategies pg_mesh_${layer}_strategy
		create_pg_mesh_pattern pg_mesh_$layer \
		-layers "{{${direction}_layer: $layer} {width: $width} {spacing: interleaving} {pitch: [expr $pitch*2]} {offset: $offset}}"	
		set_pg_strategy pg_mesh_${layer}_strategy -core -pattern "{pattern: pg_mesh_${layer}} {nets:{VDD VSS}} "   -blockage {{nets:VDD VSS}{layers: M1 M2 M3 M4} {macros_with_keepout:all}}
	} elseif {[regexp "M1$\|M2$" $layer]} {
		lappend pg_mesh_strategies pg_mesh_${layer}_strategy
		create_pg_std_cell_conn_pattern ${layer}_std_cell_rails -layers $layer -rail_width $width -check_std_cell_drc false
		set_pg_strategy pg_mesh_${layer}_strategy -core -pattern "{name: ${layer}_std_cell_rails}{nets: {VDD VSS}}" -blockage {{nets: VDD VSS}{macros_with_keepout: all}}
	} elseif  {[regexp "M8$\|M9$" $layer]} {  
		lappend pg_mesh_strategies pg_mesh_${layer}_strategy
	        create_pg_mesh_pattern pg_mesh_$layer -layers "{{${direction}_layer: $layer} {width: $width} {spacing: interleaving} {pitch: [expr $pitch*2]} {offset: $offset}}"
                set_pg_strategy pg_mesh_${layer}_strategy -core -pattern "{pattern: pg_mesh_${layer}} {nets:{VDD VSS} } "  -extension {{stop: outermost_ring} }
	} else {} 
}

compile_pg -strategies $pg_mesh_strategies  -ignore_drc
