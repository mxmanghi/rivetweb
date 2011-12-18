# -- image
#
# $Id: $
#

set hook_descriptor(tag)        image
set hook_descriptor(function)   imagehandler
set hook_descriptor(descrip)    "handler per tag <image src=..... />"

#proc imagehandler {xmlDoc} {
#
#    foreach child [$xmlDoc getElementsByTagName image] {
#        set newImgElement [$xmlDoc createElement img]
#        foreach imgatt [$child attributes] {
#            set attvalue [$child getAttribute $imgatt]
#            switch $imgatt {
#                src {
#                    set attvalue [makePictsPath $attvalue $::rivetweb::template_key]
#                }
#                default {
#                
#                }
#            }
#            $newImgElement setAttribute $imgatt $attvalue
#        }
#        [$child parentNode] replaceChild $newImgElement $child
#        $child delete
#    }
#
#    return $xmlDoc
#}

proc imagehandler {xmlDoc child} {

    set newImgElement [$xmlDoc createElement img]
    foreach imgatt [$child attributes] {
        set attvalue [$child getAttribute $imgatt]
        switch $imgatt {
            src {
                set attvalue [makePictsPath $attvalue $::rivetweb::template_key]
            }
            default {
            
            }
        }
        $newImgElement setAttribute $imgatt $attvalue
    }
    [$child parentNode] replaceChild $newImgElement $child
    $child delete

    return $xmlDoc
}
