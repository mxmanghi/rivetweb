# -- rivetweb
#
# The core functions of Rivetweb
#
#

# starting with this branch we require Tcl 8.6
#package require Tcl 8.6

package require rwconf
package require rwebdb
package require rwlogger

package require rwlink
package require rwmenu
package require rwsitemap
package require htmlizer

namespace eval ::rivetweb {

# -- select_datasource
#
# this function is the central mechanism for selecting
# a datasource depending on the urlencoded parameters
#
# The function accepts the list of param-value pairs 
# encoded and a variable name to store the datasource
# generated key to the resource. The procedure returns
# the reference to the selected datasource
#

    proc select_datasource {urlencoded_pars resource_key_var} {
        variable datasources
        upvar $resource_key_var key

        foreach ds $datasources {
            $ds willHandle $urlencoded_pars key
        }

        return $ds
    }


# base methods for url rewriting. This procedures can be 
# superseded by application specific code and should
# go into a class to preserve the basic functionality and
# extend them through subclassing

    proc rewrite_css_url {rwcode urlscript css_path rewritten_css_url} {
        upvar $rewritten_css_url rwcss

        set rwcss "/$css_path"
    }
    namespace export rewrite_css_url

    proc rewrite_js_url {rwcode urlscript js_path rewritten_js_url} {
        upvar $rewritten_js_url rwjs

        set rwjs "/${js_path}"
    }
    namespace export rewrite_js_url

    proc rewrite_url {rwcode urlscript urlargs rewritten_base} {
        upvar $rewritten_base rrbase

        set rrbase $urlscript
    }
    namespace export rewrite_url

# -- composeUrl
# 
# this function should consistently build links 
#
    proc composeUrl {args} {

        set arglist $args
        if {$::rivetweb::rewrite_links} {

            set rwcode [::rivet::var_qs get $::rivetweb::rewrite_par]
            ::rivetweb::rewrite_url $rwcode [::rivet::env SCRIPT_NAME] arglist rewritten_url

        } else {

            set rewritten_url [::rivet::env SCRIPT_NAME]

        }

        array set argsmap {}
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
        set urlargs {}

        ::rivet::apache_log_error debug "URL $rewritten_url -> $arglist"
        if {[llength $arglist]} {
            while {[llength $arglist]} {
                set arglist [lassign $arglist param value]
                lappend urlargs "${param}=${value}"
            }
            return "${rewritten_url}?[join $urlargs "&"]"
        } else {
            return $rewritten_url
        }


    }
    namespace export composeUrl

# -- make_css_path 
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
# this method should be considered as private
#

    proc make_css_path {css_relative_path} {

        set css_uri $css_relative_path
        if {$::rivetweb::rewrite_links} {
            
            set rwcode [::rivet::var_qs get $::rivetweb::rewrite_par]
            ::rivetweb::rewrite_css_url $rwcode [::rivet::env SCRIPT_NAME] $css_uri css_uri

            return $css_uri

        }

        return $css_uri 
    }


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
    
        set css_file_name [dict get $::rivetweb::templates_db $template_key css]
        set css_file_path [file join $::rivetweb::css_path $template_key $css_file_name] 

        return [::rivetweb::make_css_path $css_file_path]

    }
    namespace export csspath

# -- css
#
#

    proc css {css_path {attributes ""}} {
        
        set xhtml "<link href=\"$css_path\" rel=\"stylesheet\" type=\"text/css\""
        foreach {attrb attrv} $attributes { append xhtml " ${attrb}=\"${attrv}\"" }
        return "${xhtml} />"
#       return [::rivet::xml "" [concat link rel "stylesheet" type "text/css" href $css_path $attributes]]

    }
    namespace export css

# -- makePictsPath
#
# search 'picts_file' in the graphic files search path sequence
#

    proc makePictsPath {picts_file {style_dir ""}} {
        return [file join / [findPictureFile $picts_file $style_dir]]
    }
    namespace export makePictsPath

# -- findPictureFile
# 
# searching various directories to determine the path to the file 
#

    proc findPictureFile {picts_file style_dir} {

        ::rivet::apache_log_error debug \
        "style $style_dir $::rivetweb::running_picts_path [pwd] (site_base: $::rivetweb::site_base)"

# search list for a picts file. 
#
#    - We first try in the template's specific dir
#    - then we try the template picts directory 
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

            ::rivet::apache_log_error debug "0 pict file: >$fn<"
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

        ::rivet::apache_log_error debug "1 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::base_templates $style_dir $picts_file]
        } 

# website pictures directory combined with a template specific directory: <site_base>/<site_picts>/<template_key> 

        set fn [file join   $::rivetweb::site_base  \
                            $::rivetweb::picts_path \
                            $style_dir              \
                            $picts_file]

        ::rivet::apache_log_error debug "2 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::running_picts_path $style_dir $picts_file]
        } 

# searching in the ordinary <site_base>/<site_picts> directory

        set fn [file join   $::rivetweb::site_base    \
                            $::rivetweb::picts_path   \
                            $picts_file]

        ::rivet::apache_log_error debug "3 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::running_picts_path $picts_file]
        } 

# it's rather weird we have this case. No template directory should be hanging from site_base

        set fn [file join   $::rivetweb::site_base          \
                            $::rivetweb::picts_path         \
                            $::rivetweb::default_template   \
                            $picts_file]

        ::rivet::apache_log_error debug "4 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join   $::rivetweb::running_picts_path   \
                                $::rivetweb::default_template     \
                                $picts_file]
        }

        return ""
    }

# -- picture
#
#
    proc picture {pict_name} { return [::rivetweb::findPictureFile $pict_name $::rivetweb::template_key] }

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

        return [::rivetweb template_path [dict get $::rivetweb::templates_db $template_key template] $template_key]

    }
    namespace export template


# -- jscript_path
#
# the rationale behind this method is similar to make_css_path. By now the
# method simply checks for the path to be absolute and in case it returns
# it in absolute form
#
# this method is to be considered as private

    proc jscript_path {script_path} {
        set js_uri $script_path

        if {$::rivetweb::rewrite_links} {
            
            set rwcode [::rivet::var_qs get $::rivetweb::rewrite_par]
            ::rivetweb::rewrite_js_url $rwcode [::rivet::env SCRIPT_NAME] $js_uri js_uri


        } 

        return $js_uri
    }
    namespace export jscript_path

# -- js
#
#
    proc js {jscript_file {attributes ""}} {

        return [::rivet::xml "" [concat script type "text/javascript" src $jscript_file $attributes]]

    }
    namespace export js

# -- javascript
#
# this method should know the whereabouts of the template database. Specific
# templates might have specific javascript code, 
#
    proc javascript {script {attributes ""}} {

        set jscript_file "${::rivetweb::base_templates}/${::rivetweb::template_key}/${script}"
        return [::rivet::xml "" [concat script type "text/javascript" src [::rivetweb jscript_path $jscript_file] $attributes]]
        
        #set xhtml "<script type=\"text/javascript\" src=\"[jscript_path $jscript_file]\""
        #foreach {attrb attrv} $attributes { append xhtml " ${attrb}=${attrv}" }
        #return "$xhtml></script>"

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
