# -- localref
#
# hook per 

package require rwlink

set hook_descriptor(tag)        localref
set hook_descriptor(function)   localref
set hook_descriptor(descrip)    "link to local static resources"
set hook_descriptor(stage)      xmlpostproc

proc localref {datasource tag element_text attribute_list} {

    set d [dict create]
    array set attributes $attribute_list
    set text_dict [dict create $::rivetweb::default_lang $element_text]

    if {[info exists attributes(alias)] && [$datasource get_alias $attributes(alias) aliasdef]} { 

        set lm [$::rivetweb::linkmodel create XMLBase $aliasdef $text_dict "" ""]
        unset attributes(alias)

    } elseif {[info exists attributes(href)]} {   

        set lm [$::rivetweb::linkmodel create XMLBase $attributes(href) $text_dict "" ""]

    } elseif {[info exists attributes(src)]} {

        set lm [$::rivetweb::linkmodel create XMLBase $attributes(src) $text_dict "" ""]

    }
    $::rivetweb::linkmodel set_attribute lm [concat [array get attributes] type local]

#   set     file_path           "/$::rivetweb::local_pages/$aliasdef"
#   set     attributes(href)    $file_path

    set transformed_link [$datasource to_url $lm]
    set attributes(href) [$::rivetweb::linkmodel get_attribute $transformed_link href]
    #::rivet::html [array get attributes] div b
    dict set d text $element_text
    dict set d tagname a
    dict set d attributes [array get attributes]
    return $d
}

