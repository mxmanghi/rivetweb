# -- rivetweb_init.tcl
#
#


catch { package require Rivet }

# Some preliminary setup before the application is ready to serve pages

::rivet::apache_log_error info "running Rivetweb scripts at: $::rivetweb::scripts"
::rivet::apache_log_error info "site base: $::rivetweb::site_base, default language: $::rivetweb::default_lang"

#+
#  Rivetweb child process initialization
#-

namespace eval ::rivetweb {

    # building an in-memory database of available templates for this website

    ::rivet::apache_log_error info "Initializing Apache child [pid], [pwd]"

    set templates_dir [file join $::rivetweb::site_base $::rivetweb::base_templates]

    ::rivet::apache_log_error info "templates directory tree root $::rivetweb::templates_dir (pwd: [pwd])"

    ::rivetweb::RWTemplate::load_templates $templates_dir

    ::rivet::apache_log_error info "registered templates: $::rivetweb::RWTemplate::templates_db"

    dict for {key templ} $::rivetweb::RWTemplate::templates_db {
        ::rivet::apache_log_error debug "template $key: $templ"
    }

# now we build the hooks database


# scanning for hooks from rivetweb installation and thee hooks directory in $site_base
#

    foreach hooks_d [list [file join $scripts $hooks_dir] [file join $site_base hooks]] {

        if {[file exists $hooks_d] == 0} { continue }

        set hooks_dir_fq [file join $hooks_d *.tcl]

# every hook defines a tag or data element transformer. Hooks
# must define a hook_descriptor array where code characteristics
# are listed.

        set nhooks 0
        if {[catch {set hooks_list [glob $hooks_dir_fq]} e]} {

            ::rivet::apache_log_error info "no hooks read from $hooks_dir_fq"

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

            ::rivet::apache_log_error info "$nhooks hooks read from $hooks_d"
            #::rivet::apache_log_error debug $hooks
        }
    }
}

# vi:shiftwidth=4:softtabstop=4:
