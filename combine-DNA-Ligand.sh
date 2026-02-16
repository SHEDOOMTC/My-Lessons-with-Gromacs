#!/bin/bash


##### STEP 1 ######

echo 'Copying and Inserting the ligand information into the macromolecule'

# Count how many lines will be inserted (skip first 2, skip last 1)
insert_count=$(tail -n +3 A01_GMX.gro | head -n -1 | wc -l)

# Read the original atom count from line 2 of complex.gro
orig_count=$(sed -n '2p' complex.gro)

# Compute the new atom count
new_count=$((orig_count + insert_count))

#store the number of the last residue in the complex.gro
num=$(tail -n 2 complex.gro | head -n 1 | awk '{print substr($1,1,2)}')
num=$((num + 1))

# Build the new file
{
    # Line 1 stays the same
    sed -n '1p' complex.gro

    # Updated line 2
    echo "$new_count"

    # Everything except the last line, starting from line 3
    sed -n '3,$p' complex.gro | head -n -1

    # Insert processed A01_GMX.gro content
    tail -n +3 A01_GMX.gro | head -n -1

    # Append original last line
    tail -n 1 complex.gro
} > complex.tmp

# Replace original file
mv complex.tmp complex.gro



##### STEP 2 ######

#Use gromacs to renumber the atoms

gmx editconf -f complex.gro -o complex_renum.gro



##### STEP 3 ######

# Use sed to replace the name and number of ligand

sed 's/ 1A01 /'$num'A01 /' complex_renum.gro > complex_fixed.gro

#then rename the file back to complex.gro

mv complex_fixed.gro complex.gro

