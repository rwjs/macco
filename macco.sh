#!/bin/bash

################################# Set defaults ################################

FUNCT=to_linux
AUTO_FUNCT=to_cisco
AUTO_MODE=1
ONLY_MATCHING=0
case_fnct() { tr 'A-Z' 'a-z' ; }

############################### Create Help text ##############################

HELP="
Usage: [STDIN] | $0 [OPTIONS]... [MAC-ADDRESSES]...

	-a,-A	'Automatic' mode (depends on defaults defined in the script)
	-b,-B	Binary style
	-c	Cisco style ('maca.ddre.sses') - for newer Cisco IOS
	-C	Cisco style ('maca.ddre.sses') - for older Cisco IOS
	-h	Help - display brief help text and quit.
	-H	Help - display full help text and quit.
	-i,-I	Interface Lookup
	-l	Linux style - lowercase	('ma:ca:dd:re:ss:es')
	-L	Linux style - UPPERCASE	('MA:CA:DD:RE:SS:ES')
	-n	Naked style - lowercase	('macaddresses')
	-N	Naked style - UPPERCASE	('MACADDRESSES')
	-O,-o	Only print MAC addresses; similar to the -o flag in grep(1)
	-p	H(P) style - lowercase ('macadd-resses')
	-P	H(P) style - UPPERCASE ('MACADD-RESSES')
	-r,-R	ARP Lookup
	-s	Solaris style - lowercase ('50:1A:12:14:a:b')
	-S	Solaris style - UPPERCASE ('50:1A:12:15:A:B')
	-w	Windows style - lowercase ('ma-ca-dd-re-ss-es')
	-W	Windows style - UPPERCASE ('MA-CA-DD-RE-SS-ES')
	-x,-X	'Exclude' mode (filters out things like global broadcast)
"

# HELP2 - 'extended' help text

HELP2="
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
 - Interface Lookup (INT_LOOKUP) and ARP Lookup (ARP_LOOKUP) embeds the 
    converted addresses in various lookup commands (per the style used).
    NB: Both Lookup modes imply ONLY_MATCHING (-o).
 - The New/Old divide in Cisco/IOS affects whether 'show mac-address-table'
    (old) or 'show mac address-table' (new) is used. It only matters if 
    INT_LOOKUP (-m|-M) is used.
 - Exclude mode current filters 00:00:00:00:00:00 and FF:FF:FF:FF:FF:FF.
    More (or custom) filters might be added in future versions.
"

######################### Define Conversion Functions #########################

function to_cisco
{
	# Cisco-style: maca.ddre.sses (always lowercase)
	sed 's/..../\L&\./g;s/\.$//'
}

function to_linux
{
	# Linux-style: ma:ca:dd:re:ss:es
	sed 's/../&:/g;s/\:$//' | case_fnct
}

function to_hp
{
	# HP-style: macadd-resses
	sed 's/....../&-/g;s/\-$//' | case_fnct
}

function to_windows
{
	# Windows-style: MA-CA-DD-RE-SS-ES
	sed 's/../&-/g;s/\-$//' | case_fnct
}

function to_naked
{
	# Naked-style: macaddresses / MACADDRESSES
	tr -d '\:\-\.' | case_fnct
}

function to_solaris
{
	sed 's/../:&/g;s/:0/:/g;s/^://' | case_fnct
}

function to_binary
{
	bc <<< "obase=2; ibase=16; $(cat - | to_naked | tr [a-z] [A-Z])" | zfill 48
}

######################### Define ARP_LOOKUP Functions #########################

function arp_cisco
{
	# Cisco ARP lookup:` show ip arp maca.ddre.sses`
	to_cisco | sed 's/^/show ip arp /'
}

function arp_linux
{
	# Linux ARP lookup: `arp -n | grep ma:ca:dd:re:ss:es`
	to_linux | sed 's/^/arp -n | grep /'
}

function arp_windows
{
	# Windows ARP lookup: `arp -a | findstr MA-CA-DD-RE-SS-ES`
	to_windows | sed 's/^/arp -a | findstr /'
}

######################### Define INT_LOOKUP Functions #########################

function int_cisco
{
	# Cisco INT lookup: 'show mac[- ]address-table maca.ddre.sses | include /'

	if (( NEW_CISCO ))
	then
		to_cisco | sed 's/.*/show mac address-table address & | include \//'
	else
		to_cisco | sed 's/.*/show mac-address-table address & | include \//'
	fi
}

function int_linux
{
	# Linux INT lookup: `arp -n | grep ma:ca:dd:re:ss:es`
	to_linux | sed 's/^/arp -n | grep /'
}

function int_windows
{
	# Windows INT lookup: `arp -a | findstr MA-CA-DD-RE-SS-ES`
	to_windows | sed 's/^/arp -a | findstr /'
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
		echo "$@" | tr '[a-f]' '[A-F]'
	}
	ref="$(normalise $1)"
	shift
	for x in "$@"
	do
		[[ "$ref" != "$(normalise $x)" ]] && return 1
	done
	return 0
}

function is_excludeable
{
	naked=$(echo $1 | to_naked)
	[[ "$naked" == 000000000000 ]] && return 0
	[[ "$naked" == ffffffffffff ]] && return 0
	[[ "$naked" == FFFFFFFFFFFF ]] && return 0
	return 1
}


function parse
{
	# Attempt to detect MAC addresses (only), and convert them.
	#
	# No arguments. Reads STDIN
	#
	# The following assumes hexadecimal digits (optionally) separated by 
	#  *regular* arbitrary separators. 

	delim_chr=''
	delim_cnt=0
	cnt=0
	token=''

	function is_complete_mac
	{
		# Check if the supplied token constitutes a complete MAC address
		#
		# $1 - token
		# $2 - delim_cnt

		if [[ $2 -eq 0 ]] && [[ ${#1} -eq 12 ]]
		then
			return
		elif [[ ${#1} -eq $[ 11 + 12 / $[ $2 - 1 ] ] ]]
		then
			return
		else
			return 1
		fi
	}

	while IFS='' read -d '\n' -n1 chr	# get one character from STDIN and assign to $chr
	do
		if [[ ! "$chr" =~ [0-9a-fA-F] ]] && is_complete_mac "$token" "$delim_cnt"
		then
			convtoken=$(echo "$token" | to_naked | $FUNCT)

			unset delim_chr
			delim_cnt=0
			cnt=0

			# Exclude mode logic
			(( $EXCLUDE )) && $(is_excludeable "$convtoken") && unset convtoken token && continue

			# Auto function logic
			if (( $AUTO_MODE )) && $(is_equiv "$convtoken" "$token")
			then
				convtoken=$(echo "$token" | to_naked | $AUTO_FUNCT)
			fi

			(( $ONLY_MATCHING )) && echo "$convtoken" || echo -n "$convtoken$chr"

			unset convtoken token
			continue

		elif [[ "$chr" =~ [a-fA-F0-9] ]] 	# if chr is a hexadecimal digit
		then
			let cnt+=1
			token="${token}${chr}"

		elif [[ -z "$delim_chr" && $cnt -gt 0 && $cnt -le 6 ]] 
		then
			# set the delim_chr
			let cnt+=1
			delim_chr=$chr
			delim_cnt=$cnt
			token="${token}${chr}"
			continue

		elif [[ $delim_cnt -gt 0 ]] && [[ $[ ($cnt + 1) % $delim_cnt ] -eq 0 ]] && [[ "$chr" == "$delim_chr" ]] 	
		then
			# delim_chr regular repeat detected
			token="${token}${chr}"
			let cnt+=1
			continue
		else
			# the delim is not regular or consistent - not a MAC address
			(( $ONLY_MATCHING )) || printf -- "${token}${chr}"
			token=''
			delim_chr=''
			delim_cnt=0
			cnt=0
		fi

	done
}

################################# Get Options #################################

SHIFT=0

while getopts "aAbBcChHiIlLnNoOpPrRsSwWxX" OPTION
do
	let SHIFT+=1
	case "$OPTION" in

		#### 'Style' options ####

		b|B)
			FUNCT=to_binary
			AUTO_MODE=0
			;;
		c|C)
			FUNCT=to_cisco
			[[ $OPTION == c ]] && NEW_CISCO=1 || NEW_CISCO=0
			# old cisco is `mac-address-table`, new cisco is `mac address-table`
			AUTO_MODE=0
			;;
		l|L)
			FUNCT=to_linux
			AUTO_MODE=0
			;;
		n|N)
			FUNCT=to_naked
			AUTO_MODE=0
			;;
		p|P)
			FUNCT=to_hp
			AUTO_MODE=0
			;;
		s|S)
			FUNCT=to_solaris
			AUTO_MODE=0
			;;
		w|W)
			FUNCT=to_windows
			AUTO_MODE=0
			;;
		i|I)
			INT_LOOKUP=1
			;;
		r|R)
			ARP_LOOKUP=1
			;;

		## 'Normal' options
		# Please use continue/exit/break in the following when adding more options

		a|A)
			AUTO_MODE=1
			continue
			;;
		h)
			echo -e "$HELP"
			exit 0
			;;
		H)
			echo -e "$HELP$HELP2"
			exit 0
			;;
		o|O)
			ONLY_MATCHING=1
			continue
			;;
		x|X)
			EXCLUDE=1
			continue
			;;
		--)
			break
			;;
		?)
			echo "$HELP" >&2
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

####################### Bind lookup functions per style #######################

if (( ARP_LOOKUP ))
then
	ONLY_MATCHING=1
	ORIG_FUNCT="$FUNCT"
	(( INT_LOOKUP )) && { echo "ARP_LOOKUP (-r|-R) and INT_LOOKUP (-i|-I) are mutually exclusive!" >&2 ; exit 1 ; }
	[[ $FUNCT == to_cisco ]] && FUNCT='arp_cisco'
	[[ $FUNCT == to_linux ]] && FUNCT='arp_linux'
	[[ $FUNCT == to_windows ]] && FUNCT='arp_windows'
fi

if (( INT_LOOKUP ))
then
	ONLY_MATCHING=1
	ORIG_FUNCT="$FUNCT"
	[[ $FUNCT == to_cisco ]] && FUNCT='int_cisco'
	[[ $FUNCT == to_linux ]] && FUNCT='int_linux'
	[[ $FUNCT == to_windows ]] && FUNCT='int_windows'
fi

################################# Run Program #################################


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
	[[ -n $ORIG_FUNCT ]] && FUNCT="$ORIG_FUNCT"
	ip link | awk '/LOOPBACK/ {getline;next} {printf $2 "\t";getline;print $2}' | while read iface mac
	do
		[[ -n "$mac" ]] && echo -e "$iface\t$(echo -e "$mac" | parse)"
	done
fi
