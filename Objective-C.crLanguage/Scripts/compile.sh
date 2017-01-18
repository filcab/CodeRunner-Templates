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

if [ ! -z $CR_SANDBOXED ]; then
	echo -e "To run Objective-C code, you need to use the non-App Store version of CodeRunner, which is free for App Store customers.\n\nDownload the non-App Store version of CodeRunner at https://coderunnerapp.com/. You will also need Xcode to run Objective-C code, which can be downloaded from the Mac App Store."
	exit 1
fi

out=`echo "$CR_FILENAME" | sed 's/\(.*\)\..*/\1/'`
if [ -d "$out" ]; then
	out="$out.out"
fi

autoinclude=true
for arg in "$@"; do
	if [[ $arg = "-cr-noautoinclude" ]]; then
		autoinclude=false
		continue
	fi
	args+=("$arg");
done;
set -- "${args[@]}"

# CodeRunner autoinclude - automatically links included files
# Disable by using -cr-noautoinclude compile flag
if [ $autoinclude = true ]; then
	filelist=`php "$CR_DEVELOPER_DIR"/autoinclude.php "$PWD/$CR_FILENAME" 2>/dev/null`
	includestatus=$?
	if [ $includestatus -eq 0 ]; then
		# Hacky way of getting bash to interpret the files separated by ':' as distinct arguments
		OIFS="$IFS"
		IFS=':'
		read -a files <<< "${filelist}"
		IFS="$OIFS"
	else
		files=("$CR_FILENAME")
	fi
else
	files=("$CR_FILENAME")
fi

xcrun clang -v &>/dev/null
s=$?
if [ $s -eq 69 ]; then
	>& 2 echo "Please open Xcode and accept the Developer License Agreement to run Objective-C code."
	exit $s
elif [ $s -ne 0 ]; then
	osxversion=`sw_vers -productVersion | awk -F '.' '{print $1 "." $2}'`
	if [ $osxversion = "10.7" ] || [ $osxversion == "10.8" ]; then
		>& 2 echo "To run Objective-C code, you need to have Xcode installed. You can get it from the Mac App Store or from http://developer.apple.com/"
	else
		>& 2 echo "To run Objective-C code, you need to have Xcode installed. Please choose the \"Install\" option in the dialog box."
	fi
	exit $s
fi

xcrun clang -ObjC -o "$out" "${files[@]}" "${@:1}" ${CR_DEBUGGING:+-g}
status=$?

if [ $status -eq 0 ]; then
	echo "$out"
fi
exit $status