# Turn Makefile target and variable assignments into shell variable
# assignments:
# * For targets, define the variable `target_NAME' to "explicit".
# * For variables whose names are uppercase, perform the actual assignment.
#   We only do this for all-upper variables to avoid conflict with variables
#   used in automake.
# * For other variables, define `var_NAME' to "explicit".  Such variables
#   can only be used as flags; any use of their values must be done
#   later, in the generated Makefile.
s/(/{/g
s/)/}/g
/^ *\([a-zA-Z_.][a-zA-Z0-9_.]*\):.*/{
s//target_\1=explicit/
s/\./_/g
p
}
s/^ *\([A-Z][A-Z0-9_]*\)[	 ]*=[	 ]*\(.*\)/\1='\2'/p
s/^ *\([A-Za-z][A-Za-z0-9_]*\)[ 	]*=[ 	]*\(.*\)/var_\1=explicit/p
