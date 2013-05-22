# -- localref
#
# hook per 

set hook_descriptor(tag)        localref
set hook_descriptor(function)   localref
set hook_descriptor(descrip)    "link to local static resources"
set hook_descriptor(stage)      xmlpostproc

proc localref {element_text attribute_list} {

    set d [dict create]
    array set attributes $attribute_list
    if {[info exists attributes(href)]} {   
        set attributes(href) [join [list $::rivetweb::local_pages $attributes(href)] "/"]
    } elseif {[info exists attributes(src)]} {
        set attributes(src) [join [list $::rivetweb::local_pages $attributes(src)] "/"]
    }
    dict set d text $element_text
    dict set d tagname a
    dict set d attributes [array get attributes]
    return $d
}

