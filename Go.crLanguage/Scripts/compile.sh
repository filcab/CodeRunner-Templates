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

out=$(sed 's/\(.*\)\..*/\1/' <<< "$CR_FILENAME")

if [[ "$PWD" -ef "$CR_TMPDIR" ]]; then
	go_tmp_dir=true
	# If building an unsaved file, use a separate directory to avoid conflicts.
	rm -rf "$CR_TMPDIR/Go/" &>/dev/null
	mkdir "$CR_TMPDIR/Go"
	cp "$CR_FILENAME" "$CR_TMPDIR/Go/$CR_FILENAME"
	cd "Go"
	CR_FILENAME="Go/$CR_FILENAME"
fi

go build -o "$out" "${@:1}"
status=$?
if [ $status -eq 0 ]; then
	if [ "$go_tmp_dir" = true ]; then
		mv -f "$CR_TMPDIR/Go/"* "$CR_TMPDIR/"
	fi
	echo "$out"
fi
exit $status