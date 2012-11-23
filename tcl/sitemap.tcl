# -- sitemap.tcl: implements a sitemap manager
# 
# The main responsability for the sitemap manager is to 
# build and maintain a tree of menus. 
#

package require Itcl
package require struct::tree
package require struct::stack
package require rwmenu

namespace eval ::rwsitemap {

# the 'sitemap' variable keeps the tree object representing the
# website structure, its menus, links and multilanguage text 
# definitions. 'sitemap' is a tree of menu models implemented 
# by ::rivetweb::menumodel
#
    ::itcl::class RWSitemap {
        private variable disconnected       
        private variable sitemap_tree 
        private variable datasource
        private variable cnt
        private common   smcnt      0

        constructor {ds} {
            set cnt         0
            set datasource  $ds
# The sitemap structure is implemented by a ::struct::tree Tcl
# structure

            set sitemap_tree [::struct::tree sitemap[incr smcnt]]

# After the sitemap build-up process has completed the 'disconnected' 
# branch should be empty. We will use this assumption as a check for
# a consistent definition of the website structure
#
            $sitemap_tree insert root end disconnected
        }

        public method recreate {}
        public method has_updates {{data_source_l "*"} {ood out_of_date}} 
        public method sitemap_reload {} 
        public method add_menu_group {parent_id group_id menuobjs} 
        public method menu_list {group_id} 
        public method to_string {}
    }

# -- recreate
# 
# 

    ::itcl::body RWSitemap::recreate {} {

# 21-03-2012: shouldn't we destroy every single menu object???

        foreach node [$sitemap_tree nodes] { $node destroy }

        $sitemap_tree destroy
        set sitemap_tree [::struct::tree sitemap[incr smcnt]] 
        $sitemap_tree insert root end disconnected

    }

# -- has_updates
#
# this method should cycle through the data sources listed
# in the data_source_l list ("*" means all of the registered datasources)
# and returns in the ood variable a list of datasources that have
# updates

    ::itcl::body RWSitemap::has_updates {{data_source_l "*"} {ood out_of_date}} {
        upvar $ood need_update_l

        set need_update_ds {}
        return [$datasource has_updates]
    }

# -- sitemap_reload
#
# reloads the sitemap and informs the datasource that this
# ensemble is the sitemap manager he has to talk to.
#

    ::itcl::body RWSitemap::sitemap_reload {} {

        $datasource load_sitemap $this
    }

# -- add_menu_group 

    ::itcl::body RWSitemap::add_menu_group {parent_id group_id menuobjs} {

        if {[$sitemap_tree exists $parent_id]} {

            $sitemap_tree insert $parent_id end $group_id 
            foreach menu_o $menuobjs {
                set menuid [$menu_o id]
                $sitemap_tree set $group_id $menuid $menu_o
            }

        } else {

            $sitemap_tree insert disconnected end $group_id
            foreach menu_o $menuobjs {
                set menuid [$menu_o id]

                $sitemap_tree set $group_id $menuid $menu_o
                $sitemap_tree set $group_id parent  $parent_id
            }

            return
        }

# now we check whether we have just inserted the parent of
# a menu group object previously stored in the 'disconnected' branch

        set disconnected [$sitemap_tree children disconnected]
        foreach dmenu $disconnected {
            $::rivetweb::logger log debug "$i: $group_id $dmenu"
#           set menu_group [$sitemap get disconnected $dmenu]
            set menu_group $dmenu

            set parent [$sitemap_tree get $menu_group parent]
            if {[string match $group_id $parent]} {
                $sitemap_tree move $parent end $menu_group
                $sitemap_tree unset $menu_group parent
            }
        }

#       apache_log_error notice "sitemap ---> [$sitemap_tree nodes]"
    }

# -- menu_list: walks the tree of menus and returns a list of menu objs
# starting with the sought menu up to the root, skipping all the menus
# marked as leaves.

    ::itcl::body RWSitemap::menu_list {group_id} {

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
                    set menutype [$menu_o peek visibility]
                    if {[string match $menutype "node"]} {
                        $menu_s push $menu_o
                    }
                }
            }

        } else {

            $::rivetweb::logger log err "No menu group $group_id"

        }

# let's revert the list of menu by extracting them from the stack
#
        if {[$menu_s size] > 0}  {
            set menuobjs [$menu_s pop [$menu_s size]]
        } else {
            set menuobjs {}
        }
        $menu_s destroy
        return $menuobjs
    }

    ::itcl::body RWSitemap::to_string {} {
        return $sitemap_tree
    }


    proc create { ds } {
        return [RWSitemap ::#auto $ds]
    }
    namespace export create 
    namespace ensemble create
}

package provide rwsitemap 1.0

