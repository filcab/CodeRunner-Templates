<?php
	// Usage: parsejava.php [--package] file
	// Looks for packages and main methods in java files.
	// Exit code 0 on success, output <package>.<class> or <class>
	// Exit code 1 on failure, output <package> or nothing.
	// If --package is supplied, only output package name.
	error_reporting(0);
	ini_set('display_errors', 0);
	$packageOnly = $argv[1] == "--package";
	$filename = $packageOnly ? $argv[2] : $argv[1];
	$file = file_get_contents($filename);
	$lineComment = -1;
	$blockComment = -1;
	$charString = -1;
	$string = -1;
	for ($i = 0; $i < strlen($file); $i++) {
		if ($lineComment != -1) {
			if (substr($file, $i, 1) == "\n" || substr($file, $i, 1) == "\r") {
				$file = substr($file, 0, $lineComment).substr($file, $i+1);
				$i = $lineComment-1;
				$lineComment = -1;
			}
			continue;
		}
		if ($blockComment != -1) {
			if (substr($file, $i-1, 2) == "*/") {
				$file = substr($file, 0, $blockComment).substr($file, $i+1);
				$i = $blockComment-1;
				$blockComment = -1;
			}
			continue;
		}
		if ($charString != -1) {
			if (substr($file, $i, 1) == "'" && !isCharecterAtIndexEscaped($file, $i)) {
				$file = substr($file, 0, $charString).substr($file, $i+1);
				$i = $charString-1;
				$charString = -1;
			}
			continue;
		}
		if ($string != -1) {
			if (substr($file, $i, 1) == "\"" && !isCharecterAtIndexEscaped($file, $i)) {
				$file = substr($file, 0, $string).substr($file, $i+1);
				$i = $string-1;
				$string = -1;
			}
			continue;
		}
		
		if ($i >= 1 && substr($file, $i-1, 2) == "//") {
			$lineComment = $i-1;
			continue;
		}
		if ($i >= 1 && substr($file, $i-1, 2) == "/*") {
			$blockComment = $i-1;
			continue;
		}
		if ($i >= 1 && substr($file, $i, 1) == "'") {
			if (!isCharecterAtIndexEscaped($file, $i)) {
				$charString = $i;
				continue;
			}
		}
		if ($i >= 1 && substr($file, $i, 1) == "\"") {
			if (!isCharecterAtIndexEscaped($file, $i)) {
				$string = $i;
				continue;
			}
		}
	}
	if ($lineComment != -1)  $file = substr($file, 0, $lineComment);
	if ($blockComment != -1)  $file = substr($file, 0, $blockComment);
	if ($charString != -1)  $file = substr($file, 0, $charString);
	if ($string != -1)  $file = substr($file, 0, $string);
	
	// Find package
	$package = false;
	if (preg_match('/\bpackage[\s\n]+([\w.]+)[\s\n]*;/', $file, $package)) {
		$package = $package[1];
	} else {
		$package = "";
	}
	if ($packageOnly) {
		echo $package;
		exit(0);
	}
	
	// Find main method
	$main = array();
	if (!preg_match('/(static([\s\n]+\w+)*[\s\n]+public[\s\n]+|public([\s\n]+\w+)*[\s\n]+static[\s\n]+)void[\s\n]+main[\s\n]*\([\s\n]*String[\s\n]*\[[\s\n]*\][\s\n\w]+[\s\n]*\)/', $file, $main, PREG_OFFSET_CAPTURE)) {
		echo $package;
		exit(1);
	}
	$main = $main[0][1];
	
	$scopeNest = 0;
	for ($i = $main-1; $i >= 0; $i--) {
		if ($file[$i] == '}') {
			$scopeNest++;
			continue;
		} else if ($file[$i] == '{') {
			$scopeNest--;
			continue;
		}
		if ($scopeNest < -1) {
			echo $package;
			exit(1);
		} else if ($scopeNest == -1) {
			if (substr($file, $i, 5) == "class") {
				$matches = array();
				if (preg_match('/\bclass[\s\n]+([\w.]+)/', substr($file, $i == 0 ? 0 : $i-1), $matches)) {
					$class = $matches[1];
					if (strlen($package) > 0) {
						echo "$package.$class";
					} else {
						echo $class;
					}
					exit(0);
				}
			}
		}
	}
		
	function isCharecterAtIndexEscaped($string, $location) {
		$escape = 0;
		for ($j = $location-1; $j >= 0; $j--) {
			if (substr($string, $j, 1) == "\\") {
				$escape++;
			} else {
				break;
			}
		}
		return $escape % 2 == 1;
	}
?>