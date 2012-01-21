#
# $Id: rivet_page.tcl 2102 2011-12-15 12:01:09Z massimo.manghi $
#
#+
#
#-
#

if {[$::rivetweb::menusource has_updates]} {

    $::rivetweb::logger log notice "Recreating sitemap from menu data source"
    $::rivetweb::sitemap recreate
 
    $::rivetweb::menusource loadsitemap $::rivetweb::sitemap

}

# This code is running within the ::rivetweb namespace

if {[catch {
    set serialized_model [$::rivetweb::pmodel content \
                          $::rivetweb::current_pmodel $language]
} e]} {

    puts "error getting page content for language <b>$language</b>:\n <em>$e</em>\n$::rivetweb::current_pmodel"
    abort_page content_error

}

#puts "<pre>$serialized_model ([llength $serialized_model])</pre>"
array unset content_a
array set content_a $serialized_model

set page_xml $content_a(pagetext)

#parray_table content_a

#if {[dict keys $::rivetweb::hooks] > 0} {
#    set xmlpp [dict get $::rivetweb::hooks xmlpostproc]
#
#    foreach hk [dict keys $xmlpp] {
#        apache_log_error debug "processing hook: [dict get $xmlpp $hk descrip]"
#        set xmlprocessor [dict get $xmlpp $hk function]
#        foreach child [$page_xml getElementsByTagName $hk] {
#                   
#            eval $xmlprocessor $page_xml $child
#
#        }
#    }
#}

$::rivetweb::pmodel postproc_hooks $::rivetweb::current_pmodel $::rivetweb::hooks xmlpostproc $language

if {[isDebugging]} { puts "<pre>[escape_sgml_chars [$page_xml asXML]]</pre>" }

array unset page_menu

set menu_d [$::rivetweb::pmodel mdmodel $::rivetweb::current_pmodel menu]

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
                    [$::rivetweb::htmlizer html_menu        \
                                        $menuobj            \
                                        $language           \
                                        [dict get $::rivetweb::templates_db $template_key]]
    
    }

            
##### debug puts "<pre>[escape_sgml_chars $html_menu($pos)]</pre>"

}

apache_log_error debug "=====> menus: [array names html_menu]" 

if {[dict keys $::rivetweb::hooks] > 0} {
    set metadatapp [dict get $::rivetweb::hooks metadata]

    foreach hk [dict keys $metadatapp] {
        apache_log_error info "processing hook: [dict get $metadatapp $hk descrip]"
        set xmlprocessor [dict get $metadatapp $hk function]
                   
        $xmlprocessor $::rivetweb::current_pmodel 

    }
}

# we finally create HTML out of the xml page so far handled.

#if {[selectContent $page_xml $language content_selected]} {
#    array unset content
#    if {[makePageHTML $page_xml $content_selected content]} {
#        set page_content_html $content(pagetext)
#        set page_title        $content(title)
#        set page_headline     $content(headline)       
#    } else {
#        set page_content_html "Rivetweb internal error: could not create HTML from page data"
#        set page_headline     "Rivetweb error"
#        set page_title        "Rivetweb error"
#    }
#} else {
#    set page_content_html "no content found"
#}

# content and language had been already selected within the 
# ::rivetweb::pmodel page model manager

if {[makePageHTML $content_a(pagetext) page_content_html]} {

# we try to infer page headline and title from data available
# and store it in the content_a array.

    if {![info exists content_a(headline)] && [info exists content_a(title)]} {
        set content_a(headline) $content_a(title)
    } elseif {![info exists content_a(title)] && [info exists content_a(headline)]} {
        set content_a(title)  $content_a(headline)
    } elseif {![info exists content_a(title)] && ![info exists content_a(headline)]} {
        set content_a(title) $::rivetweb::page_content
        set content_a(headline) $::rivetweb::page_content
    }
    set page_title        $content_a(title)
    set page_headline     $content_a(headline)       
} else {
    set page_content_html "Rivetweb internal error: could not create HTML from page data"
    set page_headline     "Rivetweb error"
    set page_title        "Rivetweb error"
}

set page_authors [$::rivetweb::pmodel mdmodel $::rivetweb::current_pmodel author]

headers type "text/html; charset=$::rivetweb::http_encoding"

