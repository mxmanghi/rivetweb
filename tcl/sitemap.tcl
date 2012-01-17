# -- sitemap.tcl: implements a sitemap manager
# 
# The main responsability for the sitemap manager is to 
# build and maintain a tree of menus. 
#

package require struct::tree
package require struct::stack

namespace eval ::rwsitemap {

# - sitemap keeps the tree object representing the
# website structure, its menus, links and multilanguage
# text definitions. 'sitemap' is a tree of menu models
# implemented by ::rivetweb::menumodel

    variable sitemap
    variable disconnected
    variable datasource
    variable cnt	    0

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

            $sitemap insert disconnected end $group_id
            foreach menu_o $menuobjs {
                set menuid [$::rivetweb::menumodel id $menu_o]

                $sitemap set $group_id $menuid $menu_o
                $sitemap set $group_id parent  $parent_id
            }

            return
        }

# now we check whether we have just inserted the parent of
# a menu group object previously stored in the 'disconnected' branch

        set disconnected [$sitemap children disconnected]
        set i 0
        foreach dmenu $disconnected {
#           set dmenu [eval set dmenu]
            $::rivetweb::logger log debug "$i: $group_id $dmenu"
#           set menu_group [$sitemap get disconnected $dmenu]
            set menu_group $dmenu

            set parent [$sitemap get $menu_group parent]

#           if {[$sitemap exists $parent]} 

#           puts "$group_id <- $parent"
            if {[string match $group_id $parent]} {
                $sitemap move $parent end $menu_group
                $sitemap unset $menu_group parent
            }
            incr i
        }
    }

# -- menu_list: walks the tree of menus and returns a list of menu objs
# starting with the sought menu up to the root, skipping the
# leaf menus.

    proc menu_list {group_id} {
        variable sitemap
	variable cnt

	set menu_s [::struct::stack menu_stack[incr cnt]]

        if {[$sitemap exists $group_id]} {
#	    puts ">>>[$sitemap keys $group_id]<<<"
            foreach m [$sitemap keys $group_id] {

                set menu_o [$sitemap get $group_id $m] 
                $menu_s push $menu_o

            }

	    $::rivetweb::logger log info "walking up ancestors -> [$sitemap ancestors $group_id]"    

            foreach anc [$sitemap ancestors $group_id] {

                if {[string match $anc "root"]} { continue }

                foreach menuid [$sitemap keys $anc] {

                    set menu_o [$sitemap get $anc $menuid]
                    set menutype [$::rivetweb::menumodel peek $menu_o visibility]
                    if {[string match $menutype "node"]} {
                        $menu_s push $menu_o
                    }
                }
            }
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

    namespace export create recreate add_menu_group menu_list
    namespace ensemble create
}

package provide rwsitemap 1.0

