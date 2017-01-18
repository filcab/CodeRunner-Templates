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

lion=false
if [ `sw_vers -productVersion | awk -F '.' '{print $1 "." $2}'` = "10.7" ]; then
	lion=true
fi

out=`echo "$CR_FILENAME" | sed 's/\(.*\)\..*/\1/'`
if [ -d "$out" ]; then
	out="$out.out"
fi

autoinclude=true
noxcode=false
for arg in "$@"; do
	if [[ $arg = "-cr-noautoinclude" ]]; then
		autoinclude=false
		continue
	elif [[ $arg = "-cr-noxcode" ]]; then
		noxcode=true
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

# Check if Xcode is installed
if [ $noxcode = false ]; then
	xcode-select --print-path &>/dev/null
	s=$?
	if [ $s -ne 0 ]; then
		if [ $lion = false ]; then
			noxcode=true
		else
			>& 2 echo "To run C code on OS X 10.7, you need to have Xcode installed. You can get it from the Mac App Store or from http://developer.apple.com/"
		fi
	fi
	if [ $noxcode = false ]; then
		# Xcode installed
		xcrun clang &>/dev/null
		if [ $? -eq 69 ] && [ $lion = false ]; then
			noxcode=true
		else
			xcrun clang -o "$out" "${files[@]}" "${@:1}" ${CR_DEBUGGING:+-g}
			status=$?
		fi
	fi
fi
if [ $noxcode = true ]; then
	# Xcode not installed
	"$CR_DEVELOPER_DIR/bin/clang" -o "$out" "${files[@]}" "-I$CR_DEVELOPER_DIR/include" "-I$CR_DEVELOPER_DIR/lib/clang/6.0/include" "${@:1}" ${CR_DEBUGGING:+-g}
	status=$?
fi

if [ $status -eq 0 ]; then
	echo "$out"
fi
exit $status