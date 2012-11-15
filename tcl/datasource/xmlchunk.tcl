#
# -- XMLBase
#
# Base unified datasource model. This model reads sitemap files to 
# build a menu tree and reads XML data from files to build pages objects
#
#

package require tdom
package require rwconf
package require rwlogger
package require rwsitemap
package require rwstatic
package require rwsitemap

# temporary variable names
#
# - sitemap_dir -> Path to sitemap dir
# - timestamp -> saved timestamp of the sitemap dir
# - sitemap_stat -> [file stat] info for sitemap dir
# - xmlpath -> path to xml pages
#

namespace eval ::XMLBase {
    variable sitemap
    variable sitemap_dir        sitemap
    variable timestamp          0
    variable sitemap_stat   
    variable xmlpath
    variable current

    proc init {args} {
        variable xmlpath
        variable sitemap
        variable sitemap_dir
        variable sitemap_stat   

# we first set up the variables controlling the sitemap

        array set sitemap_stat {}

# let's rewrite the patg to the sitemap

        set sitemap_dir [file normalize [file join $::rivetweb::site_base $sitemap_dir]]

        if {![file isdirectory $sitemap_dir]} {
            
            $::rivetweb::logger log notice "Wrong path for sitemap ($sitemap_dir)"

            return -code error  -error_code invalid_path            \
                                -errorinfo  "Wrong path $sitemap_dir"   \
                                            "Wrong path $sitemap_dir"
        } else {
            $::rivetweb::logger log notice "setting sitemap path as $sitemap_dir"
        }
        
# and the we set the path to the XML pages

        set xmlpath [file join $::rivetweb::site_base pages]

        set sitemap [::rwsitemap::create ::XMLBase]
        $sitemap sitemap_reload
    }

#
# -- willHandle
#
# fundamental method that has to return a string to work as a unique 
# key in the website database.
# If the datasource is not to handle the request the procedure has
# to return with a -status continue
#

    proc willHandle {arglist keyvar} {
        upvar $keyvar key 

        set retcode break
        set errorcode rw_ok
        set key     index

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

    proc buildPageEntry {key xmldata reassigned_key} {
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
        dict append menu_d $metadata_l
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

    proc time_reference {key} {

        set xmlfile [file join $::rivetweb::static_pages ${key}.xml]
        file stat $xmlfile file_stat
        return $file_stat(mtime)

    }

# -- is_stale
#
# returns a boolean condition if the resource linked to 'key' has
# to be refreshed
#
    proc is_stale {key timereference } {
        
        set current_timeref [time_reference $key]
        return [expr $timereference < $current_timeref]
    }

# -- fetchData 
#
# This method retrieves a page content from the backend. This implementation
# looks for an XML file in the website directory tree (::rivetweb::static_pages). 
#
#

    proc fetchData {key reassigned_key} {
        upvar $reassigned_key rkey
        variable xmlpath

        set xmlfile [file join $::rivetweb::static_pages ${key}.xml]
        $::rivetweb::logger log info "->opening $xmlfile" 

        if {[file exists $xmlfile]} {
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

# -- synchData
#
# I should do something with this and make Rivetweb capable of storing new content
#

    proc synchData {key data_dict} {

    }

    proc dispose {key} {

    }

    proc has_updates {} {
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

    proc listStaticMenus {sm parent_mg} {
        
        set menumodel $::rivetweb::menumodel
        set group_menu_list {}

        foreach menu [$sm getElementsByTagName menu] {
            if {$::rivetweb::debug} {
                foreach cn [$menu childNodes] {
                    $::rivetweb::logger log debug "  $menu: [$cn nodeName] - [$cn asXML]"
                }                            
            }

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

                set menuobj [$menumodel create  [$menu getAttribute id]     \
                                                $parent                     \
                                                $visibility                 ]

    # Elements within 'menu' are <title lang="..">...</title> and
    # one or more <link>....</link>

                set headers [$menu getElementsByTagName title]
                foreach title $headers {

                    if {[$title hasAttribute lang]} {
                        set language [$title getAttribute lang]
                    } else {
                        set language $::rivetweb::default_lang
                    }

                    $menumodel assign title menuobj [$title text] $language
                }

                $menumodel assign parent menuobj $parent_mg

                set links [$menu getElementsByTagName link]
                set lm    $::rivetweb::linkmodel         
                foreach l $links {

                    set ltype internal
                    set lref  index
                    set linfo [dict create]
                    set ltext [dict create]
                    set attributes {}
                    foreach linkdata [$l childNodes] {

        # In order not to replicate the same snippet of code
        # we anyway try to determine the language of the link, 
        # regardless it's meaninful or not
                    
                        if {[$linkdata hasAttribute lang]} {
                            set language [$linkdata getAttribute lang]
                        } else {
                            set language $::rivetweb::default_lang
                        }

                        set tagname [$linkdata tagName]
                        switch $tagname {
                            text {
                                dict set ltext $language [$linkdata text]
                                foreach infoel [$linkdata getElementsByTagName info] {
                                    dict set linfo $language [$infoel text]
                                }
                            }
                            type {
                                set ltype [$linkdata text]
                            }
                            url -
                            reference {
                                set lref   [$linkdata text]
                            }
                            default {
                                lappend attributes $tagname [$linkdata text]
                            }
                        }
                    }
#                   puts "-> $ltext $linfo"

                    set linkobj [$lm create $ltype $lref $ltext $linfo]
                    $lm set_attribute linkobj $attributes
                    
                    $menumodel add_link menuobj $linkobj
                }
            }
            lappend group_menu_list $menuobj
        }
        return $group_menu_list
    }

# -- loadsitemap
#
# Must call the sitemap manager methods to build (update) a sitemap 
#
#

    proc loadsitemap {sitemap_mgr {ctx ""}} {
        variable sitemap_dir
        variable sitemap_stat
        variable timestamp

        set logger $::rivetweb::logger
        $logger log info "recreating sitemap"

        file stat $sitemap_dir  sitemap_stat
        set timestamp $sitemap_stat(mtime) 

        array unset xmlmenu

# This object assumes the files to be in the 'sitemap_dir' directory
# (its existence has been already checked in 'init')

        set xmlmenus [glob [file join $sitemap_dir *.xml]]

        foreach xmlfile $xmlmenus {
            $logger log info "reading $xmlfile...."

            set xml [read_file $xmlfile]

            set map [file tail $xmlfile]
            if {[catch { set xmlmenu($map) [dom parse $xml] } e]} {
                $logger log alert "could not parse map $map: $e"
            }
        }

        foreach mdoc [array names xmlmenu] {
            set sitemenus   [$xmlmenu($mdoc) getElementsByTagName sitemenus]
            
            $logger log info "analyzing data for $mdoc...."
            foreach sm $sitemenus {

                if {[$sm hasAttribute id]} {
                    set group_menu_id       [$sm getAttribute id]
                    if {[$sm hasAttribute parent]} {
                        set group_parent    [$sm getAttribute parent]
                    } else {
                        set group_parent    root
                    }
                    $logger log debug "group parent set as $group_parent"

                    switch [$sm hasAttribute class] {

                        dynamic {
                            set functor [lindex [$sm getElementsByTagName functor] 0]
                            set functor [$functor text]

                            if {[catch {
                                $sitemap_mgr add_menu_group $group_parent $group_menu_id \
                                                            [${functor}::loadSiteMap $sm $group_parent]
                            } e]} {
                                $logger log err "dynamic menu error for functor $functor: $e"
                            } 
                        }                       

                        default {
                            $sitemap_mgr add_menu_group $group_parent $group_menu_id \
                                                    [listStaticMenus $sm $group_parent]
                        }
                    }

                } else {

                    $logger log alert "skipping data from $mdoc, missing menu id"

                }
            }
        }
    }

    proc menu_list {page} {
        variable sitemap 

#       puts "<br/><b>pmodel</b>: $page"
#       puts "<br/><b>ds</b>: [$page metadata datasource]"
        if {[$page metadata datasource] == "::XMLBase"} {
            set menul [$page metadata menu]
        } else {
            set menul [dict create left main]
        }

        set menudb [dict create]
        foreach {group menuid} $menul {

            dict set menudb $group [$sitemap menu_list $menuid]

        }

#       puts "<br/>$menul<br/>"
#       puts "<br/>$menudb<br/>"

        return $menudb
    }

    namespace export init fetchData synchData time_reference is_stale
    namespace export loadsitemap init has_updates willHandle
    namespace export menu_list
    namespace ensemble create
}

package provide XMLBase 1.0
