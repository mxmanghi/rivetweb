# -- siterefs
#
# transform of canonical references of the website in valid URL to a page
#
#

set hook_descriptor(tag)        sitereference
set hook_descriptor(function)   sitereference
set hook_descriptor(descrip)    "link to other internal resource of the website"
set hook_descriptor(stage)      xmlpostproc

proc sitereference { datasource element_text attribute_list } {
    set new_attributes {}
    foreach {attr attrval} $attribute_list {
        switch $attr {
            href {
                lappend new_attributes $attr [::rivetweb::makeUrl $attrval]
            }
            default {
                lappend new_attributes $attr $attrval
            }
        }
    }

    set d [dict create]
    dict set d text $element_text
    dict set d attributes $new_attributes
    dict set d tagname a
    return $d
}
