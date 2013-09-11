#
# -- XMLBase
#
# Base unified datasource model. This model reads sitemap files to 
# build a menu tree and reads XML data from files to build pages objects
#
#

package require Itcl
package require tdom
package require rwconf
package require rwlogger
package require rwsitemap
package require rwstatic
package require rwsitemap
package require rwmenu
package require rwlink
package require Datasource
package require struct::stack

# temporary variable names
#
# - sitemap_dir -> Path to sitemap dir
# - timestamp -> saved timestamp of the sitemap dir
# - sitemap_stat -> [file stat] info for sitemap dir
# - xmlpath -> path to xml pages
#

namespace eval ::rwdatas {

    ::itcl::class XMLBase {
        inherit Datasource

        private variable sitemap
        private variable sitemap_dir        sitemap
        private variable static_pages       pages
        private variable local_pages	    docs
        private variable timestamp          0
        private variable sitemap_stat   
        private variable xmlpath
        private variable current

        private method buildPageEntry {key xmldata reassigned_key}
        private method time_reference {key} 
        private method listStaticMenus {sm parent_mg}
        
        public method init {args}
        public method willHandle {arglist keyvar}
        public method fetchData {key reassigned_key}
        public method is_stale {key timereference}
        public method has_updates {} 
        public method name {} { return "XMLBase" }
        public method load_sitemap {sitemap_mgr {ctx ""}}
        public method menu_list {page} 
        public method resource_exists {resource_key {translated_key translated_key}} { return false }
        public method to_url {lm}
        public method makeUrl {reference} 
    }

    ::itcl::body XMLBase::init {args} {

        set ::rwdatas::static_pages $static_pages
        set ::rwdatas::local_pages  $local_pages
# we first set up the variables controlling the sitemap

        array set sitemap_stat {}

# let's rewrite the patg to the sitemap

        set sitemap_dir  [file normalize [file join $::rivetweb::site_base $sitemap_dir]]
        set static_pages [file normalize [file join $::rivetweb::site_base $static_pages]]

        if {![file isdirectory $sitemap_dir]} {

            $::rivetweb::logger log notice "Wrong path for sitemap ($sitemap_dir)"

            return -code error  -error_code invalid_path                \
                                -errorinfo  "Wrong path $sitemap_dir"   \
                                            "Wrong path $sitemap_dir"
        } else {

            $::rivetweb::logger log notice "setting sitemap path as $sitemap_dir"

        }
        
# and the we set the path to the XML pages

        set xmlpath [file join $::rivetweb::site_base pages]

        set sitemap [::rwsitemap::create ::XMLBase]
        load_sitemap $sitemap
    }

#
# -- willHandle
#
# fundamental method that has to return a string to work as a unique 
# key in the website database.
# If the datasource is not to handle the request the procedure has
# to return with a -status continue
#

    ::itcl::body XMLBase::willHandle {arglist keyvar} {
        upvar $keyvar key 

        set retcode     break
        set errorcode   rw_ok
        set key         index

        if {[dict exists $arglist show]} {
            set key [dict get $arglist show]
        }

        $::rivetweb::logger log info "mapping key $key for processing"

        return -code $retcode -errorcode $errorcode 
    }

#
# -- buildPageEntry
#
#
#

    ::itcl::body XMLBase::buildPageEntry {key xmldata reassigned_key} {
        upvar $reassigned_key rkey

        $::rivetweb::logger log debug "getting data for key $key"

        set xmldom [dom parse $xmldata]
        set domroot [$xmldom documentElement root]
        if {[$domroot hasAttribute id]} {
            set rkey [$domroot getAttribute id]
            set key  $rkey
        } else {
            set rkey $key
        }

        set menu_d      [dict create]
        set metadata_l  {}

# metadata are stored accordingly. <menu>...</menu> elements
# receive a special treatment and go into the menu_d dictionary
# before they get into the page metadata

        foreach c [$domroot child all] {
            switch [$c tagName] {
                content {
                    continue
                }
                menu {
                    if {[$c hasAttribute position]} {
                        set position [$c getAttribute position]
                    } else {
                        set position $::rivetweb::menu_default_pos
                    }
                    dict set menu_d menu [$c getAttribute position $position] [$c text]
                }
                default {
                    lappend metadata_l [$c tagName] [escape_shell_command [$c text]]
                }
            }
        }

        set newpage [::rwpage::RWStatic ::#auto $key]
#       puts "<br/>[html $metadata_l b u]"
#       $::rivetweb::pmodel set_metadata newpage $metadata_l
        set menu_d [dict merge $menu_d [dict create {*}$metadata_l]]
        $newpage put_metadata $menu_d
        $newpage add_metadata datasource ::XMLBase

# data are scanned for <content>...</content> elements to be stored in the page object 'newpage'

        foreach content [$domroot getElementsByTagName content] {

            if {[$content hasAttribute language]} {
                set clang [$content getAttribute language]
            } else {
                set clang $::rivetweb::default_lang
            }

            foreach c [$content childNodes] {

# adding content for language '$clang'

                set node_name [$c nodeName]

                if {$node_name == "pagetext"} {

# creiamo un nuovo dom

                    set cdom [dom parse [$c asXML]]
                    $::rivetweb::logger log info "Adding content for language $clang ($key)"
                    $newpage set_content $clang pagetext $cdom

                } else {

                    $newpage set_content $clang $node_name [$c text]

                }
            }
        }

        return $newpage
    }

# -- time_reference 
#
# time reference might eventually disappear from the public interface as
# the datasource interface is going to bear the whole responsability
# for determining which method has to be used to tell whether a resource
# needs to be refreshed.

    ::itcl::body XMLBase::time_reference {key} {

        set xmlfile [file join $static_pages ${key}.xml]
        file stat $xmlfile file_stat
        return $file_stat(mtime)

    }

# -- is_stale
#
# returns a boolean condition if the resource linked to 'key' has
# to be refreshed
#
    ::itcl::body XMLBase::is_stale {key timereference } {
        
        set current_timeref [time_reference $key]
        return [expr $timereference < $current_timeref]

    }

# -- resourceExists
#
#

    ::itcl::body XMLBase::resource_exists {key {translated_key translated_key}} {
        variable static_pages
        upvar $translated_key xmlfile

        set xmlfile [file join $static_pages ${key}.xml]
        return [file exists $xmlfile]
    }


# -- fetchData 
#
# This method retrieves a page content from the backend. This implementation
# looks for an XML file in the website directory tree ( now ::XMLBase::static_pages). 
#
#

    ::itcl::body XMLBase::fetchData {key reassigned_key} {
        upvar $reassigned_key rkey
        variable xmlpath

        if {[$this resource_exists $key xmlfile]} {
            $::rivetweb::logger log info "->opening $xmlfile" 
            if {[catch {
                set xmlfp    [open $xmlfile r]
                set xmldata  [read $xmlfp]
                set xmldata  [regsub -all {<\?} $xmldata {\&lt;?}]
                set xmldata  [regsub -all {\?>} $xmldata {?\&gt;}]
#               puts stderr $xmldata
                close $xmlfp
            } fileioerr]} {
                set page_id errore_interno
                set notfound_msg "It was impossible to open the requested page ($fileioerr)"
                $::rivetweb::logger err "[pid] $notfound_msg"
                return [::rivetweb::buildSimplePage $notfound_msg message internal_error]
            } else {
                set pagedbentry [buildPageEntry $key $xmldata rkey]
                return $pagedbentry
            }
        } else {
            $::rivetweb::logger log info "$xmlfile not found"
            set notexisting_msg "The requested page does not exist"
#           return [::rivetweb::buildSimplePage $notexists_msg message $page_id]
            return -code error  -errorcode not_existing         \
                                -errorinfo $notexisting_msg     $notexisting_msg
        }
    }

    ::itcl::body XMLBase::has_updates {} {
        variable timestamp
        variable sitemap_dir

        file stat $sitemap_dir sitemap_stat

        $::rivetweb::logger log debug " menu timestamp t1: $sitemap_stat(mtime), t2: $timestamp"
        if {($sitemap_stat(mtime) > $timestamp)} { 

            return true
        }

        return false
    }

# -- listStaticMenus
#
# foreach group in a menu group a 


    ::itcl::body XMLBase::listStaticMenus {sm parent_mg} {
        
        set menumodel $::rivetweb::menumodel
        array set group_menu_list {}

        foreach menu [$sm getElementsByTagName menu] {
            foreach cn [$menu childNodes] {
                $::rivetweb::logger log debug "  $menu: [$cn nodeName] - [$cn asXML]"
            }                            

# again, menus without an id are ignored. 
# How can we be sure to avoid id definition clashes?
# This is an issue to be tackled and solved....

            if {[$menu hasAttribute id]} {

                if {[$menu hasAttribute parent]} {
                    set parent  [$menu getAttribute parent]
                } else {
                    set parent  $parent_mg
                }

                if {[$menu hasAttribute visibility]} {
                    set visibility [$menu getAttribute visibility]
                } else {
                    
                    if {[$menu hasAttribute type]} {
                        set visibility [$menu getAttribute type]
                    } else {
                        set visibility normal
                    }

                }

# create_menu is a 'static' menu of class RWMenu

                set menuobj [$menumodel create_menu [$menu getAttribute id]  \
                                                     $parent                 \
                                                     $visibility]

    # Elements within 'menu' are <title lang="..">...</title> and
    # one or more <link>....</link>

                set headers [$menu getElementsByTagName title]
                foreach title $headers {

                    if {[$title hasAttribute lang]} {
                        set language [$title getAttribute lang]
                    } elseif {[$title hasAttribute language]} {
                        set language [$title getAttribute language]
                    } else {
                        set language $::rivetweb::default_lang
                    }

                    $menuobj assign title [$title text] $language
                }

                $menuobj assign parent $parent_mg

        # links are interpreted here. A link obj should be created
        # for each of them using the linkmodel interface

                set links [$menu getElementsByTagName link]
                set lm    $::rivetweb::linkmodel
                foreach l $links {

                    set ltype internal
                    set lref  index
                    set linfo [dict create]
                    set ltext [dict create]
                    set largs [dict create]
                    set attributes {}
                    set doctarget ""
                    foreach linkdata [$l childNodes] {


        # In order not to replicate the same snippet of code
        # we anyway try to determine the language of the link, 
        # regardless it's meaninful or not
                    
                        if {[$linkdata hasAttribute lang]} {
                            set language [$linkdata getAttribute lang]
                        } elseif {[$linkdata hasAttribute language]} {
                            set language [$linkdata getAttribute language] 
                        } else {
                            set language $::rivetweb::default_lang
                        }

                        set lowner    [$this name]
                        set tagname   [$linkdata tagName]
                        switch $tagname {
                            text {
                                dict set ltext $language [$linkdata text]
                                foreach infoel [$linkdata getElementsByTagName info] {
                                    dict set linfo $language [$infoel text]
                                }
                            }
                            datasource 
                            {
                                set lowner [$linkdata text]
                            }
                            type {
                                set ltype [$linkdata text]        
                            }
                            url -
                            reference {
                                set lref [$linkdata text]
                            }
                            args {
                                foreach argument [$linkdata getElementsByTagName param] {
                                    if {[$argument hasAttribute value]} {
                                        dict set largs [$argument text] [$argument getAttribute value]
                                    }
                                }
                            }
                            doctarget {
                                set doctarget [$linkdata text]
                            }
                            default {
                                lappend attributes $tagname [$linkdata text]
                            }
                        }
                    }

                    set linkobj [$lm create $lowner $lref $ltext $largs $linfo]
                    $lm set_attribute linkobj [concat $attributes type $ltype]
                    if {$doctarget != ""} { $lm set_urltarget linkobj $doctarget }
                    $menuobj add_link $linkobj
                }

            # checking 'position' attribute

                if {[$menu hasAttribute position]} {
                    set position [$menu getAttribute position]
                    $::rivetweb::logger log debug "$menuobj has position $position"
                    if {[string is integer $position]} {
                        lappend group_menu_list($position) $menuobj
                    } else {
                        lappend group_menu_list(1000) $menuobj
                    }
                } else {
                    lappend group_menu_list(1000) $menuobj
                }
            }
        }

        $::rivetweb::logger log debug "->collected menus [array get group_menu_list]"
        set positions [lsort -integer [array names group_menu_list]]
        set group_list {} 
        foreach group_pos $positions { lappend group_list {*}$group_menu_list($group_pos) }

        return $group_list
    }

# -- load_sitemap
#
# Must call the sitemap manager methods to build (update) a sitemap 
#
#

    ::itcl::body XMLBase::load_sitemap {sitemap_mgr {ctx ""}} {
        variable sitemap_dir
        variable sitemap_stat
        variable timestamp

        set logger $::rivetweb::logger
        $logger log info "recreating sitemap"

        $sitemap_mgr recreate

        file stat $sitemap_dir  sitemap_stat
        set timestamp $sitemap_stat(mtime) 

        array unset xmlmenu

# This object assumes the files to be in the 'sitemap_dir' directory
# (its existence has been already checked in 'init')

        set xmlmenus [glob [file join $sitemap_dir *.xml]]

        foreach xmlfile $xmlmenus {
            $logger log notice "reading $xmlfile..."

            set xml [read_file $xmlfile]
            set map [file tail $xmlfile]
            if {[catch { set xmlmenu($map) [dom parse $xml] } e]} {
                $logger log emerg "could not parse map $map: $e"
            }
        }

        foreach mdoc [array names xmlmenu] {
            
            $logger log info "analyzing data for $mdoc...."

            set sitemenus [$xmlmenu($mdoc) getElementsByTagName sitemenus]
            foreach sm $sitemenus {

# any menu without an id is simply ignored. This should be documented

                if {[$sm hasAttribute id]} {

                    set group_menu_id   [$sm getAttribute id]
                    set group_parent    [$sm getAttribute parent root]
                    
# it seems the position isn't used in any way....

                    if {[$sm hasAttribute position]} {
                        set position [$sm getAttribute position]
                        if {![string is integer $position]} { set position end }
                    }

                    $sitemap_mgr add_menu_group $group_parent $group_menu_id \
                                            [listStaticMenus $sm $group_parent]
                    
                    $logger log notice "adding $group_menu_id to $group_parent"

                } else {

                    $logger log alert "skipping data from $mdoc, missing menu id"

                }
            }
        }
    }

# -- menu_list
#
# XMLBase::menu_list has the special role to provide the base menu 

    ::itcl::body XMLBase::menu_list {page} {
        variable sitemap 

#       puts "<br/><b>pmodel</b>: $page"
#       puts "<br/><b>ds</b>: [$page metadata datasource]"

        if {[has_updates]} {
            load_sitemap $sitemap
        }

        if {[$page metadata datasource] == "::XMLBase"} {

            set menul [$page metadata menu]

        } else {

            set menul [dict create  $::rivetweb::default_menu_pos \
                                    $::rivetweb::default_menu]

        }

        set menudb [dict create]
        foreach {group menuid} $menul {

            dict set menudb $group [$sitemap menu_list $menuid]

        }

        return $menudb
    }

# -- to_url
#
# metodo che deve generare la 

    ::itcl::body XMLBase::to_url {lm} {

        set linkmodel   $::rivetweb::linkmodel
        set link_ref    [$linkmodel reference $lm]
        set ltype [$linkmodel get_attribute $lm type]      
        if {(($ltype == "internal") && [$this resource_exists $link_ref]) || \
            ($ltype == "local") || ($ltype == "external")} {

            set link_descriptor [$this makeUrl $lm]
            set urlargs [dict get $link_descriptor args]
            set href    [dict get $link_descriptor href]
            if {[llength $urlargs]} {
                set urlpars {}
                foreach {attr attrv} $urlargs { lappend urlpars "$attr=$attrv" }
                set href "${href}?[join $urlpars "&"]"
            }

            if {[$linkmodel get_urltarget $lm target]} {
                set href "${href}#$target"
            }

            $linkmodel set_attribute lm [list href $href]
        } else {
            ::rivet::apache_log_error err "Invalid reference $link_ref for data source [$this name]"
            $linkmodel set_attribute lm {href ""}
        }

        return $lm
    }

# -- makeUrl
#
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

    ::itcl::body XMLBase::makeUrl {lm} {

        set linkmodel $::rivetweb::linkmodel
        set reference [$linkmodel reference $lm]
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

            set urlargs [dict create]
            switch [$linkmodel get_attribute $lm type] {
                internal {
                    set href    [env DOCUMENT_URI]
                    dict set urlargs show $reference
                }
                external {
                    set href [$linkmodel reference $lm]
                }
                local {
                    set href [file join [file dirname [env DOCUMENT_URI]] ${local_pages} [$linkmodel reference $lm]]
                }
            }

# URL data composition

            set stored_args [$linkmodel arguments $lm]
            if {[llength $stored_args]} {
                #puts "<div>stored_args: $stored_args</div>"
                set urlargs [dict merge $urlargs [dict create {*}$stored_args]]
            }
	        foreach passthrough $::rivetweb::passthroughs {
		        if {[var_qs exists $passthrough]} {
		            dict set urlargs $passthrough [::rivet::var_qs get $passthrough]
		        }	
	        }

            return [dict create href $href args $urlargs]
        }
    }
}

package provide XMLBase 2.0
