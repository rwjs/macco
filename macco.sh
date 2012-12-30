#!/bin/bash

################################# Set defaults ################################

FUNCT=to_linux
AUTO_FUNCT=to_cisco_lower
UPPER_CASE=''

############################### Create Help text ##############################

HELP="
Usage: [STDIN] | $0 [OPTIONS]... [MAC-ADDRESSES]...

	-a,-A	'Automatic' mode (depends on defaults defined in the script)
	-b,-B	Binary style
	-c,-C	Cisco style ('maca.ddre.sses') (NB: always lowercase)
	-h,-H	Help - display this text and quit.
	-l	Linux style - lowercase	('ma:ca:dd:re:ss:es')
	-L	Linux style - UPPERCASE	('MA:CA:DD:RE:SS:ES')
	-n	Naked style - lowercase	('macaddresses')
	-N	Naked style - UPPERCASE	('MACADDRESSES')
	-p	H(P) style - lowercase ('macadd-resses')
	-P	H(P) style - UPPERCASE ('MACADD-RESSES')
	-s	Solaris style - lowercase ('50:1A:12:14:a:b')
	-S	Solaris style - UPPERCASE ('50:1A:12:15:A:B')
	-w	Windows style - lowercase ('ma-ca-dd-re-ss-es')
	-W	Windows style - UPPERCASE ('MA-CA-DD-RE-SS-ES')

Notes: 
 - Automatic Mode converts to the 'default' format (as defined by "FUNCT"). 
    If the supplied MAC is already in that format, it is converted to the 
    'automatic' format (defined by "AUTO_FUNCT")
 - MAC address(es) can be supplied by STDIN, and/or script arguments.
    If both STDIN and arguments are supplied, STDIN is processed first.
 - Input from STDIN will be parsed for MAC addresses (that is, the script will
    make an effort to only convert tokens which look like MAC addresses whilst
    passing through all other input).
 - If no MAC addresses are supplied, all system MAC addresses 
    (excluding loopback) are displayed.
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
	echo "$@" | tr -d '\:\-\.'
}

function to_solaris
{
	sed 's/../:&/g;s/:0/:/g;s/^://' <<< $@
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

function is_macaddr
(
	clean=$(echo "$1" | tr -cd '[A-Fa-f0-9]')
	[[ ${#clean} == 12 ]]
	return $?
)

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

	OUTPUT=$($FUNCT $(to_naked "$1"))
	if $(is_true $AUTO_MODE) && $(is_equiv "$OUTPUT" "$1")
	then
		echo -n $($AUTO_FUNCT $(to_naked "$1")) | $(get_case $AUTO_FUNCT $2)
	else
		echo -n "$OUTPUT" | $(get_case $FUNCT $2)
	fi
}

function parse
{
	# Attempt to detect MAC addresses (only), and convert them.
	#
	# No arguments

	while IFS='' read -d '\n' -n1 chr
	do
		if [[ $chr =~ [$IFS] ]]
		then
			is_macaddr "$token" && convert "$token" "$UPPER_CASE" || printf "$token"
			printf "$chr"
			token=''
			continue
		fi
		token+=$chr
	done
}

################################# Get Options #################################

SHIFT=0

while getopts "aAbBcClLnNpPsSwW" OPTION
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
		s|S)
			FUNCT=to_solaris
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
	parse
fi

if [[ -n "$1" ]]
then
	for mac in $@
	do
		convert "$mac" "$UPPER_CASE"
		echo
	done
elif [[ -t 0 ]]
then
	ifaces=$(ip link | sed '/^[\t ]/d;/LOOPBACK/d;s/://g' | awk '{print $2}')
	echo -e "$ifaces" | while read iface ; do
		mac=$(ip a s $iface | awk '/ether/{print $2}')
		mac=$(convert "$mac" "$UPPER_CASE")
		if [[ -n "$mac" ]]
		then
			echo -e "$iface:\t$mac"
		fi
	done
fi
