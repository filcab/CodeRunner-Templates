#!/bin/bash
# This is a CodeRunner compile script. Compile scripts are used to compile
# code before being run using the run command specified in CodeRunner
# preferences. This script is invoked with the following properties:
#
# Current directory:	The directory of the source file being run
#
# Arguments $1-$n:		User-defined compile flags	
#
# Environment:			$CR_FILENAME	Filename of the source file being run
#						$CR_ENCODING	Encoding code of the source file
#						$CR_TMPDIR		Path of CodeRunner's temporary directory
#
# This script should have the following return values:
# 
# Exit status:			0 on success (CodeRunner will continue and execute run command)
#
# Output (stdout):		On success, one line of text which can be accessed
#						using the $compiler variable in the run command
#
# Output (stderr):		Anything outputted here will be displayed in
#						the CodeRunner console

out=`echo "$CR_FILENAME" | sed 's/\(.*\)\..*/\1/'`
if [ -d "$out" ]; then
	out="$out.out"
fi

# Check if Xcode is installed
xcrun swiftc &>/dev/null
status=$?
if [ $status -eq 69 ]; then
	echo "To run swift code you need to open Xcode and accept the developer license agreement."
	exit 69
else
	if [ "$CR_FILENAME" = "main.swift" ]; then
		xcrun -sdk macosx swiftc -o "$out" *.swift "${@:1}" ${CR_DEBUGGING:+-g}
	else
		xcrun -sdk macosx swiftc -o "$out" "$CR_FILENAME" "${@:1}" ${CR_DEBUGGING:+-g}
	fi
	status=$?
fi

if [ $status -eq 0 ]; then
	echo "$out"
fi
exit $status