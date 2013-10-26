# -- rivetweb
#
# The core functions of Rivetweb
#
#

package require rwconf
package require rwebdb
package require rwlogger

package require rwlink
package require rwmenu
package require rwsitemap
package require htmlizer

namespace eval ::rivetweb {

# -- makeUrl
#
# Central method for generating hypetext links pointing to other pages of the 
# site.
#
# References are built accordingly to the mode we are generating a page
# (either static or dynamic). In case the 'lang' or 'reset' parameters are 
# passed in their values are appended to the local path
#
# Arguments:
#
#   reference:  a string that works as a key to the page to be generated. 
#
# Returned value:
#
#   the URL to the page in relative form.
#

# 21-11-2012 Rivetweb has gone dynamic. Supporting static links requires every datasource to
# provide a one-to-one map between keys and set of parameters. 

    proc makeUrl {reference} {
#       puts "generate reference for '$reference' (static = $::rivetweb::static_links)"

        if {$::rivetweb::static_links} {

            if {([string length $reference] == 0) || \
                 [string equal $reference index]}  {
                if {$::rivetweb::is_homepage} {
                    return index.html
                } else {
                    return [file join .. index.html]
                }
            } else {
                if {$::rivetweb::is_homepage} {
                    return [file join $::rivetweb::static_path ${reference}.html]
                } else {
                    return ${reference}.html
                }
            }

        } else {

            if {[string length $reference] == 0} {
                set reference $::rivetweb::index
            }

# we use therefore ::request::env(DOCUMENT_NAME) to infer the template name

            if {[info exists ::rivetweb::env(DOCUMENT_NAME)]} {
                set local_ref "$::rivetweb::env(DOCUMENT_NAME)?show=${reference}"
            } else {
                set local_ref "index.rvt?show=${reference}"
            }

# structural variables passover

#            if {[var exists lang]} { 
#                set local_ref "${local_ref}&lang=[var get lang]" 
#            }
#            if {[var exists language]} { 
#                set local_ref "${local_ref}&language=[var get language]" 
#            }
#            if {[var exists reset]} { 
#                set local_ref "${local_ref}&reset=[var get reset]" 
#            }
#            if {[var exists template]} { 
#                set local_ref "${local_ref}&template=[var get template]" 
#            }

            foreach passthrough $::rivetweb::passthroughs {
                if {[var_qs exists $passthrough]} {
                    lappend urlargs "${passthrough}=[var_qs get $passthrough]"
                }	
            }
            return $local_ref
        }
    }
    namespace export makeUrl

# -- composeUrl
# 
# this function should consistently build links 
#
    proc composeUrl {args} {

        if {[::rivet::var_qs exists $::rivetweb::rewrite_par]} {

            set rwcode [::rivet::var_qs get $::rivetweb::rewrite_par]
            foreach ds $::rivetweb::datasources {

                $ds rewrite_url $rwcode [env SCRIPT_NAME] $args rewritten_url
                return $rewritten_url 

            }

        }

        set arglist $args
        set urlargs {}

        while {[llength $arglist]} {
            set arglist [lassign $arglist param value]
            set argsmap($param) [::rivet::escape_string $value]
        }

        foreach passthrough $::rivetweb::passthroughs {
            if {[::rivet::var_qs exists $passthrough]} {
                set argsmap($passthrough) [::rivet::var_qs get $passthrough]
            }	
        }

        set arglist [array get argsmap]
        while {[llength $arglist]} {
            set arglist [lassign $arglist param value]
            lappend urlargs "${param}=${value}"
        }

        return "[env SCRIPT_NAME]?[join $urlargs "&"]"

    }
    namespace export composeUrl


# -- buildSimplePage 
#
# Utility function that builds a simple page out of a message 
# 
# Arguments: 
#
#    - mag          Message text
#    - cssclass     css class the element enclosing the text must have
#    - pagina_id    identification of the page for subsequent retrieving 
#                   from the cache
#
#  Returned value:
#
#   - reference to the tdom object representing the page
#

    proc buildSimplePage {msg cssclass pagina_id} {

        if {![info exists ::rivetweb::pagine($pagina_id)]} {
            set msgdom  [dom createDocument page]
            set xml_o   [$msgdom documentElement]

# Let's add the menus to the dom

            set menu_o  [$msgdom createElement menu]
            $xml_o appendChild $menu_o
            set t   [$msgdom createTextNode "index"]
            $menu_o appendChild $t

# ...and then the page main content

            set content_o [$msgdom createElement content]
            $xml_o appendChild $content_o

            set headline_o [$msgdom createElement headline]
            set hdline_to  [$msgdom createTextNode "Rivetweb anomaly"]
            $headline_o appendChild $hdline_to
            set title_o   [$msgdom createElement title]
            set title_to  [$msgdom createTextNode "Rivetweb anomaly"]
            $title_o    appendChild $title_to
            $headline_o appendChild $hdline_to
            $content_o  appendChild $headline_o
            $content_o  appendChild $title_o

            set htmldiv_o [$msgdom createElement pagetext]
            $content_o appendChild $htmldiv_o
            eval $htmldiv_o setAttribute class $cssclass 

            set t [$msgdom createTextNode $msg]
            $htmldiv_o appendChild $t

        } else {
            set msgdom $::rivetweb::pagine($pagina_id)
        }

        return $msgdom
    }
    namespace export buildSimplePage

# -- makeCssPath 
#
#   creates rivetweb path to a CSS file
#
# Arguments:
#
#       css_file:   CSS file name
#       style_dir:  template/CSS key
#
# style_dir is supposed to be a 'key' in a database of templates, it
# represents the directory name where the CSS is located within the 
# ::rivetweb::running_css_path directory containing the css files for 
# the supported templates.
#

    proc makeCssPath {css_file {style_dir ""}} {

        return [file join $::rivetweb::running_css_path $style_dir $css_file] 

    }
    namespace export makeCssPath


# -- csspath 
#
# the templates database is supposed to store the whole dataset needed to build 
# any reference to a theme related piece of information, thus we can fetch the css
# filename by using simply the key to the template.
# 
# The procedure assumes the template files are stored in subdirectory bearing the
# same name as the template key.
#

    proc csspath {template_key} {

        return [makeCssPath [dict get $::rivetweb::templates_db $template_key css] $template_key]

    }
    namespace export csspath

# -- makePictsPath
#
# search 'picts_file' in the graphic files search path sequence
#

    proc makePictsPath {picts_file {style_dir ""}} {

        apache_log_error debug "style $style_dir $::rivetweb::running_picts_path [pwd] (site_base: $::rivetweb::site_base)"

# search list for a picts file. 
#
#    - We first try in the template's specific dir
#    - then we try the picts root directory 
#    - then we try in the website root 'picts' directory
#    - last we attempt in the rwbase dir

# we have to deceive static links (relative to the ::rivetweb::static_path variable)
# but still we must be aware we are running from /index.rvt

        if {[dict exists $::rivetweb::templates_db $::rivetweb::template_key pictures]} {
            set template_picts [dict get $::rivetweb::templates_db $::rivetweb::template_key pictures]
            set fn [file join   $::rivetweb::site_base      \
                                $::rivetweb::base_templates \
                                $style_dir                  \
                                $template_picts $picts_file]

            apache_log_error debug "0 pict file: >$fn<"
            if {[file exists $fn]} {
                return [file join $::rivetweb::base_templates $style_dir $template_picts $picts_file]
            }
        }

# pictures directory within the template directory, style_dir is usually the template_key variable
# but we keep this case to make room to other repositories of pictures

        set fn [file join   $::rivetweb::site_base      \
                            $::rivetweb::base_templates \
                            $style_dir                  \
                            $picts_file]

        apache_log_error debug "1 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::base_templates $style_dir $picts_file]
        } 

# website pictures directory combined with a template specific directory: <site_base>/<site_picts>/<template_key> 

        set fn [file join   $::rivetweb::site_base  \
                            $::rivetweb::picts_path \
                            $style_dir              \
                            $picts_file]

        apache_log_error debug "2 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::running_picts_path $style_dir $picts_file]
        } 

# searching in the ordinary <site_base>/<site_picts> directory

        set fn [file join   $::rivetweb::site_base    \
                            $::rivetweb::picts_path   \
                            $picts_file]

        apache_log_error debug "3 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::running_picts_path $picts_file]
        } 

# it's rather weird we have this case. No template directory should be hanging from site_base

        set fn [file join   $::rivetweb::site_base          \
                            $::rivetweb::picts_path         \
                            $::rivetweb::default_template   \
                            $picts_file]

        apache_log_error debug "4 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join   $::rivetweb::running_picts_path   \
                                $::rivetweb::default_template     \
                                $picts_file]
        }

        return ""
    }
    namespace export makePictsPath

# -- picture
#
#
    proc picture {pict_name} {  }


# -- template_path
#
# 

    proc template_path {template_name {template_dir ""}} {

        return [file join $::rivetweb::base_templates $template_dir $template_name]

    }
    namespace export template_path

# -- template
#
#
    proc template {template_key} {

        return [::rivetweb::template_path [dict get $::rivetweb::templates_db $template_key template] $template_key]

    }
    namespace export template


# -- script_path
#
#
    proc script_path {script_name {template_dir ""}} {

        return [file join $::rivetweb::base_templates $template_dir $script_name]

    }
    namespace export script_path

# -- javascript
#
#
    proc javascript {script} {

        return "<script type=\"text/javascript\" src=\"[script_path $script $::rivetweb::template_key]\"></script>"

    }
    namespace export javascript


# -- thisClass 
#
# returns a class="classname" attribute when we are generating
# a specific page. Useful in selectors both in forms or templates to highlight
# an element.

    proc thisClass {this_page page_reference class_selected {class_unselected ""}} {

        if {[string match $this_page $page_reference]} { 

            return " class=\"$class_selected\""

        } else {

            if {$class_unselected != ""} {
                return " class=\"$class_unselected\""
            } else {
                return ""
            }

        }
    }
    namespace export thisClass


# -- isDebugging 
#
#

    proc isDebugging { } {
        return [expr $::rivetweb::debug && [var exists debug]]
    }

 
# -- contentType
#
# Returns a 'meta' XHTML tag element specifying the content type
# and charset as stored in 

    proc contentType {} {
        return "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=$::rivetweb::http_encoding\" />"
    }

# -- searchPath 
# 
# looks for <filename> in a sequence of paths given in <pathList>
# and returns the actual path (absolute path) if found, otherwise
# returns an empty string
#

    proc searchPath {fileName pathList} {

        foreach pth $pathList {

            set fn [file join $pth $fileName]

            if {[file exists $fn]} {
                return [file normalize $fn]
            }
        }
        return ""
    }
    namespace export searchPath

# -- build_html_menu 
#
# central function returning a menu of link as an HTML fragment. The markup
# is described withing the dictionary 'templates_db'
#
# Arguments:
#
#  - pagemenus: dictionary associating positions and menu objects
#  - template_key: key to the dictionary storing template specific definitions
#  - position: keyword (usually a 'position') specifing role within the page
#

    proc build_html_menu { pagemenus template_key position } {

        set htmldefs [dict get $::rivetweb::templates_db $template_key]
        set htmltext ""
        if {[dict exists $pagemenus $position]} {
            set menus [dict get $pagemenus $position]
#           puts "<div style=\"border: 1px solid red;\">$menus</div>"
            foreach menuobj $menus {    

                append htmltext [$::rivetweb::htmlizer html_menu            \
                                                    $menuobj                \
                                                    $::rivetweb::language   \
                                                    $htmldefs]

            }
        }
        return $htmltext
    }
    namespace export build_html_menu


    namespace ensemble create
}

package provide rivetweb 2.0
