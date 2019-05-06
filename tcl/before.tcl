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
    ::rivet::apache_log_error debug "running rivetweb general tcl/before.tcl"

# determining if the 'rewrite_par' argument is in the query
# list of arguments and in case set the rewrite_links flag
# and the 'rewrite_code' free form code

    set rewrite_par [$::rivetweb::url_composer get_rewrite_par]
    set ::rivetweb::rewrite_links [::rivet::var_qs exists $rewrite_par]
    if {$::rivetweb::rewrite_links} {
        set ::rivetweb::rewrite_code [::rivet::var_qs get $rewrite_par]
    } else {
        set ::rivetweb::rewrite_code ""
    }

# we collect the URL-specified arguments and then we move on determining
# whether this has to be considered the home page of the web site (mostly
# to allow template specific determination)
# The is_homepage determination can be overridden in the site specific
# before script

    set argsqs [dict create {*}[::rivet::var_qs all]]
    set ::rivetweb::is_homepage [::rivet::lempty [::rivetweb::strip_sticky_args $argsqs]]

# site specific 'before' script (if any) runs here.

    if {$::rivetweb::site_before_script != ""} {
        ::rivet::apache_log_error debug "running specific 'before' script -> $::rivetweb::site_before_script"
        source $::rivetweb::site_before_script
    }

    if {[::rivet::var exists template]} {
        set template_key [::rivet::var_qs get template]
    } else {
        set template_key [::rivetweb::select_template] 
    } 

    $::rivetweb::logger log info \
                "selected template $template_key: [::rivetweb::RWTemplate::template $template_key template]"
    $::rivetweb::logger log info \
                "selected css $template_key: [::rivetweb::RWTemplate::template $template_key css]"

# let's build the full path to the template and css files through the Rivetweb specific calls

    set ::rivetweb::running_template  [::rivetweb::template $template_key]
    set ::rivetweb::running_css       [::rivetweb::csspath $template_key]
    set ::rivetweb::template_key      $template_key

    $::rivetweb::logger log info "running template $::rivetweb::running_template, $::rivetweb::running_css"

    if {$::rivetweb::template_key != $::rivetweb::last_selected_template} {
        set ::rivetweb::last_selected_template $template_key
        set ::rivetweb::template_changed true
    } else {
        set ::rivetweb::template_changed false
    }

# we determine the language for this request
# (keep in mind we are running within the ::rivetweb namespace)

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

    #puts "<pre>++[::rivetweb::strip_sticky_args $argsqs]-- $::rivetweb::is_homepage</pre>"

    $::rivetweb::logger log debug "registered handlers: [::rwdatas::UrlHandler::registered_handlers]"
    $::rivetweb::logger log debug "argsqs: $argsqs"

    set ::rivetweb::current_page [::rwdatas::UrlHandler::select_page $argsqs]

    $::rivetweb::logger log debug "\[::rwdatas::UrlHandler::select_page $argsqs\] selected $::rivetweb::current_page"

#
# The three stage generation of a page
#
#    * page content preparation
#    * HTTP header generation and transmission
#    * page data transmission
#

    set ::rivetweb::page_content $::rivetweb::page_key
    set ::rivetweb::current_page [$::rivetweb::current_page prepare_content \
                                  [::rwdatas::UrlHandler::current_handler]  \
                                  $::rivetweb::language $argsqs]

# sending headers

    $::rivetweb::current_page send_headers 

# let's proceed with the post processing and data generation

    $::rivetweb::current_page send_output $language

}
