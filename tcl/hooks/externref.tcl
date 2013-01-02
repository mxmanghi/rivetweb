# -- externref.tcl
#
#

set hook_descriptor(tag)        externref
set hook_descriptor(function)   externref
set hook_descriptor(descrip)    "builds an ordinary link to an external resource"
set hook_descriptor(stage)      xmlpostproc

proc externref {element_text attribute_list} {

    set d [dict create]

    dict set d text $element_text
    dict set d attributes [concat $attribute_list target _blank]
    dict set d tagname a

    return $d
}

