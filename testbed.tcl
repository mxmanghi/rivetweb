lappend auto_path . /usr/local/lib/rivet2.1 /usr/local/lib/rivet2.1/rivet-tcl
package require rwconf
package require rwlogger
package require rwlink
package require rwmenu
package require rwsitemap
package require XMLData
package require rivetweb
package require rwsitemap
package require XMLMenu

::rivetweb::init . website XMLData
::XMLMenu::init sitemap
::rwsitemap create XMLMenu
::XMLMenu::loadsitemap rwsitemap

set main [$::rwsitemap::sitemap children -all root]

foreach mn $main {
    if {[catch {
        set menus [$::rwsitemap::sitemap get $mn menu]
    }]} { continue }

    foreach menu_d $menus {
        ::rivet::putsnnl "$mn group -> Menu [::rwmenu id $menu_d], titolo: "
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
