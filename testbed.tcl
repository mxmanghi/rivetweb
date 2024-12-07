lappend auto_path . /usr/local/apache2/lib/rivet2.1.0a1 /usr/local/apache2/lib/rivet2.1.0a1/rivet-tcl
package require rwconf
package require rwlogger
package require rwlink
package require rwmenu
package require rwsitemap
package require XMLData
package require rivetweb
package require XMLMenu

::rivetweb::setup . website 
::rivetweb::init XMLData XMLMenu
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

array unset menu_catalog {}

foreach mngrp $site_groups {
    set menu_list [::rwsitemap menu_list $mngrp]

    puts "menu list for $mngrp: "
    foreach mn $menu_list {
        set menu_title [$::rivetweb::menumodel title $mn]
        set links [$::rivetweb::menumodel links $mn] 
        set menuid [$::rivetweb::menumodel id $mn]
        puts "links for menu $menuid ($menu_title)"

        set menu_catalog($menuid) $mn

        foreach l $links {

            ::rivet::putsnnl " ---> [$::rivetweb::linkmodel link_text $l] "
            ::rivet::putsnnl "([$::rivetweb::linkmodel type $l])"
            ::rivet::putsnnl " ---> [$::rivetweb::linkmodel reference $l] ("
            puts "[$::rivetweb::linkmodel get_attribute $l target])"

        }
    }
}
