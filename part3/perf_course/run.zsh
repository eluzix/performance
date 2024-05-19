#!/bin/zsh

# Check if a string is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <search_string>"
  exit 1
fi

# Get the search string from the parameter
search_string="$1"

# Iterate over all .rs files in src/bin
for file in src/bin/*.rs; do
  # Check if the filename contains the search string
  if [[ "${file:t}" == *"$search_string"* ]]; then
    # Extract the base name without extension
    base_name="${file:t:r}"


    echo "Building $base_name..."

    # Build the specific file with Cargo
    OBJ_FILE="$2" cargo run --bin "$base_name"

    # Check if the build was successful
    if [ $? -ne 0 ]; then
      echo "Cargo build failed for $base_name"
      exit 1
    fi

    exit 0
  fi
done

# If no file was found with the string
echo "No .rs file found with the string '$search_string' in the filename"
exit 1
