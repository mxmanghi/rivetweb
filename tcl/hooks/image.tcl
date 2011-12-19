# -- image
#
# $Id: $
#

set hook_descriptor(tag)        image
set hook_descriptor(function)   imagehandler
set hook_descriptor(descrip)    "handler per tag <image src=..... />"
set hook_descriptor(stage)      xmlpostproc

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
