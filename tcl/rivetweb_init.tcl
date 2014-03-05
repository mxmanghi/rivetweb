# -- rivetweb_init.tcl
#
#


catch { package require Rivet }

# Some preliminary setup before the application is ready to serve pages

apache_log_error info "running Rivetweb scripts at: $::rivetweb::scripts"
apache_log_error info "site base: $::rivetweb::site_base, default language: $::rivetweb::default_lang"
apache_log_error info "templates database: $::rivetweb::base_templates ([pwd])"

source [file join $::rivetweb::scripts rivet_init.tcl]

