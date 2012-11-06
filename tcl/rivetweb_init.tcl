# -- rivetweb_init.tcl
#
#
package require tdom
package require Rivet

# Some preliminary setup before the application is ready to serve pages

apache_log_error notice "running Rivetweb scripts at: $::rivetweb::scripts"
apache_log_error notice "site base: $::rivetweb::site_base, default language: $::rivetweb::default_lang"
apache_log_error notice "templates database: $::rivetweb::base_templates ([pwd])"

source [file join $::rivetweb::scripts rivet_init.tcl]

