##########################################################################
# This script defines statistical disclosure control functions.
# fn_roundmid_any() rounds counts for to the nearest multiple of a
# threshold (default 6), centred on the midpoint of each rounding interval
#
# Used throughout the pipeline wherever patient counts are written to
# output files.
##########################################################################

fn_roundmid_any <- function(x, to = 6) {
  # like round_any, but centers on (integer) midpoint of the rounding points
  ceiling(x / to) * to - (floor(to / 2) * (x != 0))
}
