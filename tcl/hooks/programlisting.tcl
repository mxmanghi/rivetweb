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

proc programlisting {xmlDoc child} {

    if {[$child hasAttribute src]} {

        set code_file   [$child getAttribute src]

        set code_file   [::rivetweb::searchPath $code_file [list $::rivetweb::static_pages \
                                                                 $::rivetweb::site_base    \
                                                                 $::rivetweb::rivetweb_root]]

        if {[string length $code_file]} {

            set code_fp     [open $code_file r]
            set code_text   [read $code_fp]
#debug      apache_log_error debug "text in $code_file:\n $code_text"
#debug      apache_log_error debug [escape_sgml_chars $code_text]
            close $code_fp    

        } else {

            set code_text ""

        }

        $xmlDoc createTextNode $code_text newTextNode
        set newPreNode [$xmlDoc createElement pre]
        $newPreNode setAttribute class programlisting
        $newPreNode appendChild $newTextNode
        [$child parentNode] replaceChild $newPreNode $child
#debug  apache_log_error debug "replacing $child with $newPreNode ([[$newPreNode parentNode] asText])"

    } else {
        set newPreNode [$xmlDoc createElement pre]
        $newPreNode setAttribute class programlisting

        foreach plChild [$child childNodes] {
            set nodeText [$plChild asXML -indent 2]

            regsub -all {(&lt;)} $nodeText "<" unescaped_text
            regsub -all {(&gt;)} $unescaped_text ">" unescaped_text

#debug      apache_log_error err "appending:\n $unescaped_text"
            $xmlDoc createTextNode $unescaped_text newTextNode
            $newPreNode appendChild $newTextNode
        }
        [$child parentNode] replaceChild $newPreNode $child
    }
    $child delete

    return $xmlDoc
}
