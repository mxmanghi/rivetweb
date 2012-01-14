#
# $Id: rivet_before.tcl 2101 2011-12-15 10:43:10Z massimo.manghi $
# 
# +
# This is where at every request most of the work is done to prepare a page. 
# - 
#

# let's assign the controlling variables with the corresponding parameters 
# definitions.
# parameter static -> enabling generation of 'static' (i.e. .html pages)

set ::rivetweb::static_links [var exists static]
set ::rivetweb::is_homepage  [var exists homepage]
    
# when Rivetweb is pretending to be a static site, pages fake their location 
# to be in the /static/ subdirectory, so 'running_picts_path' and 
# running_css_path has to be set accordingly

set ::rivetweb::running_picts_path  $::rivetweb::picts_path
set ::rivetweb::running_css_path    $::rivetweb::css_path
if {$::rivetweb::static_links && !$::rivetweb::is_homepage} {

    set ::rivetweb::running_picts_path  [file join .. $::rivetweb::picts_path]
    set ::rivetweb::running_css_path    [file join .. $::rivetweb::css_path]

}

# let's determine which template we are using

# we set a couple of default values for them

set running_template base.rvt
set running_css      base.css 

if {[var exists template]} {

    set template_key [var get template]
    catch {
        set running_template  [dict get $::rivetweb::templates_db $template_key template]
        set running_css       [dict get $::rivetweb::templates_db $template_key css]
    }

} elseif {[string compare $::rivetweb::default_template ""] != 0} {

    set template_key $::rivetweb::default_template
    catch {
        set running_template  [dict get $::rivetweb::templates_db $template_key template]
        set running_css       [dict get $::rivetweb::templates_db $template_key css]
    }

} else {
    set template_key rwbase
}
apache_log_error info "template: $running_template (css: $running_css)"
set ::rivetweb::running_template  [buildTemplateName $running_template $template_key]
set ::rivetweb::running_css       [makeCssPath $running_css $template_key]
set ::rivetweb::template_key      $template_key

if {[var exists staticroot]} {
    header redir index.html
}

# puts "<pre><b>static_links: $::rivetweb::static_links</b></pre>"
# we rely on the 'sitemap' directory mtime to see if some of its files
# have changed and a new tree of links has to be recreated

if {[$::rivetweb::menusource has_updates]} {

    $::rivetweb::logger log notice "(re-)loading sitemap"
    $::rivetweb::sitemap recreate

    $::rivetweb::menusource loadsitemap $::rivetweb::sitemap
}


#file stat $sitemap sitemap_now
#set  site_menus_reload  [expr $sitemap_now(mtime) > $sitemap_mtime]
#
#if { $site_menus_reload } {
#
#    set sitemap_mtime $sitemap_now(mtime)
#
#    apache_log_error info "recreating sitemap..."
#    if {[info exists menu_dom]} { $menu_dom delete }
#
## we assume the sitemap is stored in .xml files 
#
#    set maps [glob [file join $::rivetweb::sitemap *.xml]]
#    
#    foreach map $maps {
#        apache_log_error info "reading $map..."
#
#        set xml [read_file $map]
#
## we silently drop malformed XML files. We just log a message
## if Apache's loglevel is debug
#
#        if {[catch { set xmlmenu([file tail $map]) [dom parse $xml] } e]} {
#            apache_log_error debug "could not parse map $map: $e"
#        }
#    }
#
## finally for every DOM tree we extract information to build a tree of links
##
## there must be just one 'root' menu and we assume there are no disconnected
## subtree (thus following any "parent" attribute eventually we get to the
## 'root' menu
##
#
#    foreach mdoc [array names xmlmenu] {
#        set rootel      [$xmlmenu($mdoc) documentElement root]
#        set sitemenus   [$xmlmenu($mdoc) getElementsByTagName sitemenus]
#
#        foreach sm $sitemenus {
#            if {[$sm hasAttribute id]} {
#                set parent ""
#                if {[$sm hasAttribute parent]} {
#                    set parent [$sm getAttribute parent]
#                }
#
#                set menublock_id [$sm getAttribute id]
#
#                apache_log_error debug \
#                                "$mdoc - id: $menublock_id (parent: $parent)"
#                
#                foreach menu [$sm getElementsByTagName menu] {
#                    foreach cn [$menu childNodes] {
#                        apache_log_error debug \
#                                "  $menu: [$cn nodeName] - [$cn text]"
#                    }
#                }
#
#                if {$menublock_id == "root"} {
#                    set root_doc $xmlmenu($mdoc)
#                }
#
#                set sitemenus_a($menublock_id) $sm
#
#            } else {
#                apache_log_error err "no id attribute for $sm"
#            }
#        }
#    }
#    
#    foreach menu_group_id [array names sitemenus_a] {
#        if {$menu_group_id == "root"} { continue }
#        set sm $sitemenus_a($menu_group_id)
#        if {[$sm hasAttribute parent]} {
#            set p [$sm getAttribute parent]
#            if {[info exists sitemenus_a($p)]} {
#                domNode $sitemenus_a($p) appendChild $sm
#            } else {
#                apache_log_error err \
#                    "skipping $menu_group_id, no parent defined for menu block"
#            }
#        }
#    }
#} 


# vi:shiftwidth=4:softtabstop=4:
