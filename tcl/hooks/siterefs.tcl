# -- siterefs
#
# transform of canonical references of the website in valid URL to a page
#
#

set hook_descriptor(tag)        sitereference
set hook_descriptor(function)   sitereference
set hook_descriptor(descrip)    "link to other internal resource of the website"
set hook_descriptor(stage)      xmlpostproc

proc sitereference { datasource tag element_text attribute_list } {

    set language $::rivetweb::default_lang
    array set attribs $attribute_list
    if {[info exists attribs(href)]} {
        set lm [$::rivetweb::linkmodel create XMLBase $attribs(href) \
                                       [dict create language $element_text] "" ""]       
        unset attribs(href)
        $::rivetweb::linkmodel set_attribute lm [concat [array get attribs]]
        $::rivetweb::linkmodel set_property lm type internal
        set translated_link [::rwdatas::${datasource}::to_url $lm]
        set attribs(href) [$::rivetweb::linkmodel get_attribute $translated_link href]

    }

    set d [dict create]
    dict set d text $element_text
    dict set d attributes [array get attribs]
    dict set d tagname a
    return $d
}
