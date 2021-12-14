# -- rivetweb_ns.tcl
#
#

namespace eval ::rivetweb {

# version 

    variable version                    20211214

# this must be the local path to the site's document root

    variable rivetweb_root              ""

    variable site_base                  ""
    variable request
    variable scripts
    variable website_init               rivetweb.tcl
    variable site_before_script         ""
    variable site_after_script          ""
    variable site_abort_script          ""
    variable site_after_every_script    ""
    variable pagemenus

# -- rivetweb default 
#
# These values are the very last fallback values for the defaults

    variable default_template       rwbase
    variable default_menu           main
    variable default_menu_pos       left
    variable default_lang           en

# these paths are relative to the DocumentRoot, so we don't need to normalize them

    #variable site_url_base          /
    
    # site wide definition of a directory for picture files
    
    variable picts_path             picts

    variable css_path               templates
    variable base_templates         templates
    variable newsite_templates      rwtemplates
    variable running_template       [file join $base_templates base.rvt]
    variable running_css            [file join $base_templates base.css]
    variable http_encoding          utf-8
    variable handlers_dir           handlers

    variable logger                 ::rwlogger
    variable linkmodel              ::rwlink
    variable menumodel              ::rwmenu
    variable sitemap                RWSitemap

# to menuclass it's given a default in tcl/rivet_init.tcl

    variable menuclass              RWMenu
    variable htmlizer               ::htmlizer

# variable to store the list of URL-encoded arguments: it's set at *every* request
# in tcl/before.tcl

    variable argsqs                 {}

    variable is_homepage            0
    variable template_key           ""
    variable template_changed       false
    variable last_selected_template ""

# the procedure should quite easly evolve to have 
# the ability to handle multilingual contents. 'default_lang' 
# is the language if not explicitly defined in the url through
# the parameter 'lang'. This variable is given a value
# here but it will be assigned by the element <default_language>
# in site_structure.xml

    #variable site_defs              site_defs.xml
    variable language               $default_lang

# 'current_rev' is an integer number specifying
# the current revision of the site.
# When pages are generated dynamically we rebuild 
# menus and contents as 'current_rev' changes  or
# if 'reset' parameter is coded in the url

    set current_rev                 0

# default key for content generation: basically this
# is the key to the file containing the homepage.

    variable index                  index
    variable page_content           0

# we assume we are running dynamic. A $rewrite_par argument in the url
# would force rewrite of all the web site internal links

    variable rewrite_links          false
    variable rewrite_code           ""

# default name of the urlencoded parameter used
# to signal which rewriting rule was detected (if any)

    variable rewrite_par            static

# URL encoded parameters to be replicated by makeUrl and composeUrl

#    variable sticky_args            [list lang language reset template $rewrite_par]

# url composer instance

    variable url_composer

# 'picts_path' and 'css_path' are paths relative to the 
# website root. 'running_*_paths' are needed because paths
# change when pages are simulating a static website.

#    variable running_picts_path     $picts_path
#    variable running_css_path       $css_path

# static pages will pretend to be stored in this directory
# (mirroring tools like 'wget' will actually store them
# in the 'static' subdirectory)

#   variable static_path            static

# page variables used to pass parameters between procs and pages

# debug array for procedure ::rivetweb::dump_data

    variable dumpdata_map
    variable dumpdata_fp

    array set dumpdata_map {}

    variable html_menu
    variable content
    variable sitemenus_a

    array set html_menu             {}
    array set content               {}
    array set sitemenus_a           {}

# dictionary defining tags and class attributes for elements a menu
# is made of

    variable templates_db [dict create]

    dict set templates_db rwbase menu_html      {div staticmenu}
    dict set templates_db rwbase title_html     {div menuheader}
    dict set templates_db rwbase it_cont_html   {div itemcontainer}
    dict set templates_db rwbase item_html      {span menuitem}
    dict set templates_db rwbase link_class     navitem
    dict set templates_db rwbase pictures       picts

    variable debug        1
    variable hooks_dir    hooks
    variable hooks        [dict create]

# channel status

    variable channel_xlation
    variable channel_encoding

    proc setup {rweb_root website_root} {
        variable    scripts
        variable    rivetweb_root
        variable    request
        variable    site_base
        variable    logger
        variable    site_before_script
        variable    site_after_script
        variable    site_abort_script
        variable    site_after_every_script

        set rivetweb_root   [file normalize $rweb_root]
        set scripts	        [file join $rivetweb_root tcl]
        set request         [file join $scripts before.tcl]
        set site_base       $website_root        
        
        ::rivetweb save_channel_status

        set site_before_script [file normalize [file join $site_base before.tcl]]
        if {![file exists $site_before_script]} {
            set site_before_script ""
        } else {
            ::rivet::apache_log_error notice "website specific request script $site_before_script"
        }

        set site_after_script [file normalize [file join $site_base after.tcl]]
        if {![file exists $site_after_script]} {
            set site_after_script ""
        } else {
            ::rivet::apache_log_error notice "website specific after request script $site_after_script"
        }

        set site_abort_script [file normalize [file join $site_base abort.tcl]]
        if {![file exists $site_abort_script]} {
            set site_abort_script ""
        } else {
            ::rivet::apache_log_error notice "website specific abort request script $site_abort_script"
        }

        set site_after_every_script [file normalize [file join $site_base after_every.tcl]]
        if {![file exists $site_after_every_script]} {
            set site_after_every_script ""
        } else {
            ::rivet::apache_log_error notice "website specific 'after every' request script $site_after_every_script"
        }

        ::rivet::apache_log_error notice "rivetweb_root set as $rivetweb_root"
    }

# -- set_handler_args
#
#

    proc set_handler_args {handler args} {
        ::rwdatas::UrlHandler::set_handler_arguments $handler {*}$args
    }

# -- lremove
#
#   list element removal: taken straight from the Tcl manual page for lreplace

    proc lremove {listVariable value} {
        upvar 1 $listVariable var
    
        set idx [lsearch -exact $var $value]
        set var [lreplace $var $idx $idx]
    }

# -- init
#
# init used to be the real initialization in Rivetweb 1.0. Most of its tasks
# have been devolved to other components (notably url handlers). Its main duty now
# is to register new url handlers.
#

    proc init {urlhandler {position "last"} args} {
        variable    logger
        variable    default_lang

        set argidx [lsearch $args "-nopkg"]
        if {$argidx < 0} {
            package require $urlhandler
        } else {
            set args [lreplace $args $argidx $argidx]
        }

        set urlobj [::rwdatas::${urlhandler} ::${urlhandler}]

        ::rwdatas::UrlHandler::register_handler $urlobj $position {*}$args
        
        ::rivetweb add_search_path $::rivetweb::site_base 
        ::rivetweb add_search_path $::rivetweb::rivetweb_root
    }
}

package provide rwconf 2.1
