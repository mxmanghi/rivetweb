# -- externref.tcl
#
#

set hook_descriptor(tag)        externref
set hook_descriptor(function)   externref
set hook_descriptor(descrip)    "builds an ordinary link to an external resource"
set hook_descriptor(stage)      xmlpostproc

proc externref {domDoc child} {
    
    if {[$child hasAttribute href]} {
        set anchor_text [$child asText]

        $domDoc createTextNode $anchor_text new_anchor_txt
        set newAnchorElement [$domDoc createElement a]
        foreach refattr [$child attributes] {
            set attvalue [$child getAttribute $refattr]
            $newAnchorElement setAttribute $refattr $attvalue
        }
        $newAnchorElement setAttribute target _blank 

        $newAnchorElement appendChild $new_anchor_txt
        [$child parentNode] replaceChild $newAnchorElement $child
        $child delete     
    }

    return $domDoc
}
