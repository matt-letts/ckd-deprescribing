fn_roundmid_any <- function(x, to = 6) {
  # like round_any, but centers on (integer) midpoint of the rounding points
  ceiling(x / to) * to - (floor(to / 2) * (x != 0))
}
