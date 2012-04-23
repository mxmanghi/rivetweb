#
# $Id: rivet_init.tcl 2104 2011-12-18 00:24:45Z massimo.manghi $
#
#+
#  Child initialization
#-
#

# index page

$::rivetweb::rwebdb fetch index 

# costruiamo il database in memoria dei template disponibili
apache_log_error notice "Initializing Apache child [pid], [pwd]"

set templates_dir_list [glob -directory $::rivetweb::base_templates *]

foreach template $templates_dir_list {

    if {[file isdirectory $template]} {

        if {[catch {

# we prepare a clean namespace where variables will be stored

            catch { namespace delete ::rwtemplate }
            namespace eval ::rwtemplate {

                source [file join $template rwtemplate.tcl]
                if {![info exists rwtemplate] || ![info exists rwcss]} {
                    apache_log_error err "Descrittore template $template incompleto"
                    continue
                }

                set template_key [file tail $template]

                dict set ::rivetweb::templates_db $template_key template $rwtemplate 
                dict set ::rivetweb::templates_db $template_key css $rwcss

# along with template name and css file name, we build also a database of definitions
# for the menu definitions variables.

                if {[info exists ::rwtemplate::menu_html]} {
                    dict set ::rivetweb::templates_db $template_key menu_html $::rwtemplate::menu_html
                }
                if {[info exists ::rwtemplate::title_html]} {
                    dict set ::rivetweb::templates_db $template_key title_html $::rwtemplate::title_html
                }
                if {[info exists ::rwtemplate::it_cont_html]} {
                    dict set ::rivetweb::templates_db $template_key it_cont_html $::rwtemplate::it_cont_html
                }
                if {[info exists ::rwtemplate::item_html]} {
                    dict set ::rivetweb::templates_db $template_key item_html $::rwtemplate::item_html
                }
                if {[info exists ::rwtemplate::link_class]} {
                    dict set ::rivetweb::templates_db $template_key link_class $::rwtemplate::link_class
                }
            }

        } e]} {
            apache_log_error err "Error reading rwtemplate.tcl from $template ($e)"
        }
    }
}

foreach k [dict keys $::rivetweb::templates_db] {
    apache_log_error debug "$k: [dict get $::rivetweb::templates_db $k]"
}

# now we build the hooks database

namespace eval ::rivetweb {

# actually there's must be a search list of directories where hooks
# can be stored...

    set hooks_dir_fq [file join $scripts $hooks_dir *.tcl]

# every hook defines a tag or data element transformer. Hooks
# must define a hook_descriptor array where code characteristics
# are listed.

    set nhooks 0
    if {[catch {set hooks_list [glob $hooks_dir_fq]} e]} {

        apache_log_error notice "no hooks read from $hooks_dir_fq"

    } else {

        foreach hook_file [glob $hooks_dir_fq] {

            array unset hook_descriptor
            source $hook_file

# we assume everything has been stored in the hook_descriptor array

            if {![info exists hook_descriptor(textmode)]} {
                set hook_descriptor(textmode)   text
            }

            if {[info exists hook_descriptor(tag)]} {
                dict set hooks  $hook_descriptor(stage)                          \
                                $hook_descriptor(tag)                            \
                                [dict create function $hook_descriptor(function) \
                                             textmode $hook_descriptor(textmode) \
                                             descrip  $hook_descriptor(descrip)]
                incr nhooks
            }
        }

        apache_log_error notice "$nhooks hooks processed"
        apache_log_error debug   $hooks
    }
}

# vi:shiftwidth=4:softtabstop=4:
