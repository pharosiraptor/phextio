#!/bin/bash
# phextv1.file: phexty.sh
# ----------
# Copyright: (c) 2024 Will Bickford
# License: MIT
# Purpose: assists with calculating phext research addresses
#
# the phext address space for research is rooted at library=1, shelf=1, and series=1 (1.1.1/yyy.xxx).
#
# Dimensions: 1.1.1/A.B.C/D.E.F
#   A: phext-soundex(title)
#   B: phext-soundex(abstract)
#   C: phext-soundex(methods)
#   D: phext-soundex(code)
#   E: phext-soundex(results)
#   F: phext-soundex(resources)

# Function to compute soundex value for a given byte
soundex() {
  byte=$1
  lookup=$2
  increment=$3
  value=0
  for ((i = 0; i < ${#lookup}; ++i)); do
    if [ "$byte" == "${lookup:$i:1}" ]; then
      value=$((value + increment))
    fi
  done
  echo $value
}

# Function to compute phext sub-coordinate (recursive soundex modulo 100)
phexty_soundex_v1() {
  text=$1
  if [ -z "$text" ]; then
    echo 1
    return
  fi

  trim=$(echo "$text" | tr -d '[:space:]')
  max=${#trim}
  if [ "$max" -eq 0 ]; then
    echo 1
    return
  fi

  lower=$(echo "$trim" | tr '[:upper:]' '[:lower:]')
  value=0
  letter1="bpfv"
  letter2="cskgjqxz"
  letter3="dt"
  letter4="l"
  letter5="mn"
  letter6="r"
  for ((i = 0; i < max; ++i)); do
    byte="${lower:$i:1}"
    value=$((value + $(soundex "$byte" "$letter1" 1)))
    value=$((value + $(soundex "$byte" "$letter2" 2)))
    value=$((value + $(soundex "$byte" "$letter3" 3)))
    value=$((value + $(soundex "$byte" "$letter4" 4)))
    value=$((value + $(soundex "$byte" "$letter5" 5)))
    value=$((value + $(soundex "$byte" "$letter6" 6)))
  done
  value=$((value % 100))
  echo $value
}

file=$1
verbose=false
raap="1.1.2" # reserved by @wbic16
SCROLL_BREAK=$'\x17'

if [ ! -f "$file" ]; then
  echo "Unable to locate $file."
  exit 1
fi

scrolls=$(<"$file" awk -v RS="$SCROLL_BREAK" '{print $0}')
scroll_count=$(echo "$scrolls" | wc -l)

if [ "$scroll_count" -ne 3 ]; then
  echo "Invalid phext research stream - you must provide exactly 3 scrolls (found: $scroll_count)."
  exit 1
fi

# ------------------------------------------------------------------------------------------------------------

echo "input: $file"
echo "scrolls: $scroll_count"

have_title=false
have_abstract=false
have_methods=false
have_code=false
have_results=false
have_resources=false

# ------------------------------------------------------------------------------------------------------------

title=""
abstract=""
methods=""

parsing_abstract=0
parsing_intro=0
parsing_methods=0
BLOB_HEADER="^----"

scroll0=$(echo "$scrolls" | sed -n '1p')
while IFS= read -r line; do
  trim=$(echo "$line" | xargs)
  if [ ${#trim} -eq 0 ]; then
    continue
  fi

  # parse title
  if ! $have_title && [[ $line =~ ^phextv1\.title: ]]; then
    have_title=true
    title=$(echo "$line" | sed 's/^.*title://')
    title=$(echo "$title" | xargs)
    continue
  fi

  # parse abstract
  if ! $have_abstract; then
    if [[ $line =~ ^phextv1\.abstract ]]; then
      parsing_abstract=1
      continue
    fi
    if [[ $line =~ $BLOB_HEADER ]]; then
      parsing_abstract=2
      continue
    fi

    if [[ $line =~ ^phextv1\.intro ]]; then
      have_abstract=true
      parsing_intro=1
      continue
    fi

    if [ $parsing_abstract -eq 2 ]; then
      abstract+="$line\n"
      continue
    fi
  fi

  # parse methods
  if ! $have_methods; then
    if [[ $line =~ ^phextv1\.methods ]]; then
      parsing_methods=1
      continue
    fi
    if [[ $line =~ $BLOB_HEADER ]]; then
      parsing_methods=2
      continue
    fi

    if [ $parsing_methods -eq 2 ]; then
      methods+="$line\n"
      continue
    fi
  fi
done <<<"$scroll0"

have_methods=$(echo -e "$methods" | wc -l)

# ------------------------------------------------------------------------------------------------------------
parsing_code=0
parsing_results=0
parsing_resources=0

code=""
results=""
resources=""

scroll1=$(echo "$scrolls" | sed -n '2p')
while IFS= read -r line; do
  trim=$(echo "$line" | xargs)
  if [ ${#trim} -eq 0 ]; then
    continue
  fi

  if ! $have_code; then
    if [[ $line =~ ^phextv1\.code ]]; then
      parsing_code=1
      continue
    fi

    if [ $parsing_code -eq 1 ] && [[ $line =~ $BLOB_HEADER ]]; then
      parsing_code=2
      continue
    fi

    if [[ $line =~ ^phextv1\.results$ ]]; then
      have_code=true
      parsing_results=1
      continue
    fi

    if [ $parsing_code -eq 2 ]; then
      code+="$line\n"
      continue
    fi
  fi

  if ! $have_results; then
    if [ $parsing_results -eq 1 ] && [[ $line =~ $BLOB_HEADER ]]; then
      parsing_results=2
      continue
    fi

    if [[ $line =~ ^phextv1\.resources$ ]]; then
      have_results=true
      parsing_resources=1
      continue
    fi

    if [ $parsing_results -eq 2 ]; then
      results+="$line\n"
      continue
    fi
  fi

  if ! $have_resources; then
    if [ $parsing_resources -eq 1 ] && [[ $line =~ $BLOB_HEADER ]]; then
      parsing_resources=2
      continue
    fi

    if [ $parsing_resources -eq 2 ]; then
      resources+="$line\n"
      continue
    fi
  fi
done <<<"$scroll1"

have_results=$(echo -e "$results" | wc -l)
have_resources=$(echo -e "$resources" | wc -l)

# phext research addresses are of the form:
# 1.1.2/collection.volume.book/chapter.section.scroll
# cn.vm.bk/ch.sn.sc
ok=true
if ! $have_title; then
  echo "missing title"
  ok=false
fi
if ! $have_abstract; then
  echo "missing abstract"
  ok=false
fi
if ! $have_methods; then
  echo "missing methods"
  ok=false
fi
if ! $have_code; then
  echo "missing code"
  ok=false
fi
if ! $have_results; then
  echo "missing results"
  ok=false
fi
if ! $have_resources; then
  echo "warning: no resources found"
fi
if ! $ok; then
  exit 1
fi

cn=$(phexty_soundex_v1 "$title")

abstract_text=$(echo -e "$abstract")
vm=$(phexty_soundex_v1 "$abstract_text")

book_text=$(echo -e "$methods")
bk=$(phexty_soundex_v1 "$book_text")

code_text=$(echo -e "$code")
ch=$(phexty_soundex_v1 "$code_text")

results_text=$(echo -e "$results")
sn=$(phexty_soundex_v1 "$results_text")

resources_text=$(echo -e "$resources")
sc=$(phexty_soundex_v1 "$resources_text")

echo "title: $title"
echo "phext address: $raap/$cn.$vm.$bk/$ch.$sn.$sc"

if $verbose; then
  echo "$abstract"
fi
