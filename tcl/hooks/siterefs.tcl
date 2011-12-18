# -- siterefs
#
# $Id: $

set hook_descriptor(tag)        sitereference
set hook_descriptor(function)   sitereference
set hook_descriptor(descrip)    "link to other internal resource of the website"


proc sitereference {xmlDoc child} {

# internal references must be resolved before real html generation
#
# if we are running dynamic the uri is index.rvt?show=<page_ref> 
# if we are running static the uri is <page_ref>(.<lang>).html

    if {[$child hasAttribute href]} {
#       set page_ref    [$child getAttribute href]
        set anchor_text [$child asText]

#           if { $::rivetweb::static_links } {
#               if {[string equal $page_ref index]} {
#                   set page_ref index.html
#               } else {
#                   set page_ref [file join $::rivetweb::static_path ${page_ref}.html]
#               }
#           } else {
#               set page_ref index.rvt?show=${page_ref}
#           }

        $xmlDoc createTextNode $anchor_text new_anchor_txt
        set newAnchorElement [$xmlDoc createElement a]
        foreach refattr [$child attributes] {
            set attvalue [$child getAttribute $refattr]
            switch $refattr {
                href {
                    set attvalue [::rivetweb::makeUrl $attvalue]
                }
                default {
                }
            }
            $newAnchorElement setAttribute $refattr $attvalue
        }

#           $newAnchorElement setAttribute href [makeUrl $page_ref]
        $newAnchorElement appendChild $new_anchor_txt
        [$child parentNode] replaceChild $newAnchorElement $child
        $child delete
    }
}
