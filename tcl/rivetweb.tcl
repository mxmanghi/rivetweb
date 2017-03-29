# -- rivetweb
#
# The core functions of Rivetweb
#
#

# starting with this branch we require Tcl 8.6

package require Tcl 8.6

package require rwconf
package require rwebdb
package require rwlogger

package require rwlink
package require rwmenu
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
        upvar $resource_key_var key

        foreach ds $::rivetweb::datasources {
            $ds willHandle $urlencoded_pars key
        }

        return $ds
    }

# -- rewrite_as_relative
#
# this procedure must be superseded by application an application
# specific procedure.
#
#

    proc rewrite_as_relative {rwcode urlscript path_to_file rw_path} {
        upvar $rwn_path rewritten_path

        set rewritten_path $path_to_file
    }

# base methods for url rewriting. This procedures can be 
# superseded by application specific code and should
# go into a class to preserve the basic functionality and
# extend them through subclassing

    proc rewrite_css_url {rwcode urlscript css_path rewritten_css_url} {
        upvar $rewritten_css_url rwcss

        #set rwcss "/$css_path"
        
        rewrite_as_relative $rwcode $urlscript $css_path rwcss
    }
    namespace export rewrite_css_url

# rewrite_js_url

    proc rewrite_js_url {rwcode urlscript js_path rewritten_js_url} {
        upvar $rewritten_js_url rwjs

        #set rwjs "/${js_path}"

        rewrite_as_relative $rwcode $urlscript $js_path rwjs
    }
    namespace export rewrite_js_url

# -- rewrite_url
#
#

    proc rewrite_url {rwcode urlscript urlargs rewritten_base} {
        upvar $rewritten_base rrbase

        set rrbase $urlscript

    }
    namespace export rewrite_url

# -- rewrite_pict_path
#
#
    proc rewrite_pict_path {rwcode urlscript pict_path rewritten_pict_uri} {
        upvar $rewritten_pict_uri rewritten_uri

        #set rewritten_uri $urlscript
        rewrite_as_relative $rwcode $urlscript $pict_path rewritten_uri
    }
    namespace export rewrite_pict_path

# -- rewrite_generic_path
#
#

    proc rewrite_generic_path {path_to_file} {

        if {$::rivetweb::rewrite_links} {
            set rwcode [::rivet::var_qs get $::rivetweb::rewrite_par]
            ::rivetweb::rewrite_as_relative $rwcode [::rivetweb::scriptName] $path_to_file rewritten_url
        } else {
            set rewritten_url $path_to_file
        }

        return $rewritten_url
    }


# -- scriptName 
#
#

    proc scriptName {} { return [::rivet::env SCRIPT_NAME] }


# -- composeUrl
# 
# this function should consistently build links 
#
    proc composeUrl {args} {

        set arglist $args
        if {$::rivetweb::rewrite_links} {

            set rwcode [::rivet::var_qs get $::rivetweb::rewrite_par]
            ::rivetweb::rewrite_url $rwcode [::rivetweb::scriptName] arglist rewritten_url

        } else {

            set rewritten_url [::rivetweb::scriptName]

        }

        array set argsmap {}
        set hash ""
        while {[llength $arglist]} {
            set arglist [lassign $arglist param value]
            if {$param == "#"} { 
                set hash $value 
                continue
            }

            set argsmap($param) [::rivet::escape_string $value]
        }

        set arglist [array get argsmap]

        # finally we blend sticky arguments into the arguments 

        set arglist [::rivetweb merge_sticky_args $arglist]
        set urlargs {}

        ::rivet::apache_log_error debug "URL $rewritten_url -> $arglist"
        if {[llength $arglist]} {

            while {[llength $arglist]} {
                set arglist [lassign $arglist param value]
                lappend urlargs "${param}=${value}"
            }
            set final_url "${rewritten_url}?[join $urlargs "&"]"
        } else {
            set final_url $rewritten_url
        }

        if {$hash != ""} {append final_url "#$hash" }

        return $final_url
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
    namespace export make_css_path


# -- csspath 
#
# the templates database is supposed to store the whole dataset needed to build 
# any reference to a theme related piece of information, thus we can fetch the css
# filename by using simply the key to the template.
# 
# The procedure assumes the template files are stored in subdirectory bearing the
# same name as the template key.
#

    proc csspath {template_key {specific_file ""}} {
    
        if {$specific_file == ""} {

            set css_file_name [dict get $::rivetweb::templates_db $template_key css]
            set css_file_path [file join $::rivetweb::css_path $template_key $css_file_name] 

        } else {

            set css_file_path [file join $::rivetweb::css_path $template_key $specific_file]

        }
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

    }
    namespace export css


# -- makePictsPath
#
# search 'picts_file' in the graphic files search path sequence
#

    proc makePictsPath {picts_file {style_dir ""}} {
        set pict_file [findPictureFile $picts_file $style_dir] 
        if {$::rivetweb::rewrite_links} {
            set rwcode [::rivet::var_qs get $::rivetweb::rewrite_par]
            ::rivetweb::rewrite_pict_path $rwcode [::rivetweb::scriptName] $pict_file rewritten_path
            return $rewritten_path
        } else {
            return [file join / $pict_file]
        }
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

# -- select_template
#
#   template selection mechanism encapsulated within this function
#   to allow applications to implement their own template selection
#

    proc select_template {template_key} {  }
    namespace export select_template

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
        return [::rivet::xml "" \
            [concat script type "text/javascript" src [::rivetweb jscript_path $jscript_file] $attributes]]

    }
    namespace export javascript


# -- thisClass 
#
# returns a class="classname" attribute when we are generating
# a specific page. Useful in selectors both in forms or templates to highlight
# an element.
#
# Deprecated in favor of select_html_class
#
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

# -- select_html_class

    proc select_html_class {page_obj page_reference class_selected {class_unselected ""}} {
        return [::rivetweb::thisClass [$page_obj key] $page_reference $class_selected $class_unselected]
    }

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
                append htmltext [$menuobj toHTML $htmldefs]    
            }
        }
        return $htmltext
    }
    namespace export build_html_menu

# -- set_rewrite_par
#
#   method to change the url argument that triggers the URI rewriting
#  We need a method, not just a variable because the 'passthroughs' 
#  list need update (a strong indication that we need to move to a class)
#
    proc set_rewrite_par {rw_par} {
        variable rewrite_par
        variable passthroughs

        set rewrite_par     $rw_par
        set passthroughs    [list lang language reset template $rewrite_par]
    }
    namespace export set_rewrite_par

# -- merge_sticky_pars
#
#
    proc merge_sticky_args {urlargs} {
        variable passthroughs
        variable rewrite_par
        variable rewrite_links

        foreach sticky_arg $passthroughs {

            # we skip ::rivetweb::rewrite_par if we are alredy rewriting links
            # as the whole point of link rewriting is charging mod_rewrite rules 
            # to figure it out

            if {$rewrite_links && \
                ($sticky_arg == $rewrite_par)} { continue }

            if {[::rivet::var_qs exists $sticky_arg] & ![dict exists $urlargs $sticky_arg]} {
                dict set urlargs $sticky_arg [::rivet::var_qs get $sticky_arg]
            }
        }

        return $urlargs
    }
    namespace export merge_sticky_args


    proc strip_sticky_args {urlargs} {
        variable passthroughs

        set urlargs_d [dict create {*}$urlargs]

        return [dict remove $urlargs_d {*}$::rivetweb::passthroughs]
    }
    namespace export strip_sticky_args

# -- search_datasources
#
# recusive search of a page through the datasource list. 
#

    proc search_datasources {key returned_key datasrc} {
        upvar $returned_key rkey
        upvar $datasrc datasource

        # this cycle is guaranteed to return a page, al least 
        # through the last datasource in the chain (::RWDummy)

        foreach ds $::rivetweb::datasources {
            ::rivet::apache_log_error info "querying $ds for $key"

            set rkey $key           
            if {[$ds will_provide $key rkey]} {
                ::rivet::apache_log_error info \
                    "fetching $key from $ds -> returned values: $rkey"

                set pmodel [$ds fetch_page $key rkey]
                if {$pmodel != ""} {
                    set datasource  $ds
                    return          $pmodel
                } else {
     
                    if {[string match $key $rkey]} {
                        set rkey wrong_datasource_returned_key
                        return [::RWDummy fetchData $key rkey]
                    }

                    return [search_datasources $rkey rkey datasource]
                }

            } else {

                if {($rkey != "") && ($key != $rkey)} {
                    return [search_datasources $rkey rkey datasource]
                }

            }
        }
    }
    namespace export search_datasources

    # -- default_template
    # 
    # template selection
    #
    proc select_template {} {
        variable default_template

        return $default_template
    }

    namespace ensemble create
}

package provide rivetweb 2.0
