# -- photolink
#
# handler of a imagelink creating an HTML element with comment and links to 
# different resolutions
#
# <photolink src="foto.png" fullres="foto-big.png" />
#
# $Id: photolink.tcl 2104 2011-12-18 00:24:45Z massimo.manghi $
#

set hook_descriptor(tag)        photolink 
set hook_descriptor(function)   photolink
set hook_descriptor(descrip)    "manipolazione tag photolink per costruire album di foto"
set hook_descriptor(stage)      xmlpostproc

proc photolink {xmlDoc child} {

    set newImgElement [$xmlDoc createElement img]
    set fullresImgEl ""

    foreach imgatt [$child attributes] { set plattrs($imgatt) [$child getAttribute $imgatt] }

    if {[info exists plattrs(src)]} then {
        set plattrs(src)
        $newImgElement setAttribute src [::rivetweb::makePictsPath $plattrs(src) $::rivetweb::template_key]
        if {[info exists plattrs(fullres)]} then {
            if {[info exists plattrs(download)] && ($plattrs(download) == 1) && ![var exists static]} then {

                set fullresImgEl [$xmlDoc createElement a]
                set download_args [join [list fname=$plattrs(fullres) function=$::rivetweb::download_proc] &]

                set fullresUrl   [makeurl [join [list index.rvt $download_args] ?]]

                apache_log_error debug "download path $fullresUrl"

                $fullresImgEl setAttribute href $fullresUrl
            } else {

                set fullresImgEl [$xmlDoc createElement a]
                set fullresUrl   [::rivetweb::makePictsPath $plattrs(fullres) $::rivetweb::template_key]
                $fullresImgEl setAttribute href $fullresUrl
            }
        }

        if {$fullresImgEl == ""} {
            set appendObj $newImgElement
        } else {
            $fullresImgEl appendChild $newImgElement
            set appendObj $fullresImgEl
        }

        [$child parentNode] replaceChild $appendObj $child
        $child delete
    } 

    return $xmlDoc
}
