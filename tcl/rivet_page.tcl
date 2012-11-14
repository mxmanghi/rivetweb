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

#if {[$::rivetweb::sitemap has_updates]} {
#
#    $::rivetweb::logger log notice "Recreating sitemap from menu data source"
#    $::rivetweb::sitemap recreate
#    $::rivetweb::sitemap sitemap_reload
#
#}

# we run metadata hooks for variable that have to be extracted to control the
# display of our template

$::rivetweb::pmodel metadata_hooks $::rivetweb::current_pmodel $::rivetweb::hooks

if {[isDebugging]} { puts "<pre>[escape_sgml_chars [$page_xml asXML]]</pre>" }

apache_log_error notice "-> $::rivetweb::current_pmodel"
catch {unset menu_d}
set menu_d [dict create]

foreach ds $::rivetweb::datasources {

#   lappend menu_d [$ds menu_list $::rivetweb::current_pmodel]

    set dsmenu [$ds menu_list $::rivetweb::current_pmodel]
    foreach k [dict keys $dsmenu] {
        dict append menu_d $k [dict get $dsmenu $k]
    }
}
#puts "<br><b>$menu_d</b>"
#### set menu_d [$::rivetweb::pmodel metadata $::rivetweb::current_pmodel menu]

# menu_d is actually a dictionary, but a simple one which lists
# pairs of (position-menu_id)

#array unset page_menu
#while {[llength $menu_d]} {
#    set menu_d [lassign $menu_d pos menuid]
#    lappend page_menu($pos) $menuid
#    puts $menu_d
##}

#foreach {pos menuid} $menu_d {
#    lappend page_menu($pos) [dict get $menu_d $pos]
#}

#parray page_menu

# html for the menus will go in this array


#apache_log_error info "menus for '$page_key': $menu_d"

array unset html_menu
foreach pos [dict keys $menu_d] {
    array unset menu_a {}
#   set menus [$::rivetweb::sitemap menu_list [dict get $menu_d $pos]]

#   puts "<pre>--->$pos [dict get $menu_d $pos]</pre>"
#   puts "<pre>$menus</pre>"

    set menus [dict get $menu_d $pos]
    foreach menuobj $menus {

        append html_menu($pos)                          \
            [$::rivetweb::htmlizer  html_menu           \
                                    $menuobj            \
                                    $language           \
                                    [dict get $::rivetweb::templates_db $template_key]]

    }

#   puts "<pre>[escape_sgml_chars $html_menu($pos)]</pre>"

}

apache_log_error debug "=====> menus: [array names html_menu]" 

if {[catch {

    $::rivetweb::current_pmodel postproc_hooks  $::rivetweb::hooks          \
                                                xmlpostproc                 \
                                                $language

# we finally create HTML out of the xml page so far handled.

## content and language had been already selected within the 
## ::rivetweb::pmodel page model manager

##    set page_vars [$::rivetweb::current_pmodel content $language -xml]
##
##    set page_title          [dict get $page_vars title]
##    set page_headline       [dict get $page_vars headline]
##    set page_content_html   [dict get $page_vars pagetext]
##
##   set page_authors [$::rivetweb::pmodel metadata $::rivetweb::current_pmodel author]
##
##    puts "<b>$::rivetweb::current_pmodel</b>"

} e]} {

    $::rivetweb::logger log err "Error processing data for page ($e)"

    set pobj [$::rivetweb::pmodel create]
    $::rivetweb::pmodel put_metadata pobj                       \
                [list   title   "Error processing XHTML data "  \
                        menu    [list left main]                \
                        header  "Error processing XHTML data "]

    $::rivetweb::pmodel set_pagetext pobj $::rivetweb::default_lang "Error creating page<br/><pre>$e</pre>"

# we must assume this is going to be ok...

    set page_vars [$::rivetweb::pmodel content $pobj $language -xml]

    set page_title          [dict get $page_vars title]
    set page_headline       [dict get $page_vars headline]
    set page_content_html   [dict get $page_vars pagetext]

    set page_authors [$::rivetweb::pmodel metadata $::rivetweb::current_pmodel author]
}

headers type "text/html; charset=$::rivetweb::http_encoding"

