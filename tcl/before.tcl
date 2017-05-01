# -- before.tcl
#
#+
# This is where at every request most of the work is done to prepare a page. 
# rivet_before sets some Rivetweb status variables depending on the value
# of some typically urlencoded parameters.
# Code is running within the ::rivetweb namespace, but we keep to 
# fully qualify variables so to make explicit their role of status variables
# in the request processing
#
#-
#

namespace eval ::rivetweb { 

    # let's load the environment into array ::request::env

    ::rivet::load_env env
    ::rivet::apache_log_error debug "running tcl/before.tcl"


# let's assign the controlling variables with the corresponding parameters 
# definitions.
#
# static   -> enabling generation of 'static' (i.e. .html) pages
# homepage -> the home is treated in a slightly different way, so we have
#             to signal it with this flag
#
# this assignements are meaningful only when appropriate mod_rewrite rules
# are set up in the configuration 

#   set ::rivetweb::static_links [::rivet::var_qs exists static]

    set ::rivetweb::rewrite_links [::rivet::var_qs exists $::rivetweb::rewrite_par]
    #set ::rivetweb::is_homepage   [::rivet::var_qs exists homepage]
    
# when Rivetweb is pretending to be a static site, pages fake their location 
# to be in the a subdirectory of the site root (default: 'static'), so 
# 'running_picts_path' and running_css_path have to be set accordingly

    set ::rivetweb::running_picts_path  $::rivetweb::picts_path
    set ::rivetweb::running_css_path    $::rivetweb::css_path

# let's determine which template we are using. We set a couple of default
# values for the running template and basic associated CSS

    set running_template base.rvt
    set running_css      base.css 

    if {[::rivet::var exists template]} {

        set template_key [::rivet::var_qs get template]

    } else { 

        set template_key [::rivetweb::select_template] 

    } 

    $::rivetweb::logger log info "selected template $template_key: $running_template (css: $running_css)"

# let's build the full path to the template and css files through the Rivetweb specific calls

    set ::rivetweb::running_template  [::rivetweb::template $template_key]
    set ::rivetweb::running_css       [::rivetweb::csspath $template_key]
    set ::rivetweb::template_key      $template_key

    if {$::rivetweb::template_key != $::rivetweb::last_selected_template} {
        set ::rivetweb::last_selected_template $template_key
        set ::rivetweb::template_changed true    
    } else {
        set ::rivetweb::template_changed false
    }

# we determine the language for this request (keep in mind we are running
# within the ::rivetweb namespace)

    if {[::rivet::var exists lang]} {
        set language [::rivet::var get lang]
    } elseif {[::rivet::var exists language]} {
        set language [::rivet::var get language]
    } else {
        set language $::rivetweb::default_lang
    }

#
# the central point is exactly here: we determine which page we have to display
#
    set argsqs [dict create {*}[::rivet::var_qs all]]
    set ::rivetweb::is_homepage [::rivet::lempty [::rivetweb::strip_sticky_args $argsqs]]

# site specific 'before' script (if any was created) is evaluated

    if {$::rivetweb::site_before_script != ""} { 
        ::rivet::apache_log_error debug "running specific 'before' script -> $::rivetweb::site_before_script"
        source $::rivetweb::site_before_script
    }

    $::rivetweb::logger log debug "registered datasources: $::rivetweb::datasources"
    $::rivetweb::logger log debug "argsqs: $argsqs"
    foreach ds $::rivetweb::datasources {

        set ::rivetweb::datasource $ds

        set dsquery [catch { $ds willHandle $argsqs ::rivetweb::page_key } error_code error_info]
        $::rivetweb::logger log info "$ds: dsquery, ecode, einfo: $dsquery | $error_code | $error_info"

        switch $dsquery {

            3 {
                break
            }
            0 -
            4 {
                continue
            }

        }

    }

    $::rivetweb::logger log debug "error_code $error_info"
    if {[dict get $error_info -errorcode] == "rw_restart"} {
        $::rivetweb::logger log debug "datasource search forced"
        set ::rivetweb::current_page \
            [::rivetweb::search_datasources $::rivetweb::page_key ::rivetweb::page_key ::rivetweb::datasource]
    } else {
        set ::rivetweb::datasource $ds
        set ::rivetweb::current_page [$::rivetweb::datasource fetch_page $::rivetweb::page_key ::rivetweb::page_key]
    } 
    $::rivetweb::logger log info "processing request for '$::rivetweb::page_key'"

    set ::rivetweb::page_content $::rivetweb::page_key
    set ::rivetweb::current_page \
        [$::rivetweb::current_page prepare_content $::rivetweb::datasource $::rivetweb::language $argsqs]

# let's proceed with the post processing and data generation

    if {[$::rivetweb::current_page binary_content]} {

        $::rivetweb::current_page print_binary $language

    } else {

        #if {[isDebugging]} { puts "<pre>[escape_sgml_chars [$page_xml asXML]]</pre>" }
        #::rivet::apache_log_error debug "-> $::rivetweb::current_page"

    # we rebuild the navigation menu dictionary on every request

        set ::rivetweb::pagemenus [dict create]

        foreach ds $::rivetweb::datasources {

            set dsmenu [$ds menu_list $::rivetweb::current_page]
            ::rivet::apache_log_error debug "got '$dsmenu' from $ds"
            dict for {k v} $dsmenu {
                dict lappend ::rivetweb::pagemenus $k {*}$v
            }
        }

        ::rivet::apache_log_error debug "menu database $::rivetweb::pagemenus"

        fconfigure stdout -translation lf -encoding $::rivetweb::http_encoding
        ::rivet::headers type "text/html; charset=$::rivetweb::http_encoding"

        if {[::rivet::var exists rwinfo]} {
            ::rivet::load_env env
            ::rivet::parray_table env
            #parse [file join $::rivetweb::scripts rivetweb_inspector.rvt]
            set siteconf [::rivet::inspect]

            foreach k [dict keys $siteconf] {
                set arrayv "_${k}_"
                array set $arrayv [dict get $siteconf $k]
                ::rivet::parray_table $arrayv
            }

        } elseif {[::rivet::var exists function]} {
            set fun [::rivet::var get function]
            if {[catch {eval source [file join $::rivetweb::scripts $fun]} e]} {
                puts $e
            }
        } else {
            ::rivet::apache_log_error info "parsing $::rivetweb::running_template"
            ::rivet::parse $::rivetweb::running_template
        }
    }
}
