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
    foreach {codice_pag xmlref} [array get pagine] { $xmlref delete }
    set pagine($::rivetweb::index)	[::rivetweb::buildPage index]
    set ::rivetweb::page_content	$::rivetweb::index

    array unset pagine
} 

# the central point is exactly here: we have to decide which page
# we have to display

if {[var exists show]} {
    set pagina [var get show]
    if {[isDebugging]} { apache_log_error info "requesting page '$pagina'" }
#   parray pagine

# if we are using cached content and requested page is cached we simply
# store in ::rivetweb::page_content

    if {[info exists pagine($pagina)] && $::rivetweb::use_page_cache} {
        set ::rivetweb::page_content $pagina
    } else {
        set xmldom [::rivetweb::buildPage $pagina ::rivetweb::page_content $language]
        set pagine($::rivetweb::page_content) $xmldom 
    }
} else {

# Rivetweb assumes the default page is defined in the ::rivetweb::index variable

    set ::rivetweb::page_content $::rivetweb::index
    if {!$::rivetweb::use_page_cache} {
        set xmldom [::rivetweb::buildPage $::rivetweb::index ::rivetweb::page_content $language]
        set pagine($::rivetweb::page_content) $xmldom 
    }
}

array unset page_menu
#puts stderr "content: $::rivetweb::page_content"

#set page_xml [xmlPostProcessing $pagine($::rivetweb::page_content)]
set page_xml $pagine($::rivetweb::page_content)

if {[dict keys $::rivetweb::hooks] > 0} {
    set xmlpp [dict get $::rivetweb::hooks xmlpostproc]

    foreach hk [dict keys $xmlpp] {
        apache_log_error info "processing hook: [dict get $xmlpp $hk descrip]"
        set xmlprocessor [dict get $xmlpp $hk function]
        set xmlDoc $pagine($::rivetweb::page_content)
        foreach child [$xmlDoc getElementsByTagName $hk] {
                   
            eval $xmlprocessor $xmlDoc $child

        }
    }
}

if {[isDebugging]} { puts "<pre>[escape_sgml_chars [$page_xml asXML]]</pre>" }

foreach pm [$page_xml getElementsByTagName menu] {

    if {[$pm hasAttribute position]} {
        set position [$pm getAttribute position]
    } else {
        set position left
    }
	
    lappend page_menu($position) [$pm text]
}

#parray page_menu
array unset html_menu

#parray sitemenus_a

if {[array exists sitemenus_a]} {

    foreach pos [array names page_menu] {

# in Rivetweb versions before 2.0 every page had to explicitly tell 

        set mid [split $page_menu($pos) ","]

# assumiamo l'ultimo menu come quello di livello più basso (compatibilità con versione 1.x di rivetweb)

        set menuid [lindex $mid end]
        set lvmenus [::rivetweb::walkTree $sitemenus_a(root) $menuid leaf]
#       puts "<pre style=\"background-color: #0ff;border: 1px solid black;\">== $lvmenus ==</pre>"

        foreach mid $lvmenus {
            apache_log_error info "creating menu for $template_key"

            append html_menu($pos) [::rivetweb::htmlMenu $mid $language \
                                   [dict get $::rivetweb::templates_db $template_key]]
        }
    }
}

if {[isDebugging]} { puts "<pre> ===== menu: [array names html_menu]</pre>" }

set page_authors    [getElementValue $page_xml author]

#puts "<pre>==> $ident <===</pre>"

    
if {[dict keys $::rivetweb::hooks] > 0} {
    set metadatapp [dict get $::rivetweb::hooks metadata]

    foreach hk [dict keys $metadatapp] {
        apache_log_error info "processing hook: [dict get $metadatapp $hk descrip]"
        set xmlprocessor [dict get $metadatapp $hk function]
        set xmlDoc $pagine($::rivetweb::page_content)
        foreach child [$xmlDoc getElementsByTagName $hk] {
                   
            eval $xmlprocessor $xmlDoc $child

        }
    }
}

# we finally create HTML out of the xml page so far handled.

if {[selectContent $page_xml $language content_selected]} {
    array unset content
    if {[makePageHTML $page_xml $content_selected content]} {
        set page_content_html $content(pagetext)
        set page_title        $content(title)
        set page_headline     $content(headline)       
    } else {
        set page_content_html "Rivetweb internal error: could not create HTML from page data"
        set page_headline     "Rivetweb error"
        set page_title        "Rivetweb error"
    }
} else {
    set page_content_html "no content found"
}

