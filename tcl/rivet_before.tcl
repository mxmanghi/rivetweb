#
# $Id: rivet_before.tcl 2101 2011-12-15 10:43:10Z massimo.manghi $
# 
# $Author: massimo.manghi $
# 
# +
# - 
#

# let's assign the controlling variables with the corresponding parameters definitions

# parameter static -> enabling generation of 'static' (i.e. .html pages)

set ::rivetweb::static_links [var exists static]
set ::rivetweb::is_homepage  [var exists homepage]
    
# and now we determine if site_structure has to be reloaded

#set site_structure_file [file join $::rivetweb::site_base $sitemap_file]
#
#if {[file exists $site_structure_file]} {
#
## before we establish the revision number we check the mtime, it's probably better and faster
#
#    file stat $site_structure_file site_structure_stat
#    set site_structure_reload [expr $site_structure_stat(mtime) > $::rivetweb::site_structure_mtime] 
#
#    # checking if the menu structure has been updated and has to be generated from scratch
#
#    if { $site_structure_reload } {
#        set ::rivetweb::site_structure_mtime $site_structure_stat(mtime)
#        apache_log_error err "opening site defs $site_structure_file (pid: [pid])"
#        set xmlsite     [open $site_structure_file r]
#
## lines set up for deletion
##
##    set linea   [gets $xmlmenu]
##    while {    ![eof $xmlmenu] && \
##        ![regexp [subst {<\!--\s*\$Id:\s+{$sitemap_file}\s*(\d*).*\$\s*-->}] $linea match rev] && \
##        ![regexp {<\!--\s*\$Revision:\s*(\d*)\s*-->} $linea match rev] } {
##        set linea [gets $xmlmenu]
##    #   puts "<pre>[escape_sgml_chars $linea]</pre>"
##    }
##
#
#        if {[info exists site_dom]} { $site_dom delete }
#        set xml	            [read $xmlsite]
#        set site_dom        [dom parse $xml doc]
#        set domroot         [$site_dom documentElement root]
#        set deflang_el      [$domroot getElementsByTagName default_language]
#        set default_lang    [$deflang_el text]
#
#        close $xmlsite
#    }
#} else {
#    set site_structure_reload 1
#}

# when Rivetweb is pretending to be a static site, pages fake their location to be in
# the /static/ subdirectory 

set ::rivetweb::running_picts_path  $::rivetweb::picts_path
set ::rivetweb::running_css_path    $::rivetweb::css_path
if {$::rivetweb::static_links && !$::rivetweb::is_homepage} {
    set ::rivetweb::running_picts_path  [file join .. $::rivetweb::picts_path]
    set ::rivetweb::running_css_path    [file join .. $::rivetweb::css_path]
}
#puts "<pre><b>static_links: $::rivetweb::static_links</b></pre>"

file stat $sitemap sitemap_now
set  site_menus_reload  [expr $sitemap_now(mtime) > $sitemap_mtime]

if { $site_menus_reload } {

    set sitemap_mtime $sitemap_now(mtime)

    apache_log_error err "recreating sitemap..."
    if {[info exists menu_dom]} { $menu_dom delete }
#####
    set maps [glob [file join $::rivetweb::sitemap *.xml]]
#####
#   set fragment [file join $::rivetweb::sitemap sitemap.xml]
#####
    
    foreach map $maps {
        apache_log_error info "reading $map..."

        set xml [read_file $map]
        set xmlmenu([file tail $map]) [dom parse $xml]
    }

    foreach mdoc [array names xmlmenu] {
        set rootel      [$xmlmenu($mdoc) documentElement root]
        set sitemenus   [$xmlmenu($mdoc) getElementsByTagName sitemenus]

        foreach sm $sitemenus {
            if {[$sm hasAttribute id]} {
                set parent ""
                if {[$sm hasAttribute parent]} {
                    set parent [$sm getAttribute parent]
                }

                set menublock_id [$sm getAttribute id]

                apache_log_error debug "$mdoc - id: $menublock_id (parent: $parent)"
                
                foreach menu [$sm getElementsByTagName menu] {
                    foreach cn [$menu childNodes] {
                        apache_log_error debug "  $menu: [$cn nodeName] - [$cn text]"
                    }
                }

                if {$menublock_id == "root"} {
                    set root_doc $xmlmenu($mdoc)
                }

                set sitemenus_a($menublock_id) $sm

            } else {
                apache_log_error err "no id attribute for $sm"
            }
        }
    }
    
    foreach blocco_id [array names sitemenus_a] {
        if {$blocco_id == "root"} { continue }
        set sm $sitemenus_a($blocco_id)
        if {[$sm hasAttribute parent]} {
            set p [$sm getAttribute parent]
            if {[info exists sitemenus_a($p)]} {
                domNode $sitemenus_a($p) appendChild $sm
            } else {
                apache_log_error err "skipping $blocco_id, no parent defined for menu block"
            }
        }
    }
} 

# let's determine which template we are using

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
apache_log_error err "template: $running_template (css: $running_css)"
set ::rivetweb::running_template  [buildTemplateName $running_template $template_key]
set ::rivetweb::running_css       [makeCssPath $running_css $template_key]
set ::rivetweb::template_key      $template_key


if {[var exists staticroot]} {
    header redir index.html
}
# vi:shiftwidth=4:softtabstop=4:
