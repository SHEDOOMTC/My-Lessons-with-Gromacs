#!/bin/bash

ligand_gro="$1"
complex_gro="$2"

if [[ -z "$ligand_gro" || -z "$complex_gro" ]]; then
    echo "Usage: $0 ligand.gro complex.gro"
    exit 1
fi

echo "How many times should the ligand be appended?"
read copies

if ! [[ "$copies" =~ ^[0-9]+$ ]]; then
    echo "Error: please enter an integer (1, 2, 3, ...)"
    exit 1
fi

for ((n=1; n<=copies; n++)); do
    echo "=== Append round $n of $copies ==="

    ##### STEP 1 ######

    # Count how many lines will be inserted (skip first 2, skip last 1)
    insert_count=$(tail -n +3 "$ligand_gro" | head -n -1 | wc -l)

    # Read the original atom count from line 2 of complex.gro
    orig_count=$(sed -n '2p' "$complex_gro")

    # Compute the new atom count
    new_count=$((orig_count + insert_count))

    # store the number of the last residue in the complex.gro
    num=$(tail -n 2 "$complex_gro" | head -n 1 | awk '{print substr($1,1,2)}')
    num=$((num + 1))

    # store the name of the ligand
    lig_name=$(awk 'NR==3 {print $2}' "$ligand_gro")

    # Build the new file
    {
        # Line 1 stays the same
        sed -n '1p' "$complex_gro"

        # Updated line 2
        echo "$new_count"

        # Everything except the last line, starting from line 3
        sed -n '3,$p' "$complex_gro" | head -n -1

        # Insert processed ligand content
        tail -n +3 "$ligand_gro" | head -n -1

        # Append original last line
        tail -n 1 "$complex_gro"
    } > complex.tmp

    mv complex.tmp "$complex_gro"

done

##### STEP 2 ######

# Use gromacs to renumber the atoms
gmx editconf -f "$complex_gro" -o complex_renum.gro

##### STEP 3 ######

# Use sed to replace the name and number of ligand

sed "s/ 1${lig_name} /${num}${lig_name} /" complex_renum.gro > complex_fixed.gro

mv complex_fixed.gro "$complex_gro"
