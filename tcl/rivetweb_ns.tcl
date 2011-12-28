# -- rivetweb_ns.tcl
#
#

namespace eval ::rivetweb {

# this must be the local path to the site's document root

    if {![info exists site_base]} {
        set site_base       [file dirname [info script]]
    }
    set scripts             [file dirname [info script]]
    set static_pages        [file join $site_base pages]
    set sitemap             [file join $site_base sitemap]
    set local_pages	        [file join $site_base docs]

    set sitemap_mtime       0

# these are relative to the DocumentRoot

    set picts_path          picts
    set css_path            templates
    set base_templates      templates
    set newsite_templates   rwtemplates
    set running_template    [file join $base_templates base.rvt]
    set running_css         [file join $base_templates base.css]
    set default_template    rwbase
    set http_encoding       utf-8

    set template_key        ""

# the procedure should quite easly evolve to have 
# the ability to handle multilingual contents. 'default_lang' 
# is the language if not explicitly defined in the url through
# the parameter 'lang'. This variable is given a value
# here but it will be assigned by the element <default_language>
# in site_structure.xml

    set default_lang        en

#   set sitemap_file        site_structure.xml
    set site_defs           site_defs.xml
    set language            $default_lang

# 'current_rev' is an integer number specifying
# the current revision of the site.
# When pages are generated dynamically we rebuild 
# menus and contents as 'current_rev' changes  or
# if 'reset' parameter is coded in the url

    set current_rev         0

# array that maps 'content' keys and xhtml (to be replaced
# by a dictionary?)

    array set pagine        {}

# default key for content generation: basically this
# is the key to the file containing the homepage.

    set index               index
    set page_content        0

# we assume we are running dynamic. A static parameter in the url
# would emulate a static site 

    set static_links        false

    set running_picts_path  $picts_path
    set running_css_path    $css_path

# static pages weill pretend to be stored in this directory

    set static_path         static

# page variables used to pass parameters between procs and pages

    array set html_menu     {}
    array set content       {}

    set page_headline       ""
    set page_title          ""
    set page_content_html   ""
    set last_modified       ""
    set page_authors        ""
    set ident               ""
    set site_structure_mtime 0

# the effect of this are rather sticky, because when enabled 
# rivetweb uses the in-memory cache whenever possible 
# and won't change attitude until che child process exits
 
    set use_page_cache      0

# dictionary defining tags and class attributes for elements a menu
# is made of

    set templates_db       [dict create]

    dict set templates_db rwbase menu_html       {div staticmenu}
    dict set templates_db rwbase title_html      {div menuheader}
    dict set templates_db rwbase it_cont_html    {div itemcontainer}
    dict set templates_db rwbase item_html       {span menuitem}
    dict set templates_db rwbase link_class      navitem

    set debug               0
    set hooks_dir           hooks

    set hooks               [dict create]

# parameters for downloading binary files

    set download_proc       download.tcl
    set download_chunksize  65536

}

package provide rwconf 2.0
