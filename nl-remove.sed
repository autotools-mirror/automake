# Remove \newline.
/\\$/{
  s///
  H
  d
}
/[^\\]$/{
  H
  x
  s/\n//g
  p
  s/.*//
  h
}
