# -- photolink
#
# handler of a imagelink creating an HTML element with comment and links to 
# different resolutions
#
# <photolink src="foto.png" fullres="foto-big.png" />
#
# $Id: photolink.tcl 2104 2011-12-18 00:24:45Z massimo.manghi $
#

set hook_descriptor(tag)        photolink 
set hook_descriptor(function)   photolink
set hook_descriptor(descrip)    "manipolazione tag photolink per costruire album di foto"
set hook_descriptor(stage)      xmlpostproc

proc photolink { datasource tag element_text attribute_list} {

    set d [dict create]
    dict set d tagname img

    array set plattrs $attribute_list
    if {[info exists plattrs(src)]} {

        set plattrs(src) [::rivetweb::makePictsPath $plattrs(src) $::rivetweb::template_key]

        if {[info exists plattrs(fullres)]} {

            dict set d tagname a
            dict set d expansion [::rivet::xml "" [list img src $plattrs(src)]]
            set plattrs(href) [::rivetweb::makePictsPath $plattrs(fullres) $::rivetweb::template_key]
            unset plattrs(src)
            unset plattrs(fullres)

        }
    }

    dict set d text $element_text
    dict set d attributes [array get plattrs]

    return $d
}


