#!/bin/zsh

# Check if a file name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <filename.asm>"
  exit 1
fi

# Get the file name from the parameter
filename="$1"

# Check if the file exists
if [ ! -f "$filename" ]; then
  echo "File not found: $filename"
  exit 1
fi

# Extract the base name without extension
base_name="${filename:r}"

# Run NASM to assemble the file
as -arch arm64 -o "../${base_name}.o" "$filename"

# Check if the assembly was successful
if [ $? -ne 0 ]; then
  echo "AS assembly failed"
  exit 1
fi

echo "Assembly successful. Output file: ${base_name}.o"
