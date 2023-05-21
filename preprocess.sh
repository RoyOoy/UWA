#!/bin/bash

# Validate arguments
if [ $# -ne 1 ]; then
  echo "Error: Incorrect number of arguments provided."
  echo "Usage: $0 <input-file>"
  exit 1
fi

# Check if input file exists
if [ ! -f "$1" ]; then
  echo "Error: Input file '$1' does not exist."
  exit 1
fi

# Define awk script
awk_script='
BEGIN {
  FS="\t"; OFS="\t"
  print "Name_of_Covered_Entity", "State", "Individuals_Affected", "Date_of_Breach", "Type_of_Breach", "Month", "Year"
}

# Remove any commas or slashes after the first one in the Type_of_Breach field
{
  gsub(/,.*|\//, "", $5)
}

# Extract month and year from Date_of_Breach and add them as new fields
{
  split($4, d, /[-\/]/)
  $6 = sprintf("%d", d[1])   # Month (without leading zero)
  year = sprintf("%04d", (d[3] < 50 ? 2000+d[3] : (d[3] < 100 ? 1900+d[3] : d[3]))) # Year (with leading zeroes)
  if (year < 1950 || year > 2090) {
    print "Invalid year:", year > "/dev/stderr"
    exit 1
  }
  $7 = year
}

# Print the cleaned and enriched row
{
  print $1, $2, $3, $4, $5, $6, $7
}'

# Prompt user for output file name
read -p "Enter output file name: " fname

# Check if output file already exists
if [ -f "$fname" ]; then
  read -p "Warning: Output file '$fname' already exists. Do you want to overwrite it? [y/n] " overwrite
  case $overwrite in
    [Yy]* ) ;;
    [Nn]* ) exit;;
    * ) echo "Error: Invalid input. Please answer yes or no."
        exit 1;;
  esac
fi

# Apply awk script to input file, and redirect output to stdout and file
exec 3>&1   # Save stdout to file descriptor 3
sed '1d' "$1" | awk "$awk_script" | tee >(cat >&3 > "$fname")
