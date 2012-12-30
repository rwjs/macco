NAME
======

MACCo - MAC COnverter

SYNOPSIS:
======

[STDIN] | macco.sh [OPTIONS]... [MAC-ADDRESSES]...

DESCRIPTION
=====

MACCo is a script for translating MAC addresses between various vendors' formats.

The motivation for this script is similar to that of 'ciscom' ([CISCO M]ac converter), but is a different project due to the change in scope (ie, it supports more vendors than just Cisco).

This script is largely useful for converting MAC addresses so that they can be used in regexps - eg, Cisco's 'show mac-address-table | i maca.ddre.sses'.

OPTIONS:
=====

	-a,-A	'Automatic' mode (depends on defaults defined in the script)
	-b,-B	Binary style
	-c,-C	Cisco style ('maca.ddre.sses') (NB: always lowercase)
	-h,-H	Help - display this text and quit.
	-l	Linux style - lowercase ('ma:ca:dd:re:ss:es')
	-L	Linux style - UPPERCASE ('MA:CA:DD:RE:SS:ES')
	-n	Naked style - lowercase ('macaddresses')
	-N	Naked style - UPPERCASE ('MACADDRESSES')
	-p	H(P) style - lowercase ('macadd-resses')
	-P	H(P) style - UPPERCASE ('MACADD-RESSES')
	-s	Solaris Style - lowercase ('50:1a:12:15:a:b')
	-S	Solaris Style - UPPERCASE ('50:1A:12:15:A:B')
	-w	Windows style - lowercase ('ma-ca-dd-re-ss-es')
	-W	Windows style - UPPERCASE ('MA-CA-DD-RE-SS-ES')

NOTES
======

 - Automatic Mode converts MACs to the default format (as defined by "FUNCT"). If the supplied MAC is already in that format (case-insensitive), it is converted to the 'automatic' format (as defined by "AUTO_FUNCT").
 - MAC address(es) can be supplied by STDIN, and/or script arguments. If both STDIN and arguments are supplied, STDIN is processed first.
 - Input from STDIN will be parsed for MAC addresses (that is, the script will make an effort to only convert tokens which look like MAC addresses whilst passing through all other input).
 - If no MAC addresses are supplied, all system MAC addresses (excluding loopback) are displayed.

AUTHOR
======

Written by Robert W.J. Stewart

TODO
======

 - Add case sensitivity for 'Automatic Mode' (ie, convert to the style defined by FUNCT instead of AUTO_FUNCT if the input MAC is not in FUNCT's forced case)
 - Optimise for speed (currently very slow on large inputs)
