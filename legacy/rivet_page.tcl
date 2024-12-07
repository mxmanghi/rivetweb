# 
# -- rivet_page
# 
# various stuff here to prepare the actual page generation.
#
# First of all we have to determine which menus have to be displayed in this
# context. Let's check to see if the sitemap has to be updated
#

# This code is running within the ::rivetweb namespace, but we keep to 
# fully qualify variables so to make explicit their role of status variables
# in the request processing

# we run metadata hooks for variable that have to be extracted to control the
# display of our template

$::rivetweb::current_pmodel metadata_hooks $::rivetweb::hooks

if {[isDebugging]} { puts "<pre>[escape_sgml_chars [$page_xml asXML]]</pre>" }

apache_log_error notice "-> $::rivetweb::current_pmodel"

catch {unset ::rivetweb::pagemenus}
set ::rivetweb::pagemenus [dict create]

foreach ds $::rivetweb::datasources {

#   lappend ::rivetweb::pagemenus [$ds menu_list $::rivetweb::current_pmodel]

    set dsmenu [$ds menu_list $::rivetweb::current_pmodel]
    foreach k [dict keys $dsmenu] {
        dict append ::rivetweb::pagemenus $k [dict get $dsmenu $k]
    }
}

if {[catch {

   $::rivetweb::current_pmodel postproc_hooks  $::rivetweb::hooks   \
                                                xmlpostproc         \
                                                $language

} e]} {

    $::rivetweb::logger log err "Error processing data for page ($e)"


    if {![$::rivetweb::rwebdb check postproc_hook_error]} {
        set pobj [::rwpage::RWStatic ::#auto postproc_hook_error]
        $pobj set_pagetext $::rivetweb::default_lang "Error in page postprocessing"
        $pobj add_metadata header "Postprocessing error"
        $pobj add_metadata title  "Postprocessing error"
        $::rivetweb::rwebdb store postproc_hook_error $pobj ""
    } else {

        set pobj [$::rivetweb::rwebdb fetch postproc_hook_error]
        set ::rivetweb::current_pmodel $pobj

    }
}

headers type "text/html; charset=$::rivetweb::http_encoding"

