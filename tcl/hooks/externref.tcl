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

#proc externref {domDoc child} {
#    
#    if {[$child hasAttribute href]} {
#        set anchor_text [$child asText]
#
#        $domDoc createTextNode $anchor_text new_anchor_txt
#        set newAnchorElement [$domDoc createElement a]
#        foreach refattr [$child attributes] {
#            set attvalue [$child getAttribute $refattr]
#            $newAnchorElement setAttribute $refattr $attvalue
#        }
#        $newAnchorElement setAttribute target _blank 
#
#        $newAnchorElement appendChild $new_anchor_txt
#        [$child parentNode] replaceChild $newAnchorElement $child
#        $child delete     
#    }
#
#    return $domDoc
#}
