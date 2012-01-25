#
# -- XMLMenu: Data source responsible for reading
# menu data from <website-root>/sitemap/ and talk
# to the sitemap manager to build a menu tree
#
#

package require tdom
package require rwconf
package require rwlogger
package require rwsitemap


namespace eval ::XMLMenu {
    variable sitemap
    variable timestamp      0
    variable sitemap_stat   

    proc init {xmlpath} {
        variable sitemap
        variable sitemap_stat   

        array set sitemap_stat {}

        set sitemap [file normalize [file join $::rivetweb::site_base $xmlpath]]

        if {![file isdirectory $sitemap]} {

            return -code error  -error_code invalid_path \
                                -errorinfo  "Wrong path $sitemap" \
                                            "Wrong path $sitemap"

        }

        set lastaccess 0

    }

    proc has_updates {} {
        variable timestamp
        variable sitemap

        file stat $sitemap  sitemap_stat

        $::rivetweb::logger log debug " menu timestamp t1: $sitemap_stat(mtime), t2: $timestamp"
        if {($sitemap_stat(mtime) > $timestamp)} { 

            return true
        }

        return false
    }

    proc loadsitemap {sitemap_mgr} {
        variable sitemap
        variable sitemap_stat
        variable timestamp

        set logger $::rivetweb::logger
        $logger log info "recreating sitemap"

        file stat $sitemap  sitemap_stat
        set timestamp $sitemap_stat(mtime) 

        array unset xmlmenu

# This object assumes the files to be in the 'sitemap' directory
# (its existence has been checked in 'init')

        set xmlmenus [glob [file join $sitemap *.xml]]

        foreach xmlfile $xmlmenus {
            $logger log info "reading $xmlfile...."

            set xml [read_file $xmlfile]

            set map [file tail $xmlfile]
            if {[catch { set xmlmenu($map) [dom parse $xml] } e]} {
                $logger log alert "could not parse map $map: $e"
            }
        }
# 
        set menumodel $::rivetweb::menumodel

        foreach mdoc [array names xmlmenu] {
#           set rootel      [$xmlmenu($mdoc) documentElement root]
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
                    
                    set group_menu_list {}

                    foreach menu [$sm getElementsByTagName menu] {
                        if {$::rivetweb::debug} {
                            foreach cn [$menu childNodes] {
                                $logger log debug "  $menu: [$cn nodeName] - [$cn asXML]"
                            }                            
                        }

                        if {[$menu hasAttribute id]} {

                            if {[$menu hasAttribute parent]} {
                                set parent  [$menu getAttribute parent]
                            } else {
                                set parent  $group_parent
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

                            $menumodel assign parent menuobj $group_parent

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
                    # we anyway try to determine the language of the datum, regardless it's
                    # meaninful or not
                                
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
#                               puts "-> $ltext $linfo"

                                set linkobj [$lm create $ltype $lref $ltext $linfo]
                                $lm set_attribute linkobj $attributes
                                
                                $menumodel add_link menuobj $linkobj

                            }
                        }
                        lappend group_menu_list $menuobj
                    }

                    $sitemap_mgr add_menu_group $group_parent $group_menu_id $group_menu_list

                } else {

                    $logger log alert "skipping data from $mdoc, missing menu id"

                }
            }
        }

    }

    namespace export loadsitemap init has_updates
    namespace ensemble create
}


package provide XMLMenu 1.0
