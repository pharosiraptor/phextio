#!/bin/bash

# phextv1.file: extract.sh
# Copyright: (c) 2024 Will Bickford
# License: MIT
# Purpose: extracts scripts from phext research documents

file=$1
force=false

if [ "$2" == "-force" ]; then
  force=true
fi

if [ ! -f "$file" ]; then
  echo "Unable to locate $file."
  exit 1
fi

SCROLL_BREAK=$'\x17'
scrolls=$(<"$file" awk -v RS="$SCROLL_BREAK" '{print $0}')
scroll_count=$(echo "$scrolls" | wc -l)

if [ "$scroll_count" -ne 3 ]; then
  echo "Invalid phext research file"
  exit 1
fi

scroll1=$(echo "$scrolls" | sed -n '2p' | tr '\r' '\n')
lines=$(echo "$scroll1" | wc -l)

echo "Scanning $lines for code..."

if [ "$lines" -gt 1000000 ]; then
  echo "Refusing to parse your spew"
  exit 1
fi

parsing=false
script=""
declare -A output

while IFS= read -r line; do
  if [[ $line =~ ^phextv1\.code$ ]]; then
    parsing=true
  fi
  if [[ $line =~ ^phextv1\.results$ ]]; then
    parsing=false
  fi

  if [[ $line =~ ^#\ phextv1\.file:\  ]]; then
    script=$(echo "$line" | sed 's/^# phextv1\.file: //')
    output["$script"]=""
    continue
  fi

  if $parsing; then
    output["$script"]+="$line"$'\n'
    continue
  fi
done <<< "$scroll1"

if [ ${#output[@]} -gt 0 ]; then
  for script in "${!output[@]}"; do
    data="${output[$script]}"
    if $force || [ ! -f "$script" ]; then
      echo -n "$data" > "$script"
      echo "Wrote $(echo -n "$data" | wc -l) lines to $script."
    else
      echo "Warning: $script already exists. Use -force to overwrite."
    fi
  done
fi
