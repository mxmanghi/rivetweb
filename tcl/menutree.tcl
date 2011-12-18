puts "<html>"
puts "<head></head>"
puts "<body>"
package require tdom

proc walkTree { radice node {eltype "node"} {menu_list {}} } {

    puts "examining node '$node' (type '$eltype') menu_list: '$menu_list'"
 
    set menublock [$radice selectNodes {//sitemenus[@id=$node]}]
    if {$menublock == ""} { return $menu_list }
    if {[$menublock hasAttribute parent]} {

        set parent_block [$menublock getAttribute parent]

    } elseif {[$menublock hasAttribute id]} {

        if {[$menublock getAttribute id] == "root"} { set parent_block "" }

    } else {

        return  -code error                                 \
                -errorcode inconsistent_tree                \
                -errorinfo "Struttura menu inconsistente (manca 'radice')" $menu_list

    }

    set ml {}
    foreach cn [$menublock childNodes] {
        if {[$cn nodeName] == "menu"} {
            if {[$cn hasAttribute type]} {
                set tipo [$cn getAttribute type]
            } else {
                set tipo leaf
            }

            if {($tipo == "node") || ($eltype == $tipo)} {
                lappend ml $cn
            }
        }
    }

    eval lappend menu_list $ml

    if {$parent_block == ""} {
        return $menu_list
    } else {
        return [walkTree $radice $parent_block node $menu_list]
    }

}

# experimental script for building a consistent site map
# let's collect the whole set of available menus

source "rivet_defs.tcl"    
source "tcl/rivet_init.tcl"

#lappend auto_path /usr/lib/tcltk/rivet2.0/rivet-tcl/
#lappend auto_path /usr/lib/tcltk/rivet2.0/

namespace eval ::rivetweb { load_env env }

puts "<pre>"

set maps [glob [file join $::rivetweb::sitemap *.xml]]

foreach map $maps {
    puts "reading $map..."

    set xml [read_file $map]
    set xmlmenu([file tail $map]) [dom parse $xml]
}

parray xmlmenu

foreach mdoc [array names xmlmenu] {
    
    set rootel      [$xmlmenu($mdoc) documentElement root]
    set sitemenus   [$xmlmenu($mdoc) getElementsByTagName sitemenus]

    foreach sm $sitemenus {
        if {[$sm hasAttribute id]} {
            set parent ""
            if {[$sm hasAttribute parent]} {
                set parent [$sm getAttribute parent]
            }

            set menublock_id [$sm getAttribute id]

            puts "$mdoc - id: $menublock_id (parent: $parent)"
            
            foreach menu [$sm getElementsByTagName menu] {
                foreach cn [$menu childNodes] {
                    puts "    $menu: [$cn nodeName] - [$cn text]"
                }
            }

            if {$menublock_id == "root"} {
                set root_doc $xmlmenu($mdoc)
            }

            set sitemenus_a($menublock_id) $sm

        } else {
            puts "no id attribute for $sm"
        }
    }
}

foreach blocco_id [array names sitemenus_a] {
    if {$blocco_id == "root"} { continue }
    set sm $sitemenus_a($blocco_id)

    if {[$sm hasAttribute parent]} {
        set p [$sm getAttribute parent]
        if {[info exists sitemenus_a($p)]} {
            domNode $sitemenus_a($p) appendChild $sm
        } else {
            puts "skipping $blocco_id, no parent defined for menu block"
        }
    }

}


# set final_tree [dom createDocumentNode]

puts "<span class=\"box\">[escape_sgml_chars [$sitemenus_a(root) asXML]]</span>"

#foreach m [array names xmlmenu] { $xmlmenu($m) delete }

set menuid level2

if {[var exists menuid]} { set menuid [var get menuid] }

set lv2ml [walkTree $sitemenus_a(root) $menuid leaf]

foreach m $lv2ml { puts "<span class=\"box\">[escape_sgml_chars [htmlMenu $m]]</span>" }

puts "</pre>"

parray server
catch { parray RivetServerConf }

puts "</body>"
puts "</html>"
