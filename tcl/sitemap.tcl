# -- sitemap.tcl: implements a sitemap manager
# 
# The main responsability for the sitemap manager is to 
# build and maintain a tree of menus. 
#

package require struct::tree

namespace eval ::rwsitemap {

# - sitemap keeps the tree object representing the
# website structure, its menus, links and multilanguage
# text definitions. 'sitemap' is a tree of menu models
# implemented by ::rivetweb::menumodel

    variable sitemap
    variable disconnected
    variable datasource

    proc create { ds } {
        variable sitemap 
        variable disconnected       
        variable datasource

        set datasource $ds

# The sitemap structure is implemented by a ::struct::tree Tcl structure

        set sitemap [::struct::tree sitemap]

# After the sitemap build-up process has completed the 'disconnected' 
# branch should be empty. We will use this assumption as a check for
# a consistent definition of the website structure

        $sitemap insert root end disconnected

###### once the debug phase has finished here will go the
###### datasource call

######

        return $sitemap
    }

    proc recreate {} {
        variable sitemap 
        variable disconnected       
        variable datasource

        $sitemap destroy
        set sitemap [::struct::tree sitemap]
        $sitemap insert root end disconnected
        return $sitemap

    }

    proc add_menu_group {parent_id group_id menuobjs} {
        variable sitemap

        set mm $::rivetweb::menumodel

# we get the menuid from the model so to use it as the node name

#       set menuid      [$mm id $menuobj]
#       set menuparent  [$mm parent $menuobj]
#       set index       [$mm index $menuobj]

        if {[$sitemap exists $parent_id]} {

            $sitemap insert $parent_id end $group_id 
            foreach menu_o $menuobjs {
                set menuid [$::rivetweb::menumodel id $menu_o]

                $sitemap set $group_id $menuid $menu_o
            }

        } else {

            $sitemap insert disconnected end $menuobjs

        }

# now we check whether we have just inserted the parent of
# a menu group object previously stored in the 'disconnected' branch

        set disconnected [$sitemap children disconnected]
        
        foreach dmenu $disconnected {
            set parent [$mm parent $dmenu]

            if {[$sitemap exists $parent]} {
                set index [$mm index $dmenu]

                $sitemap move $parent $index $dmenu
            }
        }
    }

# -- menu_list: walks the tree of menus and returns a list of menu objs
# starting with the sought menu up to the root, skipping the
# leaf menus.

    proc menu_list {group_id} {
        variable sitemap

        set menuobjs {}
        if {[$sitemap exists $group_id]} {
#           puts ">>>[$sitemap keys $group_id]<<<"
            foreach m [$sitemap keys $group_id] {

                set menu_o [$sitemap get $group_id $m] 
                lappend menuobjs $menu_o

            }
            
            foreach anc [$sitemap ancestors $group_id] {

                if {[string match $anc "root"]} { continue }

                foreach menuid [$sitemap keys $anc] {

                    set menu_o [$sitemap get $anc $menuid]
                    set menutype [$::rivetweb::menumodel peek $menu_o visibility]
                    if {[string match $menutype "node"]} {
#                       puts " <== $menu_o"
                        lappend menuobjs $menu_o
                    }

                }
            }
        }

        return $menuobjs
    }

    namespace export create recreate add_menu_group menu_list
    namespace ensemble create
}

package provide rwsitemap 1.0

