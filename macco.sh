#!/bin/bash

################################# Set defaults ################################

FUNCT=to_linux
AUTO_FUNCT=to_cisco_lower
CASE=''

############################### Create Help text ##############################

HELP="
Usage: [STDIN] | $0 [OPTIONS]... [MAC-ADDRESS]...

	-a,-A	"Automatic" mode (depends on script defaults)
	-b,-B	Binary style
	-c,-C	Cisco style ('maca.ddre.sses') (NB: always lowercase)
	-h,-H	Help - display this text and quit.
	-l	Linux style - lowercase	('ma:ca:dd:re:ss:es')
	-L	Linux style - uppercase	('MA:CA:DD:RE:SS:ES')
	-n	Naked style - lowercase	('macaddresses')
	-N	Naked style - uppercase	('MACADDRESSES')
	-p	H(P) style ('macadd-resses')
	-w	Windows style ('ma-ca-dd-re-ss-es')

Notes: 
 - Automatic Mode convert to the default format (defined in the script). 
    If the supplied MAC is in that format, it is converted to the 'automatic' format.
 - MAC address(es) can be supplied by STDIN, and/or script arguments.
    If both STDIN and arguments are supplied, STDIN is processed first.
 - If no MAC address(es) is supplied, all system MAC addresses are displayed.
"

######################### Define Conversion Functions #########################
#
# Codes to append to force case;
# _upper	force UPPERCASE
# _lower	force lowercase
# _ignore	ignore case
#

function to_cisco_lower
{
	# Cisco-style: maca.ddre.sses
	sed 's/..../\U&\./g;s/\.$//' <<< $@
}

function to_linux
{
	# Linux-style: ma:ca:dd:re:ss:es
	sed 's/../&:/g;s/\:$//' <<< $@ 
}

function to_hp
{
	# HP-style: macadd-resses
	sed 's/....../&-/g;s/\-$//' <<< $@
}

function to_windows
{
	# Windows-style: MA-CA-DD-RE-SS-ES
	sed 's/../&-/g;s/\-$//' <<< $@
}

function to_naked
{
	# Naked-style: macaddresses / MACADDRESSES
	echo $@ | tr -d '\:\-\.'
}

function to_binary_ignore
{
	bc <<< "obase=2; ibase=16; $(to_naked $@ | tr [a-z] [A-Z])" | zfill 48
}

########################### Define Helper Functions ###########################

function zfill
{
	cat - | sed ':a;s/^.\{1,'"$[$1-1]"'\}$/0&/g;ta'
}


function is_true
{
	return $(egrep -i "true|yes|1|okay" <<< $1 > /dev/null)
}

function is_equiv
{
	[[ -z "$2" ]] && return 0
	function normalise
	{
		echo $@ | tr '[a-f]' '[A-F]'
	}
	ref=$(normalise $1)
	shift
	for x in "$@"
	do
		[[ "$ref" != "$(normalise $x)" ]] && return 1
	done
	return 0
}

function get_case
{
	# $1	Function name
	# $2	Suggested case

	case $1 in
		*_upper)
			echo "tr '[a-f]' '[A-F]'"
			;;
		*_lower)
			echo "tr '[A-F]' '[a-f]'"
			;;
		*_ignore)
			echo "cat -"
			;;
		*)
			if [[ -n "$2" ]]
			then
				$(is_true $2) && echo "tr '[a-f]' '[A-F]'" || echo "tr '[A-F]' '[a-f]'"
			else
				echo 'cat -'
			fi
			;;
	esac
}

function convert
{
	# $1	MAC address to convert
	# $2	Output Case (true=UPPERCASE). No conversion if false

	OUTPUT=$($FUNCT $(to_naked $1))
	if $(is_true $AUTO_MODE) && $(is_equiv "$OUTPUT" "$1")
	then
		echo "$($AUTO_FUNCT $(to_naked $1))" | $(get_case $AUTO_FUNCT $2)
	else
		echo "$OUTPUT" | $(get_case $FUNCT $2)
	fi
}

################################# Get Options #################################

SHIFT=0

while getopts "aAbBcClLnNpPwW" OPTION
do
	let SHIFT+=1
	case "$OPTION" in
		a|A)
			AUTO_MODE='true'
			;;
		b|B)
			FUNCT=to_binary_ignore
			;;
		c|C)
			FUNCT=to_cisco_lower
			;;
		h|H)
			echo "$HELP"
			exit 0
			;;
		l|L)
			FUNCT=to_linux
			;;
		n|N)
			FUNCT=to_naked
			;;
		p|P)
			FUNCT=to_hp
			;;
		w|W)
			FUNCT=to_windows
			;;
		--)
			break
			;;
		?)
			echo "$HELP"
			exit 1
			;;
	esac

	if [[ "$OPTION" =~ [A-Z] ]]
	then
		UPPER_CASE='true'
	else
		UPPER_CASE='false'
	fi
done

shift $SHIFT # Must be done outside of `while getopt` loop (or things break).

################################## Run Program ################################

if [[ ! -t 0 ]]
# STDIN not empty
then
	while read mac
	do
		convert "$mac" "$UPPER_CASE"
	done
fi

if [[ -n "$1" ]]
then
	for mac in $@
	do
		convert "$mac" "$UPPER_CASE"
	done
elif [[ -t 0 ]]
then
	ifaces=$(ip link | sed '/^[\t ]/d;/LOOPBACK/d;s/://g' | awk '{print $2}')
	echo -e "$ifaces" | while read iface ; do
		mac=$(ip a s $iface | awk '/ether/{print $2}')
		mac=$(convert $mac "$UPPER_CASE")
		if [[ -n "$mac" ]]
		then
			echo -e "$iface:\t$mac"
		fi
	done
fi
