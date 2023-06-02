#################################################################################
# Script: create_top_level_scandef.tcl
# Description: Convert and merge block level scandef(s) to toplevel.
# Usage: create_top_level_scandef -output <output scandef name> <input scandef(s)>
#
# Author: Tord Jakobsson 
# Copyright (C) 2011 Synopsys All rights reserved.
#################################################################################

proc create_top_level_scandef {args} {
  global product_version
  global synopsys_program_name
  
  parse_proc_arguments -args $args Opt

  set outfile $Opt(-output)
  set scandef(scanchains) 0
  
  # Check for input files
  foreach infile $Opt(scandefs) {
    if {[file exists $infile]} {
      lappend infiles $infile
    } else {
      # Check for files with wildecards in name
      foreach X [ls $infile] {
        lappend infiles $X
      }
    }
  }
  
  # Convert scandef(s)
  foreach infile [lsort -unique $infiles] {

    # Open input file
    set SDEF_IN [open $infile "r"]
    
    # Reset header/footer
    if {[info exists scandef(head)]} {
      unset scandef(head)
    }
    if {[info exists scandef(foot)]} {
      unset scandef(foot)
    }
    
    # Start creating header.
    set part "head"
    
    while { ![eof $SDEF_IN] } {
      gets $SDEF_IN line
      if {[regexp -lineanchor {^(DESIGN +)(\S+)(\s.)} $line {} {} design]} {
        # Check for hierarchical instance path
        if {[current_design_name]=="$design"} {
          set hier_path ""
        } else {
          set hier_path "[get_attribute [get_cells -hier -filter "@ref_name==$design || @original_design_name==$design"] full_name]/"
        }
        # Set toplevel design name
        lappend scandef($part) "DESIGN [current_design_name] ;"
      } elseif {[regexp -lineanchor {^SCANCHAINS (\d+)} $line {} nbr]} {
        # Increase nbr of scan cahins
        set scandef(scanchains) [expr $scandef(scanchains) + $nbr]
        # End of header
        set part "body"
      } elseif {[regexp -lineanchor {^(-\s+)(\S+)} $line {} pref name]} {
        # Prefix chain names with original design name.
        lappend scandef($part) "${pref}${design}_${name}"
      } elseif {[regexp -lineanchor {^\+\s+START\sPIN\s+(\S+.*)$} $line {} port]} {
        # Get original port/pin name
        set port [regsub {\s} $port {/}]
        # Find connected pins
        set pins [all_connected [all_connected [get_pins "${hier_path}$port"]] -leaf]
        # Get startpoint pin/port
        set pin [filter_collection $pins {@pin_direction==out || @port_direction==in}]
        set start [get_attribute $pin full_name]
        # Check if startpoint is port or internal pin.
        if {[get_attribute $start object_class]=="port"} {
          lappend scandef($part) "+ START PIN ${start}"
        } else {
          lappend scandef($part) "+ START [regsub {(.*)/(.*)} ${start} {\1 \2}]"
        }
      } elseif {[regexp -lineanchor {^\+\s+START\s+(\S+.*)$} $line {} port]} {
        # Get original port/pin name
        set port [regsub {\s} $port {/}]
        # Find connected pins
        set pins [all_connected [all_connected [get_pins "${hier_path}$port"]] -leaf]
        # Get startpoint pin/port
        set pin [filter_collection $pins {@pin_direction==out || @port_direction==in}]
        set start [get_attribute $pin full_name]
        # Check if startpoint is port or internal pin.
        if {[get_attribute $start object_class]=="port"} {
          lappend scandef($part) "+ START PIN ${start}"
        } else {
          lappend scandef($part) "+ START [regsub {(.*)/(.*)} ${start} {\1 \2}]"
        }
      } elseif {[regexp -lineanchor {^(\+\s+\S+\s+)(\S+.*)$} $line {} pref cell]} {
        ;# Prefix hier path
        lappend scandef($part) "${pref}${hier_path}${cell}"
      } elseif {[regexp -lineanchor {^(\s+)(\S+.*)$} $line {} pref cell]} {
        ;# Prefix hier path
        lappend scandef($part) "${pref}${hier_path}${cell}"
      } elseif {[regexp -lineanchor {^(END .*)$} $line]} {
        # Start of footer
        set part "foot"
        lappend scandef($part) $line
      } else {
        lappend scandef($part) $line
      }
    }
    close $SDEF_IN
  }
    
  # Write out new scandef
  set SDEF_OUT [open $outfile "w"]
  foreach sdef $scandef(head) {
    puts $SDEF_OUT "$sdef"
  }
  puts $SDEF_OUT "SCANCHAINS $scandef(scanchains) ;"
  foreach sdef $scandef(body) {
    puts $SDEF_OUT "$sdef"
  }
  foreach sdef $scandef(foot) {
    puts $SDEF_OUT "$sdef"
  }
  close $SDEF_OUT
  
  # Check new scandef (only in DC 2010.03 and later)
  if {$product_version>="D-2010.03" && $synopsys_program_name=="dc_shell"} {
    redirect -v xyz {check_scan_def -file $outfile}
    echo "[regsub -all {.*\*\n(.*)Chain.*} $xyz {\1}]"
  }

}; # end proc

define_proc_attributes create_top_level_scandef -info "Convert and merge block level scandef(s) to toplevel." \
-define_args {
  {-output " output file name " "file_name" string}
  {scandefs " input scandef(s) " "scandef(s)" string}

  {-help " help " "" boolean optional}
}

