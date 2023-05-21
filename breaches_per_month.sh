#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Error: Incorrect number of arguments provided."
  echo "Usage: $0 <input_file>"
  exit 1
fi

input_file=$1

if [ ! -f "$input_file" ]; then
  echo "Error: Input file '$input_file' does not exist or is not a regular file." >&2
  exit 1
fi

if [ ! -r "$input_file" ]; then
  echo "Error: Input file '$input_file' is not readable." >&2
  exit 1
fi

# Initialize counters for each month
Jan=0
Feb=0
Mar=0
Apr=0
May=0
Jun=0
Jul=0
Aug=0
Sep=0
Oct=0
Nov=0
Dec=0

# Loop through each line of the input file and count breaches by month
while read line
do
  if [[ ! $line =~ ^Name_of_Covered_Entity ]]; then # Ignore the first line
    month=$(echo "$line" | cut -f 6)
    case $month in
      1) ((Jan++));;
      2) ((Feb++));;
      3) ((Mar++));;
      4) ((Apr++));;
      5) ((May++));;
      6) ((Jun++));;
      7) ((Jul++));;
      8) ((Aug++));;
      9) ((Sep++));;
      10) ((Oct++));;
      11) ((Nov++));;
      12) ((Dec++));;
      *) echo "Error: Invalid month $month in line \"$line\"" >&2;;
    esac
  fi
done < "$input_file"

# Calculate the mean
mean=$(( (Jan + Feb + Mar + Apr + May + Jun + Jul + Aug + Sep + Oct + Nov + Dec) / 12 ))

# Calculate the median and median absolute deviation
counts=( $Jan $Feb $Mar $Apr $May $Jun $Jul $Aug $Sep $Oct $Nov $Dec )
sorted_counts=( $(
  for i in "${counts[@]}"; do
    echo "$i"
  done | sort -n
) )
count=$(( ${#sorted_counts[@]} ))
mid=$(( count/2 ))
if [[ $((count % 2)) -eq 0 ]]; then
  median=$(( (sorted_counts[mid-1] + sorted_counts[mid])/2 ))
else
  median=${sorted_counts[mid]}
fi
mad_values=()
for i in "${counts[@]}"; do
  mad_values+=( $(( i > median ? i - median : median - i )) )
done
mad_sorted=( $(
  for i in "${mad_values[@]}"; do
    echo "$i"
  done | sort -n
) )
mad_count=${#mad_sorted[@]}
mid=$(( mad_count/2 ))
if [[ $((mad_count % 2)) -eq 0 ]]; then
  mad=$(bc <<< "scale=1; (${mad_sorted[mid-1]} + ${mad_sorted[mid]}) / 2")
else
  mad=${mad_sorted[mid]}
fi

# Function to display ++, --, or nothing based on the month count compared to the median
function display_diff {
  diff=$(( $1 - $median ))
  if [[ $diff -ge 10 ]]; then
    echo "++"
  elif [[ $diff -le -10 ]]; then
    echo "--"
  else
    echo ""
  fi
}

# Display the counts by month in the desired format
echo "Median = $median"
echo "MAD = $mad"
echo ""
echo "Jan $Jan$(display_diff $Jan)"
echo "Feb $Feb$(display_diff $Feb)"
echo "Mar $Mar$(display_diff $Mar)"
echo "Apr $Apr$(display_diff $Apr)"
echo "May $May$(display_diff $May)"
echo "Jun $Jun$(display_diff $Jun)"
echo "Jul $Jul$(display_diff $Jul)"
echo "Aug $Aug$(display_diff $Aug)"
echo "Sep $Sep$(display_diff $Sep)"
echo "Oct $Oct$(display_diff $Oct)"
echo "Nov $Nov$(display_diff $Nov)"
echo "Dec $Dec$(display_diff $Dec)"
