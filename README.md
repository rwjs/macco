macco
======

MACCo ([MAC CO]nverter] is a script for translating MAC addresses between various formats. 

This script was based on 'ciscom' ([CISCO M]ac converter), but has changed names due to the change in scope (ie, it supports more vendors than just Cisco).

This script is largely useful for converting MAC addresses so that they can be used in regexps - eg, 'show mac-address-table | i maca.ddre.ss'.

USAGE:
======

Usage: [STDIN] | macco.sh [OPTIONS]... [MAC-ADDRESSES]...

        -a,-A   'Automatic' mode (depends on defaults defined in the script)
        -b,-B   Binary style  
        -c,-C   Cisco style ('maca.ddre.sses') (NB: always lowercase)
        -h,-H   Help - display this text and quit.
        -l      Linux style - lowercase ('ma:ca:dd:re:ss:es')
        -L      Linux style - uppercase ('MA:CA:DD:RE:SS:ES')
        -n      Naked style - lowercase ('macaddresses')
        -N      Naked style - uppercase ('MACADDRESSES')
        -p      H(P) style - lowercase ('macadd-resses')
	-P	H(P) style - uppercase ('MACADD-RESSES')
        -w      Windows style - lowercase ('ma-ca-dd-re-ss-es')
        -W      Windows style - uppercase ('MA-CA-DD-RE-SS-ES')

NOTES
======

 - Automatic Mode converts MACs to the default format (as defined by "FUNCT"). If the supplied MAC is already in that format, it is converted to the 'automatic' format (as defined by "AUTO_FUNCT").
 - MAC address(es) can be supplied by STDIN, and/or script arguments. If both STDIN and arguments are supplied, STDIN is processed first.
 - If no MAC addresses are supplied, all system MAC addresses (excluding loopback) are displayed.

TODO
======

 - Add support for Solaris-style (`0:1:a:2:b:3` -> `00:01:0a:02:0b:03`)
 - Add input verification (possibly allowing for automatic detection and conversion of MAC addresses within larger text)
