# -- XMLData: Rivetweb's default data source
#
# Basic datasource implementation
#
#

package require tdom
package require rwconf
package require rwlogger
package require rwpmodel

namespace eval ::XMLData {
    variable xmlpath

    proc init {} {
        variable xmlpath

        set xmlpath [file join $::rivetweb::site_base pages]
    }

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

        set newpage [$::rivetweb::pmodel create]
        $::rivetweb::pmodel set_metadata newpage $metadata_l
        $::rivetweb::pmodel put_metadata newpage $menu_d

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
                    $::rivetweb::pmodel set_content newpage $clang pagetext $cdom

                } else {

                    $::rivetweb::pmodel set_content newpage $clang $node_name [$c text]

                }
            }
        }

        return $newpage
    }

# -- time_reference 
#
#

    proc time_reference {key} {

        set xmlfile [file join $::rivetweb::static_pages ${key}.xml]
        file stat $xmlfile file_stat
        return $file_stat(mtime)

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
# I should do something with this and
# make Rivetweb capable of storing new content
#

    proc synchData {key data_dict} {

    }

    proc dispose {key} {

    }

    namespace export init fetchData synchData time_reference
    namespace ensemble create
}

package provide XMLData 0.1
