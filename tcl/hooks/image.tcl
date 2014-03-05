# -- image
#
# Transform 'image' tags into HTML img tags rewriting the image referenced
# in the src attribute into a valid path to the file.
#
#

set hook_descriptor(tag)        image
set hook_descriptor(function)   imagehandler
set hook_descriptor(descrip)    "handler per tag <image src=..... />"
set hook_descriptor(stage)      xmlpostproc

proc imagehandler { datasource tag element_text attribute_list } {

    set d [dict create]

    array set attributes $attribute_list
    if {[info exists attributes(src)]} {
        set attributes(src) [::rivetweb::makePictsPath $attributes(src) $::rivetweb::template_key]
    }

    dict set d attributes [array get attributes]
    dict set d tagname img
    return $d
}

