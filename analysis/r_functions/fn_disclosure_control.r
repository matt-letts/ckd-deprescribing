##########################################################################
# This script defines statistical disclosure control functions.
# https://docs.opensafely.org/outputs/sdc/ for information
#
# Rules are:
# - in general to suppress any counts of 7 or fewer
# - and to suppress rates calculates from counts <=7
#
# fn_apply_sdc() applies these rules
#
# If future calculations rely on small non-zero rates not being suppressed
# then fn_roundmid_any() rounds counts for to the nearest multiple of a
# threshold (default 6) as per the OpenSAFELY SDC guidelines.
#
# For any outputs using midpoint rounding need to:
# - add _midpoint6 to column name
# - add _midpoint6_derived to values derived from midpoint 6 values
##########################################################################

fn_apply_sdc <- function(x, threshold = 7) {
  replace(x, x > 0 & x <= threshold, NA)
}

fn_roundmid_any <- function(x, to = 6) {
  # like round_any, but centers on (integer) midpoint of the rounding points
  ceiling(x / to) * to - (floor(to / 2) * (x != 0))
}
