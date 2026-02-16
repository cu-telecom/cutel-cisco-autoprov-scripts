#!/usr/bin/env bash

set -euo pipefail

OUTPUT="library.tar"

FILES=( *.tcl )

if [ "${FILES[0]}" = "*.tcl" ] || [ ${#FILES[@]} -eq 0 ]; then
    echo "No .tcl files found in current directory."
    exit 1
fi

echo "Creating $OUTPUT with the following files:"
printf ' - %s\n' "${FILES[@]}"

tar -cf "$OUTPUT" "${FILES[@]}"

echo "Done."
