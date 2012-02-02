# -- ident
# 
# manipulation of the 'ident' element in a page DOM. This metadata hook should
# detect a subversion style Id, extract the timestamp from it and store it in
# the ::rivetweb::last_modified variable.
#
#

set hook_descriptor(tag)        ident
set hook_descriptor(function)   extract_ident
set hook_descriptor(descrip)    "extract information from 'ident' metatada element"
set hook_descriptor(stage)      metadata

proc extract_ident {pmodel} {

    set ident [$::rivetweb::pmodel metadata $pmodel ident]

    if {[regexp {\$Id:\s+[-\w]+\.xml\s+\d*\s+(.*Z)\s+([\.\w]*)\s+\$} $ident match last_modified committer]} {

        $::rivetweb::logger log debug "'Id' matched\n Last Modification: $last_modified" 
        set ::rivetweb::last_modified [clock format [clock scan $last_modified -gmt 1] -format "%d-%m-%Y %H:%M:%S" -gmt 1]

    } else {
    
        $::rivetweb::logger log debug "'Id' did not match" 
        set ::rivetweb::last_modified ""

# we couldn't match the subversion Id, so we store the content of this
# element in a ::rivetweb::ident variable anyway

        set ::rivetweb::ident $ident

    }

    return $pmodel
}
