package require rwlink

set hook_descriptor(tag)        rwurl
set hook_descriptor(function)   rweb_url
set hook_descriptor(descrip)    "Hook for rivetweb generated links"
set hook_descriptor(stage)      xmlpostproc

proc rweb_url {datasource tag element_text attribute_list} {

	set href [::rivetweb::composeUrl {*}$attribute_list]
    set d [dict create tagname a text $element_text attributes [dict create href $href]]

    return $d
}
