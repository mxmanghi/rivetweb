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

if {[$::rivetweb::sitemap has_updates]} {

    $::rivetweb::logger log notice "Recreating sitemap from menu data source"
    $::rivetweb::sitemap recreate
 
#   $::rivetweb::menusource loadsitemap $::rivetweb::sitemap

    $::rivetweb::sitemap sitemap_reload

}

# we run metadata hooks for variable that have to be extracted to control the
# display of our template

$::rivetweb::pmodel metadata_hooks  $::rivetweb::current_pmodel \
                                    $::rivetweb::hooks

if {[isDebugging]} { puts "<pre>[escape_sgml_chars [$page_xml asXML]]</pre>" }

array unset page_menu

set menu_d [$::rivetweb::pmodel metadata $::rivetweb::current_pmodel menu]

# menu_d is actually a dictionary, but a simple one which lists
# pairs of (position-menu_id)

foreach {pos menuid} $menu_d {
    lappend page_menu($pos) [dict get $menu_d $pos]
}

# html for the menus will go in this array

array unset html_menu

foreach pos [dict keys $menu_d] {
    array unset menu_a {}
    set menus [$::rivetweb::sitemap menu_list [dict get $menu_d $pos]]

#   puts "<pre>--->$pos [dict get $menu_d $pos] $menu_list</pre>"
#   puts "\n $n_menus \n"

    foreach menuobj $menus {

            append html_menu($pos)                          \
                    [$::rivetweb::htmlizer  html_menu       \
                                            $menuobj        \
                                            $language       \
                                            [dict get $::rivetweb::templates_db $template_key]]

    }

##### debug puts "<pre>[escape_sgml_chars $html_menu($pos)]</pre>"

}

apache_log_error debug "=====> menus: [array names html_menu]" 

if {[catch {

    $::rivetweb::pmodel postproc_hooks  $::rivetweb::current_pmodel \
                                        $::rivetweb::hooks          \
                                        xmlpostproc                 \
                                        $language

# we finally create HTML out of the xml page so far handled.

# content and language had been already selected within the 
# ::rivetweb::pmodel page model manager

    set page_vars [$::rivetweb::pmodel content $::rivetweb::current_pmodel $language -xml]

    set page_title [dict get $page_vars title]
    set page_headline [dict get $page_vars headline]
    set page_content_html [dict get $page_vars pagetext]

    set page_authors [$::rivetweb::pmodel metadata $::rivetweb::current_pmodel author]

} e]} {

    $::rivetweb::logger log err "Error processing data for page ($e)"

    set pobj [$::rivetweb::pmodel create]
    $::rivetweb::pmodel put_metadata pobj           \
                [list   title   "Error processing XHTML data " \
                        menu    [list left main]    \
                        header  "Error processing XHTML data "]
    $::rivetweb::pmodel set_pagetext pobj $::rivetweb::default_lang "Error creating page<br/><pre>$e</pre>"

# we must assume this is going to be ok...

    set page_vars [$::rivetweb::pmodel content $pobj $language -xml]

    set page_title [dict get $page_vars title]
    set page_headline [dict get $page_vars headline]
    set page_content_html [dict get $page_vars pagetext]

    set page_authors [$::rivetweb::pmodel metadata $::rivetweb::current_pmodel author]
    
}

headers type "text/html; charset=$::rivetweb::http_encoding"

