# -- rivetweb_ns.tcl
#
#

namespace eval ::rivetweb {

# this must be the local path to the site's document root
    variable site_base
    variable rivetweb_root
    variable scripts     
    variable static_pages
    variable local_pages	    docs
    variable website_init	    rivetweb.tcl

# these paths are relative to the DocumentRoot, so we don't need
# to normalize them

    variable picts_path             picts
    variable css_path               templates
    variable base_templates         templates
    variable site_scritps           tcl
    variable newsite_templates      rwtemplates
    variable running_template       [file join $base_templates base.rvt]
    variable running_css            [file join $base_templates base.css]
    variable default_template       rwbase
    variable http_encoding          utf-8
    variable datasources            {}
    variable datasource             ::XMLBase
    variable rwebdb                 ::rwebdb
    variable logger                 ::rwlogger
    variable pmodel                 ::rwpmodel
    variable linkmodel              ::rwlink
    variable menumodel              ::rwmenu
    variable htmlizer               ::htmlizer

    variable menu_default_pos       left
    variable template_key           ""

# the procedure should quite easly evolve to have 
# the ability to handle multilingual contents. 'default_lang' 
# is the language if not explicitly defined in the url through
# the parameter 'lang'. This variable is given a value
# here but it will be assigned by the element <default_language>
# in site_structure.xml

    variable default_lang           en

    variable site_defs              site_defs.xml
    variable language               $default_lang

# 'current_rev' is an integer number specifying
# the current revision of the site.
# When pages are generated dynamically we rebuild 
# menus and contents as 'current_rev' changes  or
# if 'reset' parameter is coded in the url

    set current_rev                 0

# array that maps 'content' keys and xhtml (to be replaced
# by a dictionary?)

    variable pagine
    array set pagine                {}

# default key for content generation: basically this
# is the key to the file containing the homepage.

    variable index                  index
    variable page_content           0

# we assume we are running dynamic. A static parameter in the url
# would emulate a static site 

    variable static_links           false

# 'picts_path' and 'css_path' are paths relative to the 
# website root. 'running_*_paths' are needed because paths
# change when pages are simulating a static website.

    variable running_picts_path     $picts_path
    variable running_css_path       $css_path

# static pages will pretend to be stored in this directory
# (mirroring tools like 'wget' will actually store them
# in the 'static' subdirectory)

    variable static_path            static

# page variables used to pass parameters between procs and pages

    variable html_menu
    variable content
    variable sitemenus_a

    array set html_menu             {}
    array set content               {}
    array set sitemenus_a           {}

# and finally we create the dictionary that is to held the 
# whole website database

    variable sitepages              [dict create]

    variable page_headline          ""
    variable page_title             ""
    variable page_content_html      ""
    variable last_modified          ""
    variable page_authors           ""
    variable ident                  ""
    variable site_structure_mtime   0

# the effect of this are rather sticky, because when enabled 
# rivetweb uses the in-memory cache whenever possible 
# and won't change attitude until che child process exits
 
    variable use_page_cache         0

# dictionary defining tags and class attributes for elements a menu
# is made of

    variable templates_db           [dict create]

    dict set templates_db rwbase menu_html      {div staticmenu}
    dict set templates_db rwbase title_html     {div menuheader}
    dict set templates_db rwbase it_cont_html   {div itemcontainer}
    dict set templates_db rwbase item_html      {span menuitem}
    dict set templates_db rwbase link_class     navitem

    variable debug                  1
    variable hooks_dir              hooks

    variable hooks                  [dict create]

# These variables are of interest only for the basic XML pages support
# They can be superseded in /<path_site_root>/site_defs.tcl

# variable controlling metadata for a new static page creation 

    set metadatatags		    {date author ident keywords}

# if any RCS system it should be set here. 
# Possible values are 'svn' and 'git' or 'none'. Any other string
# falls back on 'none'

    set versioning_system	    none

# parameters for downloading binary files

    variable download_proc          download.tcl
    variable download_chunksize     65536

    proc setup {rweb_root website_root} {
        variable    scripts
        variable    rivetweb_root
        variable    site_base
        variable    static_pages
        variable    logger

        set rivetweb_root       [file normalize $rweb_root]
        set scripts	        [file join $rivetweb_root tcl]
        set site_base           $website_root        
        set static_pages        [file normalize [file join $site_base pages]]

        $logger log info "rivetweb_root set as $rivetweb_root"
    }

    proc init {ds} {
        variable    site_base
        variable    datasources
        variable    logger
        variable    default_lang

        package require $ds
        lappend datasources ::${ds} 

        $ds init
        $logger log info "Rivetweb started up at $site_base, default_language: $default_lang"
    }
}

package provide rwconf 2.0

