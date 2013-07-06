# -- externref.tcl
#
# hook processing external references. Basically expands this tag to a
# anchor ('a') tag preserving its attributes
#

set hook_descriptor(tag)        externref
set hook_descriptor(function)   externref
set hook_descriptor(descrip)    "builds an ordinary link to an external resource"
set hook_descriptor(stage)      xmlpostproc

proc externref { datasource tag element_text attribute_list } {

    array set attributes $attribute_list

    if {[info exists attributes(alias)] && [$datasource get_alias $attributes(alias) aliasdef]} { 

        set attributes(href) $aliasdef
        unset attributes(alias)

        set attribute_list [array get attributes]
    }

    set d [dict create]

    dict set d text $element_text
    dict set d attributes [concat $attribute_list target _blank]
    dict set d tagname a

    return $d
}

