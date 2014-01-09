# -- before.tcl
#
#+
# this file ships the BeforeScript code of a Rivetweb site.
#-
#

namespace eval ::rivetweb { 

    # let's load the environment into array ::request::env

    load_env env

    apache_log_error debug "running tcl/before.tcl"

#
# -- rivet_before.tcl
# 
# This is where at every request most of the work is done to prepare a page. 
# rivet_before sets some Rivetweb status variables depending on the value
# of some typically urlencoded parameters
#
#

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
    set ::rivetweb::is_homepage   [::rivet::var_qs exists homepage]
    
# when Rivetweb is pretending to be a static site, pages fake their location 
# to be in the a subdirectory of the site root (default: 'static'), so 
# 'running_picts_path' and running_css_path have to be set accordingly

    set ::rivetweb::running_picts_path  $::rivetweb::picts_path
    set ::rivetweb::running_css_path    $::rivetweb::css_path

    if {$::rivetweb::rewrite_links && !$::rivetweb::is_homepage} {

        set ::rivetweb::running_picts_path  [file join .. $::rivetweb::picts_path]
        set ::rivetweb::running_css_path    [file join .. $::rivetweb::css_path]

    }

# let's determine which template we are using. We set a couple of default
# values for them

    set running_template base.rvt
    set running_css      base.css 

    if {[var exists template]} {

        set template_key [var get template]

#        catch {
#
#            set running_template  [dict get $::rivetweb::templates_db $template_key template]
#            set running_css       [dict get $::rivetweb::templates_db $template_key css]
#
#        }

    } elseif {[string compare $::rivetweb::default_template ""] != 0} {

        set template_key $::rivetweb::default_template
#        if {[catch {
#
#            set running_template  [dict get $::rivetweb::templates_db $template_key template]
#            set running_css       [dict get $::rivetweb::templates_db $template_key css]
#
#        } e]} { puts "errore: $e" }

    } else {

# there must be always a definition for the rwbase template

        set template_key rwbase

    }

    $::rivetweb::logger log info "selected template: $running_template (css: $running_css)"

# let's build the full path to the template and css files through the Rivetweb specific calls

    set ::rivetweb::running_template  [::rivetweb::template $template_key]
    set ::rivetweb::running_css       [::rivetweb::csspath $template_key]
    set ::rivetweb::template_key      $template_key

# setting this parameter redirs to the 'static' form of the website.
#
#   if {[var exists staticroot]} {
#       header redir index.html
#   }
#

# we determine the language for this request (keep in mind we are running
# within the ::rivetweb namespace.

    if {[var exists lang]} {
        set language [var get lang]
    } elseif {[var exists language]} {
        set language [var get language]
    } else {
        set language $::rivetweb::default_lang
    }

#
# the central point is exactly here: we determine which page we have to display
#
    set argsqs [dict create {*}[var_qs all]]

    $::rivetweb::logger log debug "registered datasources: $::rivetweb::datasources"
    $::rivetweb::logger log debug "argsqs: $argsqs"
    foreach ds $::rivetweb::datasources {

        set ::rivetweb::datasource $ds
        $ds willHandle $argsqs ::rivetweb::page_key 

    }

# specific 'before' script

    apache_log_error notice "running specific 'before' script >$::rivetweb::site_before_script<"
    if {$::rivetweb::site_before_script != ""} { 
        source $::rivetweb::site_before_script
    }

    $::rivetweb::logger log info "processing request for '$page_key'"
    set ::rivetweb::page_content $page_key
    set ::rivetweb::current_pmodel [$::rivetweb::rwebdb fetch $::rivetweb::page_key]
    set ::rivetweb::current_pmodel [$::rivetweb::current_pmodel prepare $::rivetweb::language $argsqs]

# vi:shiftwidth=4:softtabstop=4:

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

# we run metadata hooks for variable that have to be extracted to control the
# display of our template

    $::rivetweb::current_pmodel metadata_hooks $::rivetweb::hooks

    if {[isDebugging]} { puts "<pre>[escape_sgml_chars [$page_xml asXML]]</pre>" }

    apache_log_error notice "-> $::rivetweb::current_pmodel"

    catch {unset ::rivetweb::pagemenus}
    set ::rivetweb::pagemenus [dict create]

    foreach ds $::rivetweb::datasources {

        set dsmenu [$ds menu_list $::rivetweb::current_pmodel]
        apache_log_error notice "got $dsmenu from $ds"
        #puts "<pre>got $dsmenu from $ds</pre>"

        foreach k [dict keys $dsmenu] {

            if {[dict exists $::rivetweb::pagemenus $k]} {
                set m [concat [dict get $::rivetweb::pagemenus $k] [dict get $dsmenu $k]]
            } else {
                set m [dict get $dsmenu $k]
            }

            dict set ::rivetweb::pagemenus $k $m
        }

    }

    apache_log_error notice "menu database $::rivetweb::pagemenus"

    if {[catch {

       $::rivetweb::current_pmodel postproc_hooks   $::rivetweb::datasource \
                                                    $::rivetweb::hooks      \
                                                    xmlpostproc             \
                                                    $language

    } e]} {

        $::rivetweb::logger log err "Error processing data for page ($e)"
        $::rivetweb::logger log err $errorInfo
        if {![$::rivetweb::rwebdb check postproc_hook_error]} {
            set pobj [::rwpage::RWStatic ::#auto postproc_hook_error]
            $pobj set_pagetext $::rivetweb::default_lang "Error in page postprocessing"
            $pobj add_metadata header "Postprocessing error"
            $pobj add_metadata title  "Postprocessing error"
            $::rivetweb::rwebdb store postproc_hook_error $pobj ::RWDummy
        } else {

            set pobj [$::rivetweb::rwebdb fetch postproc_hook_error]
            set ::rivetweb::current_pmodel $pobj

        }
    }

    if {[$::rivetweb::current_pmodel binary_content]} {
        $::rivetweb::current_pmodel print_binary
    } else {
        headers type "text/html; charset=$::rivetweb::http_encoding"
    }
}
