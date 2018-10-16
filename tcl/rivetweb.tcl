# -- rivetweb.tcl
#
# The framework's set of core functions 
#
#

# starting with this branch we require Tcl 8.6

package require Tcl 8.6

package require rwconf
package require rwlogger

package require rwlink
package require rwmenu
package require htmlizer

namespace eval ::rivetweb {

# -- registered_handlers
#
# we now try to phase in a management of URL handlers
# that eventually will make them an opaque informatio
# of the rivetweb status

    proc registered_handlers {} {
        return [::rwdatas::UrlHandler::registered_handlers]
    }
    namespace export registered_handlers

# -- notify_url_handlers
#
# Method to be used by pages needing to send signals to URL handlers

    proc notify_url_handlers {signal signal_arguments} {
        
        foreach ds [::rwdatas::UrlHandler::registered_handlers] {
            $ds signal $signal $signal_arguments
        }

    }

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

        foreach ds [::rivetweb registered_handlers] {
            $ds willHandle $urlencoded_pars key
        }

        return $ds
    }

# -- rewrite_as_relative
#
# If an application has to rewrite rules most likely this procedure 
# must be superseded by the application's specific procedure.
#
#

    proc rewrite_as_relative {rwcode urlscript path_to_file rw_path} {
        upvar $rw_path rewritten_path

        if {[string index $path_to_file 0] == "/"} {
            set path_to_file [string range $path_to_file 1 end]
        }
        set rewritten_path $path_to_file
    }

# base methods for url rewriting. This procedures can be 
# superseded by application specific code and should
# go into a class to preserve the basic functionality and
# extend them through subclassing

    proc rewrite_css_url {rwcode urlscript css_path rewritten_css_url} {
        upvar $rewritten_css_url rwcss

        rewrite_as_relative $rwcode $urlscript $css_path rwcss
    }
    namespace export rewrite_css_url

# rewrite_js_url

    proc rewrite_js_url {rwcode urlscript js_path rewritten_js_url} {
        upvar $rewritten_js_url rwjs

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
    namespace export rewrite_generic_path

# -- scriptName 
#
#
    proc scriptName {} { return [::rivet::env SCRIPT_NAME] }

# -- composeUrl
# 
# this function should consistently build links 
#
    proc composeUrl {args} {
        variable rewrite_code
        variable url_composer
            
        return [$url_composer compose_url $args [::rivet::var_qs all] $rewrite_code]
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
            ::rivetweb::rewrite_css_url $rwcode [::rivetweb::scriptName] $css_uri css_uri

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

    proc csspath {template_key {css_file_name ""}} {
    
        if {$css_file_name == ""} {

            set css_file_name [RWTemplate::template $template_key css]

        } 
        set css_file_path [join [list $::rivetweb::css_path $template_key $css_file_name] "/"]
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
# DEPRECATED INTERFACE adopt 'picture_path'

    proc makePictsPath {picts_file {style ""}} { return [::rivetweb::picture_path $picts_file $style] }

    proc picture_path {picts_file {template_dir ""}} {

        if {$template_dir == ""} { set template_dir $::rivetweb::template_key }

        set pict_file [findPictureFile $picts_file $template_dir] 
        if {$::rivetweb::rewrite_links} {
            ::rivetweb::rewrite_pict_path $::rivetweb::rewrite_code \
                                          [::rivetweb::scriptName]  \
                                            $pict_file rewritten_path
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

    proc findPictureFile {picts_file temp_key} {
        ::rivet::apache_log_error debug "style $temp_key , site_base: $::rivetweb::site_base"

# search list for a picts file. 
#
#    - We first try in the template's specific dir
#    - then we try the template picts directory 
#    - then we try in the website root 'picts' directory
#    - last we attempt in the rwbase dir

        set template_picts [::rivetweb::RWTemplate::template $temp_key pictures]
        set template_dir   [::rivetweb::RWTemplate::template $temp_key dir]

        foreach uri [list   [list $::rivetweb::base_templates   \
                                  $template_dir                 \
                                  $template_picts $picts_file]  \
                            [list $::rivetweb::base_templates   \
                                  $template_dir                 \
                                  $picts_file]                  \
                            [list $::rivetweb::picts_path       \
                                  $temp_key                     \
                                  $picts_file]                  \
                            [list $::rivetweb::picts_path $picts_file]] {

            set fn [file join $::rivetweb::site_base {*}$uri]
            ::rivet::apache_log_error debug "[incr pathn] pict file: >$fn<"
            
            if {[file exists $fn]} { 
                return [join $uri "/"] 
            } 
        }

        ::rivet::apache_log_error debug "Image file for: >$picts_file< not found"
        return ""
    }

# -- picture
#
#
    proc picture {pict_name} { return [::rivetweb::findPictureFile $pict_name $::rivetweb::template_key] }

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

        return [::rivet::xml "" [concat script type "text/javascript" src $jscript_file {*}$attributes]]

    }
    namespace export js

# -- javascript
#
# this method should know the whereabouts of the template database. Specific
# templates might have specific javascript code, 
#
    proc javascript {script {attributes ""}} {

        set jscript_file "${::rivetweb::base_templates}/${::rivetweb::template_key}/${script}"
        return [::rivet::xml "" [concat script 	type "text/javascript" \
                                                src  [::rivetweb jscript_path $jscript_file] \
                                                {*}$attributes]]

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

# -- hightlighted_item
#
#   Procedure to generated XHTML code for a list item having the 
#   CSS class selected when the link contained is the one of the
#   page being displayed (will replace thisClass)

    proc highlighted_item {item_xml selected_page selected_url selected_class {unselected_class ""} {item_tag "li"}} {

        if {$selected_page == $::rivetweb::page_key} { 
            return [::rivet::xml $item_xml [list $item_tag class $selected_class] [list a href $selected_url]]
        } elseif { $unselected_class != ""} {
            return [::rivet::xml $item_xml [list $item_tag class $unselected_class] [list a href $selected_url]]
        } else {
            return [::rivet::xml $item_xml [list $item_tag] [list a href $selected_url]]
        }
    }
    namespace export highlighted_item

# -- isDebugging 
#
#

    proc isDebugging { } {
        return [expr $::rivetweb::debug && [::rivet::var exists debug]]
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
# *was* described within the dictionary 'templates_db', now managed through
# the (common) public interface of the RWTemplate class
#
# Arguments:
#
#  - pagemenus: dictionary associating positions and menu objects
#  - template_key: key to the dictionary storing template specific definitions
#  - position: keyword (usually a 'position') specifing role within the page
#

    proc build_html_menu { pagemenus template_key position } {

        set template [::rivetweb::RWTemplate::template $template_key] 
        set htmltext ""
        if {[dict exists $pagemenus $position]} {
            set menus [dict get $pagemenus $position]
            foreach menuobj $menus {    
                append htmltext [$template to_html $menuobj]    
            }
        }
        return $htmltext
    }
    namespace export build_html_menu

# -- set_rewrite_par
#
#  method to change the url argument that triggers the URI rewriting
#  We need a method, not just a variable because the 'sticky_args' 
#  list need update (a strong indication that we need to move to a class)
#
#    proc set_rewrite_par {rw_par} {
#        variable url_composer
#
#        #::rivet::apache_log_error notice "Calling deprecated procedure ::rivetweb set_rewrite_par"
#        $url_composer set_rewrite_par $rw_par
#    }
#    namespace export set_rewrite_par

# -- merge_sticky_args
#
#
    proc merge_sticky_args {urlargs} {
        variable url_composer
        variable rewrite_links
        
        #::rivet::apache_log_error notice "Calling deprecated procedure ::rivetweb merge_sticky_args"
        return [$url_composer merge_sticky_args $urlargs [::rivet::var_qs all] $rewrite_links]
    }
    namespace export merge_sticky_args


    proc strip_sticky_args {urlargs} {
        variable url_composer

        #::rivet::apache_log_error notice "Calling deprecated procedure ::rivetweb strip_sticky_par"
        return [$url_composer strip_sticky_args $urlargs] 
    }
    namespace export strip_sticky_args

# -- search_handler
#
# recusive search of a page through the URL handler list. 
#

    proc search_handler {key returned_key datasrc {excluded_handler ""}} {
        upvar $returned_key rkey
        upvar $datasrc datasource

        # this cycle is guaranteed to return a page, al least 
        # through the last datasource in the chain (::RWDummy)

        set ds [::rwdatas::UrlHandler::start_scan]

        while {$ds != ""} {
            if {($ds == $excluded_handler) && ($ds != "::RWDummy")} { 
                ::rivet::apache_log_error debug "excluding $ds from search for $key"
                set ds  [$ds next_handler]
                continue
            }

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

                    return [search_handler $rkey rkey datasource $ds]
                }

            } else {

                if {($rkey != "") && ($key != $rkey)} {
                    return [search_handler $rkey rkey datasource $ds]
                }

            }
            
            set ds  [$ds next_handler]
        }
        
        return [::RWDummy fetchData page_not_found_error rkey]
    }
    namespace export search_handler

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
        return [::rivetweb template_path [::rivetweb::RWTemplate::template $template_key template] $template_key]

    }
    namespace export template


    # -- default_template
    # 
    # template selection. Accessor to the default database for the
    # current template definition
    #

    proc select_template {} {
        variable default_template

        return $default_template
    }
    namespace export select_template

    proc select_menu {} {
        variable default_menu

        return $default_menu
    }

    proc select_menu_position {} {
        variable default_menu_pos

        return $default_menu_pos
    }

    proc select_language {} {
        variable default_lang

        return $default_lang
    }

    proc default {site_default} {

        set procname "::rivetweb::select_${site_default}"
        if {[info procs $procname] == ""} {
            return ""
        }

        return [eval $procname]
    }
    namespace export default

    proc restore_channel_status {} {
        variable channel_xlation 
        variable channel_encoding

        fconfigure stdout -translation $channel_xlation -encoding $channel_encoding
    }
    namespace export restore_channel_status

    proc save_channel_status {} {
        variable channel_xlation 
        variable channel_encoding

        set channel_xlation  [fconfigure stdout -translation]
        set channel_encoding [fconfigure stdout -encoding]

    }
    namespace export save_channel_status
    
    proc make_error_page {e einfo} {
        set msg "<h4>$e</h4>"
        dict for {f v} $einfo {
            switch $f {
                -errorstack {
                    append msg "<ul>"
                    foreach {level dump} $v {
                        append msg "<li>$level: <pre>$dump</pre></li>"
                    }
                    append msg "</ul>"
                }
                -errorinfo {
                    append msg "<pre>$v</pre>"
                }
                default {
                    append msg "<hr/>$f: $v"
                }
            }
            
        }
        return $msg
    }
    namespace export make_error_page
    
    proc simple_page {key ptext} {
        variable language 

        if {[::RWDummy cache_query $key]} {
            set pobj [::RWDummy get_page_object $key]
            if {[$pobj info class] == "::rwpage::BasicPage"} {
                $pobj pagetext $language $ptext
            }
        } else {
            set pobj [::rwpage::RWBasicPage ::#auto $key $ptext]
            ::RWDummy store_page $key $pobj
        }
        return $pobj
    }
    namespace export simple_page
    
    proc stacktrace {} {
        set stack "Stack trace:\n"
        for {set i 1} {$i < [info level]} {incr i} {
            set lvl [info level -$i]
            set pname [lindex $lvl 0]
            append stack [string repeat " " $i]$pname
            foreach value [lrange $lvl 1 end] arg [info args $pname] {
                if {$value eq ""} {
                    info default $pname $arg value
                }
                append stack " $arg='$value'"
            }
            append stack \n
        }
        return $stack
    }
    namespace export stacktrace
    
    proc handlers_list_tampering {urlhandlers} { return $urlhandlers }
    namespace export handlers_list_tampering

    namespace ensemble create
}

package provide rivetweb 2.0
