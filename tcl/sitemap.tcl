# -- sitemap.tcl: implements a sitemap manager
# 
# The main responsability for the sitemap manager is to 
# build and maintain a tree of menus. 
#

package require struct::tree
package require struct::stack

namespace eval ::rwsitemap {

# the 'sitemap' variable keeps the tree object representing the
# website structure, its menus, links and multilanguage text 
# definitions. 'sitemap' is a tree of menu models implemented 
# by ::rivetweb::menumodel
#

    variable sitemap_tree
    variable disconnected
    variable datasource
    variable cnt	    0

    proc create { ds } {
        variable sitemap_tree 
        variable disconnected       
        variable datasource

        set datasource $ds

# The sitemap structure is implemented by a ::struct::tree Tcl
# structure

        set sitemap_tree [::struct::tree sitemap]

# After the sitemap build-up process has completed the 'disconnected' 
# branch should be empty. We will use this assumption as a check for
# a consistent definition of the website structure
#

        $sitemap_tree insert root end disconnected

        return $sitemap_tree
    }

# -- recreate
# 
# 

    proc recreate {} {
        variable sitemap_tree 
        variable disconnected       
        variable datasource

# 21-03-2012: shouldn't we destroy every single menu object???

        $sitemap_tree destroy
        set sitemap_tree [::struct::tree sitemap_tree]
        $sitemap_tree insert root end disconnected

        return $sitemap_tree
    }

# -- has_updates
#
# this method should cycle through the data sources listed
# in the data_source_l list ("*" means all of the registered datasources)
# and returns in the ood variable a list of datasources that have
# updates

    proc has_updates {{data_source_l "*"} {ood out_of_date}} {
        upvar $ood need_update_l
        variable datasource

        set need_update_ds {}
        return [$datasource has_updates]
    }

# -- sitemap_reload
#
# reloads the sitemap and informs the datasource that this
# ensemble is the sitemap manager he has to talk to.
#

    proc sitemap_reload {} {
        variable datasource

        $datasource loadsitemap $::rivetweb::sitemap   
    }

    proc add_menu_group {parent_id group_id menuobjs} {
        variable sitemap_tree

        set mm $::rivetweb::menumodel

# we get the menuid from the model so to use it as the node name

#       set menuid      [$mm id $menuobj]
#       set menuparent  [$mm parent $menuobj]
#       set index       [$mm index $menuobj]

        if {[$sitemap_tree exists $parent_id]} {

            $sitemap_tree insert $parent_id end $group_id 
            foreach menu_o $menuobjs {
                set menuid [$::rivetweb::menumodel id $menu_o]

                $sitemap_tree set $group_id $menuid $menu_o
            }

        } else {

            $sitemap_tree insert disconnected end $group_id
            foreach menu_o $menuobjs {
                set menuid [$::rivetweb::menumodel id $menu_o]

                $sitemap_tree set $group_id $menuid $menu_o
                $sitemap_tree set $group_id parent  $parent_id
            }

            return
        }

# now we check whether we have just inserted the parent of
# a menu group object previously stored in the 'disconnected' branch

        set disconnected [$sitemap_tree children disconnected]
        set i 0
        foreach dmenu $disconnected {
#           set dmenu [eval set dmenu]
            $::rivetweb::logger log debug "$i: $group_id $dmenu"
#           set menu_group [$sitemap get disconnected $dmenu]
            set menu_group $dmenu

            set parent [$sitemap_tree get $menu_group parent]

#           if {[$sitemap exists $parent]} 

#           puts "$group_id <- $parent"
            if {[string match $group_id $parent]} {
                $sitemap_tree move $parent end $menu_group
                $sitemap_tree unset $menu_group parent
            }
            incr i
        }
    }

# -- menu_list: walks the tree of menus and returns a list of menu objs
# starting with the sought menu up to the root, skipping all the menus
# marked as leaves.

    proc menu_list {group_id} {
        variable sitemap_tree
        variable cnt

        set menu_s [::struct::stack menu_stack[incr cnt]]

        if {[$sitemap_tree exists $group_id]} {
#	        puts ">>>[$sitemap keys $group_id]<<<"
            foreach m [$sitemap_tree keys $group_id] {

                set menu_o [$sitemap_tree get $group_id $m] 
                $menu_s push $menu_o

            }

	        $::rivetweb::logger log info "walking up ancestors -> [$sitemap_tree ancestors $group_id]"    

            foreach anc [$sitemap_tree ancestors $group_id] {

                if {[string match $anc "root"]} { continue }

                foreach menuid [$sitemap_tree keys $anc] {

                    set menu_o [$sitemap_tree get $anc $menuid]
                    set menutype [$::rivetweb::menumodel peek $menu_o visibility]
                    if {[string match $menutype "node"]} {
                        $menu_s push $menu_o
                    }
                }
            }
        } else {
            $::rivetweb::logger log err "No menu group $group_id"
        }

# let's revert the list of menu by extracting them from the stack

        if {[$menu_s size] > 0}  {
            set menuobjs [$menu_s pop [$menu_s size]]
        } else {
            set menuobjs {}
        }
        $menu_s destroy
        return $menuobjs
    }

    namespace export create recreate add_menu_group menu_list \
                     has_updates sitemap_reload
    namespace ensemble create
}

package provide rwsitemap 1.0

