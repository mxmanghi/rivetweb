# -- localref
#
#

#set hook_descriptor(tag)        localref
#set hook_descriptor(function)   localref
#set hook_descriptor(descrip)    "link to local static resources"
#set hook_descriptor(stage)      xmlpostproc

proc localref {domDoc child} {

    if {[$child hasAttribute href]} {
        set page_ref    [$child getAttribute href]
        set anchor_text [$child asText]

        $domDoc createTextNode $anchor_text new_anchor_txt
        set newAnchorElement [$domDoc createElement a]

        $newAnchorElement setAttribute href $page_ref
        $newAnchorElement appendChild $new_anchor_txt
        [$child parentNode] replaceChild $newAnchorElement $child
        $child delete
    }
}
