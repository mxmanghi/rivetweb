# -- init.tcl
#
# this stuff must go in rivetweb's configuration, I don't see any other
# clear way to make it site specific
#

lappend auto_path $rweb_root $website_root

::rivet::apache_log_error notice "rweb_root: $rweb_root, website_root: $website_root"
cd $website_root

package require rwlogger
package require rwconf
package require rwmenu
package require rwpage
package require rwlink
package require urlcomposer
package require RWTemplate
package require UrlHandler
package require rivetweb
package require RWDummy
package require XMLBase

::rivetweb::setup $rweb_root $website_root

# rivetweb initialization

set website_definitions [file join $::rivetweb::site_base site_defs.tcl]
if {[file exists $website_definitions]} { source $website_definitions }

::rivet::apache_log_error info "default_template: $::rivetweb::default_template"

#set ::rivetweb::url_composer [::rivetweb::UrlComposer #auto $::rivetweb::rewrite_par]
set ::rivetweb::url_composer [::rivetweb::make_url_composer]

# site_defs.tcl is supposed to define the default template, we thus assign this key to the
# last_selected_template variable in order to force a template_chanded signal

set ::rivetweb::last_selected_template rwbase

# rivetweb_init.tcl loads the templates database and hooks database

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
# initialization of a specific application ::rivetweb::init Scripted

::rivetweb::init XMLBase last

# this one is guaranteed to be the last datasource

::rivetweb::init RWDummy last

# Application replaceable procedure for the handler list tampering

# The handler list tampering is deprecated in favour of overriding the method
# UrlHandler::next_handler

::rivet::apache_log_error debug "[pwd] - Registered handlers pre tampering [::rwdatas::UrlHandler::registered_handlers]"
::rivet::apache_log_error debug "[pwd] - Handlers arguments pre tampering [::rwdatas::UrlHandler::handlers_arguments]"
::rwdatas::UrlHandler::set_installed_handlers \
    [::rivetweb::handlers_list_tampering [::rwdatas::UrlHandler::registered_handlers]]

::rivet::apache_log_error debug "[pwd] - Registered handlers [::rwdatas::UrlHandler::registered_handlers]"
::rivet::apache_log_error debug "[pwd] - Handlers arguments post tampering [::rwdatas::UrlHandler::handlers_arguments]"

# this is the very last operation to do after the initialization. We have just
# instantiated each datasource and we proceed calling the 'init' method for each
# instance in reverse order in the list of handlers. Application level models 
# different from the default list based model should provide a meanining about
# the idea of 'reverse order'

# the main reason for deferring this stage is that 'init' method register error
# messages within the RWDummy messages database, but RWDummy has to be instantiated for
# the method 'register_error' to exist

::rivet::apache_log_error debug "Url handlers init [::rwdatas::UrlHandler::handlers_arguments]"

set handlers_arguments [::rwdatas::UrlHandler::handlers_arguments]
foreach ds [lreverse [::rwdatas::UrlHandler::registered_handlers]] {

    if {[dict exists $handlers_arguments $ds]} {
        ::rivet::apache_log_error debug "Running init for handler $ds ([dict get $handlers_arguments $ds])"
        $ds init {*}[dict get $handlers_arguments $ds]
    } else {
        $ds init        
    }

}

# -- init.tcl
