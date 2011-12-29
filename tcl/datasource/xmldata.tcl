# 
# -- XMLData: Rivetweb's default data source
#
#

package require tdom
#package require rwconf

namespace eval ::rivetweb {
    variable site_base [file join [pwd] website]
    variable default_language en
    variable static_pages [file join $site_base pages]

    proc itemSerialize {itemObj} {
        set lista {}
        foreach c [$itemObj child all] {
            lappend lista [$c tagName] [$c text]
        }
        return $lista
    }

    proc buildSimplePage {messaggio cssclass code} {
        variable default_language

        return [dict create content [dict create $default_language page_text $messaggio]]
    }

}

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
        }

        set metadata_l {}
        foreach {tag telem} [::rivetweb::itemSerialize $domroot] {
            if {$tag == "content"} { continue }            
            lappend metadata_l $tag $telem
        }

        set pagedict [dict create]
        dict set pagedict metadata [eval dict create $metadata_l]
        foreach content [$domroot getElementsByTagName content] {
            if {[$content hasAttribute language]} {
                set clang [$content getAttribute language]
            } else {
                set clang $::rivetweb::default_language
            }

            foreach c [$content childNodes] {
                set node_name [$c nodeName]
                if {$node_name == "pagetext"} {

# creiamo un nuovo dom
            
                    set cdom [dom parse [$c asXML]]
                    dict set pagedict content $clang pagetext $cdom

                } else {

                    dict set pagedict content $clang $node_name [$c text]

                }
            }
        }

        return $pagedict
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
#               apache_log_error err "[pid] $notfound_msg"
                return [::rivetweb::buildSimplePage $notfound_msg message internal_error]
            } else {
                set pagedbentry [buildPageEntry $key $xmldata rkey]
                return $pagedbentry
            }
        } else {
            apache_log_error info "$xmlfile not found"
            set rkey not_existing
            set notexists_msg "The requested page does not exist"
            return [::rivetweb::buildSimplePage $notexists_msg message $page_id]
        }
    }

    proc synchData {key data_dict} {

    }

    namespace export   init
    namespace export   fetchData
    namespace export   synchData

    namespace ensemble create

}

package provide XMLData 0.1
