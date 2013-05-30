#
# -- programlisting
#
# Replaces the occurrence of tags <programlisting>...</programlisting> with an element 
# <pre>...</pre> containing programlisting's text escaped
#

set hook_descriptor(tag)        programlisting
set hook_descriptor(function)   programlisting
set hook_descriptor(descrip)    "manipolazione tag pre inclusione testo preformattato (sorgenti)"
set hook_descriptor(stage)      xmlpostproc
set hook_descriptor(textmode)   XML

proc programlisting { datasource element_text attribute_list} {

    set d [dict create]

    array set attributes $attribute_list

    if {![info exists attributes(class)]} {
        set attributes(class) programlisting
    }

    set code_text ""

    if {[info exists attributes(src)]} {

        set code_file [::rivetweb::searchPath $attributes(src) [list    $::rwdatas::static_pages    \
                                                                        $::rivetweb::local_pages    \
                                                                        $::rivetweb::site_base      \
                                                                        $::rivetweb::rivetweb_root]]

        if {[string length $code_file] && [file exists $code_file]} {

            set code_text [read_file $code_file]

        } else {

            set code_text ""

        }

        unset attributes(src)

    } else {

        set el_dom  [dom parse $element_text]
        set el_root [$el_dom documentElement]

        set el_text ""

        foreach c [$el_root childNodes] {

            append el_text [$c asXML -indent 2]

        }

        regsub -all {(&lt;)} $el_text "<" code_text
        regsub -all {(&gt;)} $code_text ">" code_text

        $el_dom delete
    }

    dict set d text $code_text
    dict set d attributes [array get attributes]
    dict set d tagname pre

    return $d
}

