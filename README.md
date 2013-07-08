NAME
======

MACCo - MAC COnverter

SYNOPSIS:
======

[STDIN] | macco.sh [OPTIONS]... [MAC-ADDRESSES]...

DESCRIPTION
=====

MACCo is a script for translating MAC addresses between various vendors' formats.

The motivation for this script is similar to my earlier project'ciscom' ([CISCO M]ac converter), but is a different project due to the change in scope (ie, it supports more vendors than just Cisco).

This script is largely useful for converting MAC addresses so that they can be used in regexps - eg, Cisco's 'show mac-address-table | i maca.ddre.sses'.

OPTIONS:
=====

	-a,-A   'Automatic' mode (depends on defaults defined in the script)
	-b,-B   Binary style
	-c      Cisco style ('maca.ddre.sses') - for newer Cisco IOS
	-C      Cisco style ('maca.ddre.sses') - for older Cisco IOS
	-h      Help - display brief help text and quit.
	-H      Help - display full help text and quit.
	-i,-I   Interface Lookup
	-l      Linux style - lowercase ('ma:ca:dd:re:ss:es')
	-L      Linux style - UPPERCASE ('MA:CA:DD:RE:SS:ES')
	-n      Naked style - lowercase ('macaddresses')
	-N      Naked style - UPPERCASE ('MACADDRESSES')
	-O,-o   Only print MAC addresses; similar to the -o flag in grep(1)
	-p      H(P) style - lowercase ('macadd-resses')
	-P      H(P) style - UPPERCASE ('MACADD-RESSES')
	-r,-R   ARP Lookup
	-s      Solaris style - lowercase ('50:1A:12:14:a:b')
	-S      Solaris style - UPPERCASE ('50:1A:12:15:A:B')
	-w      Windows style - lowercase ('ma-ca-dd-re-ss-es')
	-W      Windows style - UPPERCASE ('MA-CA-DD-RE-SS-ES')
	-x,-X   'Exclude' mode (filters out things like global broadcast)

NOTES
======

 - Automatic Mode converts to the 'default' format (as defined by FUNCT). If the supplied MAC is already in that format, it is converted to the 'automatic' format (defined by AUTO_FUNCT)
 - MAC address(es) can be supplied by STDIN, and/or script arguments. If both STDIN and arguments are supplied, STDIN is processed first.
 - Input from STDIN will be parsed for MAC addresses (that is, the script will make an effort to only convert tokens which look like MAC addresses whilst passing through all other input).
 - If no MAC addresses are supplied, all system MAC addresses (excluding loopback) are displayed.
 - Interface Lookup (INT_LOOKUP) and ARP Lookup (ARP_LOOKUP) embeds the converted addresses in various lookup commands (per the style used). NB: Both Lookup modes imply ONLY_MATCHING (-o).
 - The New/Old divide in Cisco/IOS affects whether 'show mac-address-table' (old) or 'show mac address-table' (new) is used. It only matters if INT_LOOKUP (-m|-M) is used.
 - Exclude mode current filters 00:00:00:00:00:00 and FF:FF:FF:FF:FF:FF. 


AUTHOR
======

Written by Robert W.J. Stewart

TODO
======

 - Add interface/ARP support for more vendors (Juniper NetScreen/JunOS, HP, etc)
 - Add support for custom MAC filters with -x
