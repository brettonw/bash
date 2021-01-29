#! /usr/bin/env bash

# given a list of "bin" directories, look at all of the directories in them and return a path string 
# for them, taking into account whether the directory contains a "bin" of its own (like maven, etc).

output="";
separator="";
for path in "$@"; do
	#echo $path;
	output="$path$separator$output";
	separator=":";
	paths=($(find -L $path -mindepth 1 -maxdepth 1 -type d));
	for subPath in ${paths[@]}; do
		if [ -d "$subPath/bin" ]; then 
			output="$subPath/bin$separator$output";
		else
			output="$subPath$separator$output";
		fi
	done
done
echo $output;