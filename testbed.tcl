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

