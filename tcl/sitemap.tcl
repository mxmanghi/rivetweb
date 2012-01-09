# -- sitemap.tcl: implements a sitemap manager
# 
# The main responsability for the sitemap manager is to 
# build and maintain a tree of menus. 

package require struct::tree


namespace eval ::rwsitemap {

    variable sitemap
    variable disconnected

    proc create { datasource } {
        variable sitemap 
        variable disconnected       

# The sitemap structure is implemented by a ::struct::tree Tcl structure

        set sitemap         [::struct::tree sitemap]
        $sitemap insert root end disconnected
    }

    proc addmenu {menuobj} {
        variable sitemap

        set mm $::rivetweb::menumodel

# we get the menuid from the model so to use it as the node name

        set menuid      [$mm id $menuobj]
        set menuparent  [$mm parent $menuobj]
        set index       [$mm index $menuobj]

        if {[$sitemap exists $menuparent]} {

            $sitemap insert $menuparent $index $menuid 
            $sitemap set $menuid menu $menuobj

        } else {

            $sitemap insert disconnected end $menuobj

        }

# now we check whether we have just inserted the parent of
# a menuobject previously stored in the 'disconnected' branch

        set disconnected [$sitemap children disconnected]
        
        foreach dmenu $disconnected {
            set parent [$mm parent $dmenu]

            if {[$sitemap exists $parent]} {
                set index [$mm index $dmenu]

                $sitemap move $parent $index $dmenu
            }
        }
    }
}

package provide rwsitemap 1.0
