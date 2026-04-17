##########################################################################
# This script does the following:
# 1. Defines fn_roundmid_any() which rounds counts for statistical
#    disclosure control
# 2. Rounds values to the nearest multiple of a threshold (default 6),
#    centred on the midpoint of each rounding interval
#
# Used throughout the pipeline wherever patient counts are written to
# output files.
##########################################################################

fn_roundmid_any <- function(x, to = 6) {
  # like round_any, but centers on (integer) midpoint of the rounding points
  ceiling(x / to) * to - (floor(to / 2) * (x != 0))
}
