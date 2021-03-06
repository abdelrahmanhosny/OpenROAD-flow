if {![info exists standalone] || $standalone} {
  # Read process files
  foreach libFile $::env(LIB_FILES) {
    read_liberty $libFile
  }
  read_lef $::env(OBJECTS_DIR)/merged_padded.lef

  # Read design files
  read_def $::env(RESULTS_DIR)/2_floorplan.def
  read_sdc $::env(RESULTS_DIR)/2_floorplan.sdc
}

set_wire_rc -layer $::env(WIRE_RC_LAYER)

global_placement -timing_driven -density $::env(PLACE_DENSITY)

if {![info exists standalone] || $standalone} {
  write_def $::env(RESULTS_DIR)/3_1_place_gp.def
  exit
}
