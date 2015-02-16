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

compname=`echo "$CR_FILENAME" | sed 's/\(.*\)\..*/\1/'`.exe
gmcs "$CR_FILENAME" "${@:1}"
status=$?
if [ $status -eq 0 ]
then
echo $compname
exit 0
elif [ $status -eq 127 ]
then
echo -e "\nIn order to run C# code, you need to have Mono installed. You can get it at http://mono-project.com"
fi
exit $status