# -- siterefs
#
# transformation of canonical references of the website in valid URL to a page

set hook_descriptor(tag)        sitereference
set hook_descriptor(function)   sitereference
set hook_descriptor(descrip)    "link to other internal resource of the website"
set hook_descriptor(stage)      xmlpostproc

#proc sitereference {xmlDoc child} {
#
## internal references must be resolved before real html generation
##
## if we are running dynamic the uri is index.rvt?show=<page_ref> 
## if we are running static the uri is <page_ref>(.<lang>).html
#
#    if {[$child hasAttribute href]} {
#        set anchor_text [$child asText]
#
##           if { $::rivetweb::static_links } {
##               if {[string equal $page_ref index]} {
##                   set page_ref index.html
##               } else {
##                   set page_ref [file join $::rivetweb::static_path ${page_ref}.html]
##               }
##           } else {
##               set page_ref index.rvt?show=${page_ref}
##           }
#
#        $xmlDoc createTextNode $anchor_text new_anchor_txt
#        set newAnchorElement [$xmlDoc createElement a]
#        foreach refattr [$child attributes] {
#            set attvalue [$child getAttribute $refattr]
#            switch $refattr {
#                href {
#                    set attvalue [::rivetweb::makeUrl $attvalue]
#                }
#                default {
#                }
#            }
#            $newAnchorElement setAttribute $refattr $attvalue
#        }
#
#        $newAnchorElement appendChild $new_anchor_txt
#        [$child parentNode] replaceChild $newAnchorElement $child
#        $child delete
#    }
#}

proc sitereference { element_text attribute_list } {
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
