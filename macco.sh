#!/bin/bash

################################# Set defaults ################################

FUNCT=to_linux
AUTO_FUNCT=to_cisco
ONLY_MATCHING=1
case_fnct() { tr 'A-Z' 'a-z' ; }

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
	-O,-o	Only print MAC addresses; similar to the -o flag in grep(1)
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

function to_cisco
{
	# Cisco-style: maca.ddre.sses
	sed 's/..../\L&\./g;s/\.$//' <<< $@
}

function to_linux
{
	# Linux-style: ma:ca:dd:re:ss:es
	sed 's/../&:/g;s/\:$//' <<< $@ | case_fnct
}

function to_hp
{
	# HP-style: macadd-resses
	sed 's/....../&-/g;s/\-$//' <<< $@ | case_fnct
}

function to_windows
{
	# Windows-style: MA-CA-DD-RE-SS-ES
	sed 's/../&-/g;s/\-$//' <<< $@ | case_fnct
}

function to_naked
{
	# Naked-style: macaddresses / MACADDRESSES
	echo "$@" | tr -d '\:\-\.' | case_fnct
}

function to_solaris
{
	sed 's/../:&/g;s/:0/:/g;s/^://' <<< $@ | case_fnct
}

function to_binary
{
	bc <<< "obase=2; ibase=16; $(to_naked $@ | tr [a-z] [A-Z])" | zfill 48
}

########################### Define Helper Functions ###########################

function zfill
{
	cat - | sed ':a;s/^.\{1,'"$[$1-1]"'\}$/0&/g;ta'
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

function convert
{
	# $1	MAC address to convert
	# $2	Output Case (true=UPPERCASE). No conversion if false

	OUTPUT=$($FUNCT $(to_naked "$1"))
	if (( $AUTO_MODE )) && $(is_equiv "$OUTPUT" "$1")
	then
		OUTPUT=$($AUTO_FUNCT $(to_naked "$1"))
	fi
	printf "$OUTPUT"
}

function parse
{
	# Attempt to detect MAC addresses (only), and convert them.
	#
	# No arguments
	OUTPUT=''

	while IFS='' read -d '\n' -n1 chr
	do
		if [[ $chr =~ [$IFS] ]]
		then
			if is_macaddr "$token"
			then
				convert "$token"
				(( $ONLY_MATCHING )) || echo
			elif (( $ONLY_MATCHING ))
			then
				printf "$token"
			fi
			(( $ONLY_MATCHING )) && printf "$chr"
			token=''
			continue
		fi
		token+=$chr
	done
}

################################# Get Options #################################

SHIFT=0

while getopts "aAbBcClLnNoOpPsSwW" OPTION
do
	let SHIFT+=1
	case "$OPTION" in
		a|A)
			AUTO_MODE=1
			;;
		b|B)
			FUNCT=to_binary
			;;
		c|C)
			FUNCT=to_cisco
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
		o|O)
			ONLY_MATCHING=0
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
		case_fnct() { tr 'a-z' 'A-Z' ; }
	else
		case_fnct() { tr 'A-Z' 'a-z' ; }
	fi
done

shift $SHIFT # Must be done outside of `while getopt` loop (or things break).

################################## Run Program ################################


if [[ ! -t 0 ]]
# STDIN not empty
then
	parse
fi

if [[ $# -gt 0 ]]
then
	echo $@ | parse
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
