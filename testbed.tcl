lappend auto_path . /usr/local/lib/rivet2.1 /usr/local/lib/rivet2.1/rivet-tcl
package require rwconf
package require rwlogger
package require rwlink
package require rwmenu
package require rwsitemap
package require XMLData
package require rivetweb
package require XMLMenu

::rivetweb::init . website XMLData XMLMenu
#::XMLMenu::init sitemap
#::rwsitemap create XMLMenu
#::XMLMenu::loadsitemap rwsitemap

set site_groups [$::rwsitemap::sitemap children -all root]
puts " ==== examining menu groups --> [join $site_groups ,] <<--"

foreach mngrp $site_groups {
#    if {[catch {
#        set menus [$::rwsitemap::sitemap get $mn menu]
#    }]} { continue }

    set menuids [$::rwsitemap::sitemap keys $mngrp]

    puts "menu group: $mngrp -> $menuids"
    foreach menuid $menuids {
        puts "-----------\n menu $menuid"
        set menu_d [$::rwsitemap::sitemap get $mngrp $menuid]
#       puts $menu_d

        ::rivet::putsnnl "$mngrp group -> Menu [::rwmenu id $menu_d], titolo: "
        ::rivet::putsnnl "[::rwmenu title $menu_d $::rivetweb::default_lang], "
        ::rivet::putsnnl "parent: [::rwmenu parent $menu_d]"
        puts ""

        set links [::rwmenu links $menu_d]

        puts "links: $links"
        foreach l $links {
            ::rivet::putsnnl $l 
            ::rivet::putsnnl "---> [::rwlink link_text $l]"
            puts ""
        }
    }
}


foreach mngrp $site_groups {
    set menu_list [::rwsitemap menu_list $mngrp]

    puts "menu list for $mngrp: "
    foreach mn $menu_list {
        puts "ok---> $mn"
    }
}
