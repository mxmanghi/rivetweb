# -- sitemap.tcl: implements a sitemap manager
# 
# The main responsability for the sitemap manager is to 
# build and maintain a tree of menus. 

package require struct::tree

namespace eval ::rwsitemap {

    variable sitemap
    variable disconnected
    variable datasource

    proc create { ds } {
        variable sitemap 
        variable disconnected       
        variable datasource

        set datasource $ds

# The sitemap structure is implemented by a ::struct::tree Tcl structure

        set sitemap         [::struct::tree sitemap]
        $sitemap insert root end disconnected
        return $sitemap
    }

    proc add_menu_group {parent_id group_id menuobjs} {
        variable sitemap

        set mm $::rivetweb::menumodel

# we get the menuid from the model so to use it as the node name

#        set menuid      [$mm id $menuobj]
#        set menuparent  [$mm parent $menuobj]
#        set index       [$mm index $menuobj]

        if {[$sitemap exists $parent_id]} {

            $sitemap insert $parent_id end $group_id 
            $sitemap set $group_id menu $menuobjs

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

    namespace export create add_menu_group
    namespace ensemble create
}

package provide rwsitemap 1.0
