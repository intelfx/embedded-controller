#!/bin/bash

DEBUG=1

# Ancillary function definitions.
# ---
function hex() {
	printf "%x" "$1"
}

function dbg() {
	if (( DEBUG )); then
		echo "$@" >&2
	fi
}
# ---
