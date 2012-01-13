#
# $Id: rivet_page.tcl 2102 2011-12-15 12:01:09Z massimo.manghi $
#
#+
#
#-
#

# This code is running within the ::rivetweb namespace

if {[var exists lang]} {
    set language [var get lang]
} else {
    set language $::rivetweb::default_lang
}

if {[var exists reset]} {

    set ::rivetweb::page_content	$::rivetweb::index

### set pagine($::rivetweb::index)	[::rivetweb::buildPage index]

    $::rivetweb::rwebdb erase
    $::rivetweb::rwebdb fetch $::rivetweb::index 

### array unset pagine
} 

# the central point is exactly here: we have to decide which page
# we have to display


if {[var exists show]} {
    set pagina [var get show]
    apache_log_error info "'$pagina' requested"

# if we are using cached content and requested page is cached we simply
# store in ::rivetweb::page_content

    set ::rivetweb::page_content $pagina
    if {[$::rivetweb::rwebdb check $pagina]} { 
        $::rivetweb::rwebdb dispose $pagina 
    }

    set ::rivetweb::current_pmodel [$::rivetweb::rwebdb fetch $pagina]

    apache_log_error info "[pid] page_content: $::rivetweb::page_content"

} else {

# Rivetweb assumes the default page is defined in the ::rivetweb::index variable

    set ::rivetweb::page_content $::rivetweb::index
    set ::rivetweb::current_pmodel \
                [$::rivetweb::rwebdb fetch $::rivetweb::index]
}

#set page_xml $pagine($::rivetweb::page_content)

set serialized_model [$::rivetweb::pmodel content \
                                    ::rivetweb::current_pmodel $language]

#puts "<pre>$serialized_model ([llength $serialized_model])</pre>"
array unset content_a
array set content_a $serialized_model

set page_xml $content_a(pagetext)

if {[dict keys $::rivetweb::hooks] > 0} {
    set xmlpp [dict get $::rivetweb::hooks xmlpostproc]

    foreach hk [dict keys $xmlpp] {
        apache_log_error debug "processing hook: [dict get $xmlpp $hk descrip]"
        set xmlprocessor [dict get $xmlpp $hk function]
        foreach child [$page_xml getElementsByTagName $hk] {
                   
            eval $xmlprocessor $page_xml $child

        }
    }
}

if {[isDebugging]} { puts "<pre>[escape_sgml_chars [$page_xml asXML]]</pre>" }

array unset page_menu

#foreach pm [$page_xml getElementsByTagName menu] {
#
#    if {[$pm hasAttribute position]} {
#        set position [$pm getAttribute position]
#    } else {
#        set position left
#    }
#	
#    lappend page_menu($position) [$pm text]
#}

set menu_d [$::rivetweb::pmodel mdmodel $::rivetweb::current_pmodel menu]

foreach {pos menuid} $menu_d {
    lappend page_menu($pos) [dict get $menu_d $pos]
}

#parray page_menu
array unset html_menu

if {[array exists sitemenus_a]} {

    apache_log_error info "recreating HTML menus "

    foreach pos [array names page_menu] {

# in Rivetweb versions before 2.0 every page had to explicitly list 
# the menu id that were to be shown

        set mid [split $page_menu($pos) ","]

# a page should refer to a single menu group. Anyway, for compatibility 
# with early versions of rivetweb we pick the last one

        set menuid [lindex $mid end]
        set lvmenus [::rivetweb::walkTree $sitemenus_a(root) $menuid leaf]
        apache_log_error debug " lvmenus ==> $lvmenus"

        foreach mid $lvmenus {
            apache_log_error info "creating menu for $template_key"

            append html_menu($pos)  [::rivetweb::htmlMenu $mid $language \
                       [dict get $::rivetweb::templates_db $template_key]]
        }
    }
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

# With the new object oriented approach the content language has been already
# selected by the ::rivetweb::pmodel page model manager

if {[makePageHTML $content_a(pagetext) page_content_html]} {
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

