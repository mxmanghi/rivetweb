# -- calendar
#
# Realizzato per il sito del Master, potrebbe diventare una base per
# costruire dei blog
#
#

package require tdom

set hook_descriptor(tag)        calendar
set hook_descriptor(function)   expandcalendar
set hook_descriptor(descrip)    "handler per tag <calendar>...</calendar>"
set hook_descriptor(stage)      xmlpostproc
set hook_descriptor(textmode)   XML

proc listaPunti {punti} {

    set puntitxt "<ul>"

    foreach punto [$punti childNodes] {
        append puntitxt "<li>"
        foreach subel [$punto childNodes] {
#           puts "subel -> [$subel asXML]"
            switch [$subel nodeName] {
                #text {
                    append puntitxt [string trim [$subel nodeValue]]
                }
                docente {
                    append puntitxt "<strong class=\"docbox\">([$subel text])</strong>"
                }
            }
        }
        append puntitxt "</li>\n"
    }

    append puntitxt "</ul>"
    return $puntitxt
}


proc expandcalendar {element_xml attribute_list} {

    set d [dict create]
    dict set d expansion "<b>error</b>"
    dict set d tagname div
    dict set d attributes {}

    if {[ catch {
            set pagedom [dom parse $element_xml]
            set domroot [$pagedom documentElement]
            set xmltext "<div>"

            foreach calentry [$domroot getElementsByTagName calentry] {

                append xmltext "<div class=\"calentry\">"

# cerchiamo l'header della calendar entry

                set calheader [$calentry getElementsByTagName calheader]
#               puts "calheader ->> [$calheader asXML]"
                append xmltext "<div class=\"calheader\">"
                array unset calheader_a
                foreach calhdr [$calheader childNodes] {
                    set calheader_a([$calhdr nodeName]) [$calhdr text]
                }

                if {[info exists calheader_a(date)]} {
                    append xmltext "<span class=\"caldate\">$calheader_a(date)</span>"
                }
                if {[info exists calheader_a(sede)]} {
                    append xmltext "<span class=\"sede\">$calheader_a(sede)</span>"
                }
                if {[info exists calheader_a(docenti)]} {
                    append xmltext \
                        "<div class=\"docenti\">Docenti Responsabili: <strong>$calheader_a(docenti)</strong></div>"
                }
                append xmltext "</div><!-- calheader -->\n"

                append xmltext "<div class=\"programma\">"
                set programma [$calentry getElementsByTagName programma]
                foreach pgmel [$programma childNodes] {
                    switch [$pgmel nodeName] {
                        #text {
                            append xmltext "<p>[$pgmel nodeValue]</p>"
                        }
                        punti {
                            append xmltext [listaPunti $pgmel]
                        }
                        default {
                            append xmltext [$pgmel asXML]
                        }
                    }
                }
                append xmltext "</div><!-- programma -->"
                append xmltext "</div><!-- calentry -->\n"
            }
        } e]} {
        dict set d expansion "<pre>$e</pre>"
    } 

    dict set d expansion "$xmltext</div>"
    return $d
}

