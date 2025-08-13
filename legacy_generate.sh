#!/bin/bash

# Clear and set up src directory
rm -rf src 
mkdir src

# Generate C files from the DBC file
cantools generate_c_source mini_celka.dbc -o src --use-float
# python barka_enum_generator.py "barka.dbc"

# cat src/barka_dbc_enumeration.h

read -n 1 -p "Press 'b' to build or any other key to exit... " x
echo
if [[ $x == "b" || $x == "B" ]]; then
    echo "Building..."
    mkdir -p build

    # Create a temporary test file to validate headers
    echo '#include "../src/mini_celka.h"' > build/test_headers.c
    # echo '#include "../src/barka_dbc_enumeration.h"' >> build/test_headers.c

    # Compile C source files
    gcc -c src/mini_celka.c -o build/mini_celka.o
    # gcc -c build/test_headers.c -o build/test_headers.o

    # Check if compilation was successful
    if [[ $? -eq 0 ]]; then
        echo "Build succeeded."
    else
        echo "Build failed."
    fi

    read -p "Press any key to exit..." x
    rm -rf build
fi
echo "Exiting..."
sleep 1
