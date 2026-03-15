#!/usr/bin/env bash

arr=("quick" "0" "7" "9" "10" "11" "12" "14")
for n in "${arr[@]}"; do
    typst c ../examples/example_${n}.typ --pages 1 --ppi 250 --format png
done

mv ../examples/*.png .

oxipng -o max --fast -Z --strip all *.png
