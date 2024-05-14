#!/bin/bash

# Function to convert a number to Base88
toBase88() {
  local value=$1
  local temp=$value
  local lookup="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ,./?:[]|{}=-+_)(*&^%$#@!~"
  local result=""

  if [ "$temp" -eq 0 ]; then
    echo "0"
    return
  fi

  while [ "$temp" -ne 0 ]; do
    local remainder=$((temp % 88))
    temp=$((temp / 88))
    result="${lookup:remainder:1}$result"
  done

  echo "$result"
}

# Accepting input value as the first argument
value=$1

# Calling the function and passing the value
toBase88 "$value"
