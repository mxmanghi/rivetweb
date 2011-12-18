# -- programlisting
#
# $Id: $

set hook_descriptor(tag)        programlisting
set hook_descriptor(function)   programlisting
set hook_descriptor(descrip)    "manipolazione tag pre inclusione testo preformattato (sorgenti)"


proc programlisting {xmlDoc child} {

    if {[$child hasAttribute src]} {

        set code_file   [$child getAttribute src]

        set code_fp     [open [file join $::rivetweb::static_pages $code_file] r]
        set code_text   [read $code_fp]
#debug      puts stderr "text in $code_file:\n $code_text"
#debug      puts "<pre>"
#debug      puts [escape_sgml_chars $code_text]
#debug      puts "</pre>"
        close $code_fp    

        $xmlDoc createTextNode $code_text newTextNode
        set newPreNode [$xmlDoc createElement pre]
        $newPreNode setAttribute class programlisting
        $newPreNode appendChild $newTextNode
        [$child parentNode] replaceChild $newPreNode $child
#debug      puts stderr "\[[clock format [clock seconds]]\] replacing $child with $newPreNode ([[$newPreNode parentNode] asText])"

    } else {
        set newPreNode [$xmlDoc createElement pre]
        $newPreNode setAttribute class programlisting

        foreach plChild [$child childNodes] {
            set nodeText [$plChild asXML -indent 2]

            regsub -all {(&lt;)} $nodeText "<" unescaped_text
            regsub -all {(&gt;)} $unescaped_text ">" unescaped_text

#debug          puts stderr "appending:\n $unescaped_text"
####            $xmlDoc createTextNode $nodeText newTextNode
            $xmlDoc createTextNode $unescaped_text newTextNode
            $newPreNode appendChild $newTextNode
        }
        [$child parentNode] replaceChild $newPreNode $child
    }
    $child delete

    return $xmlDoc
}
