#!/bin/bash

# Load util module.
# ---
source "$(dirname "${BASH_SOURCE[0]}")/util.sh" || exit 1
# ---

# Check input data.
# ---
INPUT="$1"
OUTPUT="$2"

if [[ -z "$INPUT" || -z "$OUTPUT" ]]; then
	cat >&2 <<EOF
Input/output file(s) not given. Usage:

	$0 INPUT OUTPUT

INPUT should contain the Field() block defining the EmbeddedControl
operation region. Extract it from your decompiled DSDT.

[example:

OperationRegion (ERAM, EmbeddedControl, Zero, 0xFF)
Field (ERAM, ByteAcc, Lock, Preserve)
{
	// INPUT starts here
	CDPR, 1,
	Offset (0x04),
	....
	BDN0, 8
	// INPUT ends here
}

-- example end.]

OUTPUT will be a file following bash syntax and containing parsed
information about EC RAM fields.

Exiting.
EOF

	exit 1
fi
# ---

# Variable definitions.
# ---
POSITION=0
# ---

set -e
exec < "$INPUT" > "$OUTPUT"

echo "declare -A EC_FIELDS"
echo "EC_FIELDS=("

while read line; do
	if [[ "$line" =~ Offset\ \((.*)\) ]]; then
		OFFSET="${BASH_REMATCH[1]}"
		dbg "- offset: '$OFFSET'"

		(( POSITION = $OFFSET * 8 ))
	elif [[ "$line" =~ ([[:alnum:]]*),\ *([[:digit:]]*) ]]; then
		NAME="${BASH_REMATCH[1]}"
		LENGTH="${BASH_REMATCH[2]}"
		dbg "- parameter: name '$NAME' length '$LENGTH'"

		if [[ "$NAME" ]]; then
			echo "	[\"$NAME\"]=\"$POSITION,$LENGTH\""
		fi
		(( POSITION += $LENGTH ))
	else
		echo "- /wrong/ line: $line" >&2
		echo "Exiting." >&2

		rm -f "$OUTPUT"
		exit 1
	fi
done

echo ")"
