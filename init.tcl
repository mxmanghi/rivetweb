# -- init.tcl
#
# this stuff must go in rivetweb's configuration, I don't see any other
# clear way to make it site specific
#

lappend auto_path $rweb_root $website_root

::rivet::apache_log_error notice "rweb_root: $rweb_root, website_root: $website_root"

package require rwlogger
package require rivetweb
package require rwconf
package require rwmenu
package require rwpage
package require urlcomposer
package require Datasource
package require RWTemplate
package require RWDummy
package require XMLBase

::rivetweb::setup $rweb_root $website_root 

cd $website_root

# rivetweb initialization 

set website_definitions [file join $::rivetweb::site_base site_defs.tcl]
if {[file exists $website_definitions]} { source $website_definitions }

set ::rivetweb::url_composer [::rivetweb::UrlComposer #auto $::rivetweb::rewrite_par]

# site_defs.tcl is supposed to define the default template, we thus assign this key to the 
# last_selected_template variable in order to force a template_chanded signal

set ::rivetweb::last_selected_template rwbase

source [file join $::rivetweb::scripts rivetweb_init.tcl]

# we have both the default template and the template database, we proceeded
# determining the default menuclass

#set ::rivetweb::menuclass [dict get $::rivetweb::templates_db $rivetweb::default_template menuclass]
set ::rivetweb::menuclass [::rivetweb::RWTemplate::template $rivetweb::default_template menuclass]

set website_init [file join $website_root $::rivetweb::website_init]
if {[file exists $::rivetweb::website_init]} {
    ::rivet::apache_log_error notice "running website specific initialization $website_init ([pwd])"
    if {[catch {source $website_init} e]} {

        ::rivet::apache_log_error crit "Error running website specific initialization ($e)"
        foreach l [split $errorInfo "\n"] {
            ::rivet::apache_log_error crit $l
        }
        
    }
}

# if we want to have the Scripted datasource we have to load it from within the
# initialization of a specific application 
# ::rivetweb::init Scripted

::rivetweb::init XMLBase

# this one is guaranteed to be the last datasource

::rivetweb::init RWDummy

::rivet::apache_log_error debug "[pwd] - Registered handlers $::rivetweb::datasources"

# this is the very last operation to do after the initialization. We have just
# instantiated each datasource and we proceed calling the 'init' method for each
# instance, as listed in ::rivetweb::datasources, in reverse order

foreach ds [lreverse $::rivetweb::datasources] {

    ::rivet::apache_log_error debug "Running init for handler $ds"
    $ds init [dict get $::rivetweb::datasources_args $ds]

}
