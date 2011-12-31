# 
# -- XMLData: Rivetweb's default data source
#
#

package require tdom
package require rwconf
package require rwlogger
package require rwpentry

#namespace eval ::rivetweb {
#    variable site_base [file join [pwd] website]
#    variable default_language en
#    variable static_pages [file join $site_base pages]
#
#    proc buildSimplePage {messaggio cssclass code} {
#        variable default_language
#
#        return [dict create content [dict create \
#                            $default_language page_text $messaggio]]
#    }
#
#}

namespace eval ::XMLData {
    variable xmlpath

    proc init {} {
        variable xmlpath

        set xmlpath [file join $::rivetweb::site_base pages]
    }

    proc buildPageEntry {key xmldata reassigned_key} {
        upvar $reassigned_key rkey

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
        foreach c [$domroot child all] {
            switch [$c tagName] {
                content {
                    continue
                }
                menu {

                    dict set menu_d menu [$c getAttribute position left] [$c text]

                }
                default {
                    lappend metadata_l [$c tagName] [$c text]
                }
            }
        }

#       puts "<pre>metadata_l: $metadata_l</pre>"
        set pageentry [$::rivetweb::pentry create]
#       dict set pagedict metadata [eval dict create $metadata_l]
        $::rivetweb::pentry set_metadata pageentry $metadata_l
        $::rivetweb::pentry put_metadata pageentry $menu_d
#       puts "<pre>menu_l: $menu_d</pre>"

        foreach content [$domroot getElementsByTagName content] {
            if {[$content hasAttribute language]} {
                set clang [$content getAttribute language]
            } else {
                set clang $::rivetweb::default_lang
            }

            foreach c [$content childNodes] {
                set node_name [$c nodeName]
                if {$node_name == "pagetext"} {

# creiamo un nuovo dom
            
                    set cdom [dom parse [$c asXML]]
#                   dict set pagedict content $clang pagetext $cdom
                    $::rivetweb::pentry add_content pageentry $clang pagetext $cdom
                } else {

#                   dict set pagedict content $clang $node_name [$c text]
                    $::rivetweb::pentry add_content pageentry $clang $node_name [$c text]
                }
            }
        }

        return $pageentry
    }

    proc fetchData {key reassigned_key} {
        upvar $reassigned_key rkey
        variable xmlpath

        set xmlfile [file join $::rivetweb::static_pages ${key}.xml]
#       apache_log_error info "->opening $xmlfile" 

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
            return -code error -errorcode not_existing \
                   -errorinfo $notexisting_msg $notexisting_msg
        }
    }

    proc synchData {key data_dict} {

    }

    proc dispose {key} {


    }

    namespace export   init
    namespace export   fetchData
    namespace export   synchData

    namespace ensemble create
}

package provide XMLData 0.1
