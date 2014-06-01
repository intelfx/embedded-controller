#!/bin/bash

# Load util module.
# ---
source "$(dirname "${BASH_SOURCE[0]}")/util.sh" || exit 1
# ---

# Check input data.
# ---
DEFINITIONS="$1"
FIELD="$2"
WRITE_VALUE="$3"

if [[ -z "$FIELD" || -z "$DEFINITIONS" ]]; then
	cat >&2 <<EOF
Some data not given. Usage:

	$0 DEFINITIONS FIELD [VALUE]

DEFINITIONS should be path to a file generated from your decompiled DSDT
using 'ec_parse_definitions.sh' script.

FIELD should be the EC RAM field name to read/write.

VALUE should be the value to write, if writing is desired.
If it is not specified, the field is read and printed to standard output.

Exiting.
EOF

	exit 1
fi
# ---

# Load definitions.
# ---
source "$DEFINITIONS" || exit 1
# ---

# Check 'ec_access'.
# ---
EC_ACCESS="$(dirname "${BASH_SOURCE[0]}")/ec_access"

if ! [[ -f "$EC_ACCESS" && -x "$EC_ACCESS" ]]; then
	cat >&2 <<EOF
Can't locate 'ec_access' at '$EC_ACCESS', or the file is not executable.

Compile it by issuing 'gcc ec_access.c -o ec_access' in the source directory.

Exiting.
EOF

	exit 1
fi
# ---

# Ancillary function definitions.
# ---
function ec_read() {
	"$EC_ACCESS" -b "$(hex "$1")"

	if (( $? )); then
		echo "Failed to read byte $1 through 'ec_access'. Exiting." >&2
		exit 1
	fi
}

function ec_write() {
	"$EC_ACCESS" -w "$(hex "$1")" -v "$(hex "$2")"

	if (( $? )); then
		echo "Failed to write $2 to byte $1 through 'ec_access'. Exiting." >&2
		exit 1
	fi
}
# ---

# Load field definition.
# ---
IFS="," read FIELD_OFFSET FIELD_LENGTH <<< "${EC_FIELDS["$FIELD"]}"

if [[ -z "$FIELD_OFFSET" || -z "$FIELD_LENGTH" ]]; then
	echo "Invalid field name: '$FIELD'. Exiting." >&2
	exit 1
fi
# ---

# Sanity-check the field.
# ---
if (( LENGTH > 8 )); then
	echo "Reading multi-byte fields not implemented. Exiting." >&2
	exit 1
fi
# ---

# Calculate field offset and bitmask.
# ---
FIELD_OFFSET_BYTE="$(( FIELD_OFFSET / 8 ))"
FIELD_OFFSET_BIT="$(( FIELD_OFFSET % 8 ))"
FIELD_MASK="$(( ((2 ** FIELD_LENGTH) - 1) << FIELD_OFFSET_BIT ))"
NOT_FIELD_MASK="$(( 0xFF - FIELD_MASK ))"
# ---

# Output debugging information.
# ---
dbg "Field:       '$FIELD' (offset $FIELD_OFFSET)"
dbg "Byte offset: '$FIELD_OFFSET_BYTE'"
dbg "Bit offset:  '$FIELD_OFFSET_BIT'"
dbg "Length:      '$FIELD_LENGTH'"
dbg "Mask:        '$FIELD_MASK' (reverse: '$NOT_FIELD_MASK')"
# ---

function read_field() {
	# Read the field.
	# ---
	dbg "- reading byte $FIELD_OFFSET_BYTE"

	BYTE_VALUE="$(ec_read "$FIELD_OFFSET_BYTE")"
	dbg "Byte value:  '$BYTE_VALUE'"
	# ---
}

function write_field() {
	# Write the field.
	# ---
	dbg "- writing byte $FIELD_OFFSET_BYTE, value $BYTE_VALUE"
	ec_write "$FIELD_OFFSET_BYTE" "$BYTE_VALUE"
	# ---
}

set -e

if [[ "$WRITE_VALUE" ]]; then
	read_field
	
	BYTE_VALUE="$(( (BYTE_VALUE & NOT_FIELD_MASK) | (WRITE_VALUE << FIELD_OFFSET_BIT) ))"
	dbg "New value:   '$BYTE_VALUE'"

	write_field
else
	read_field

	FIELD_VALUE="$(( (BYTE_VALUE & FIELD_MASK) >> FIELD_OFFSET_BIT))"
	dbg "Field value: '$FIELD_VALUE'"

	echo "$FIELD_VALUE"
fi
