#!/usr/bin/tclsh
#
#
#

lappend auto_path [file normalize [file join [file dirname [info script]] ..]]

package require rwterm
package require rivetweb

# -- check_create_dir
#
# 
#

proc check_create_dir {dirpath} {

    if {[file exists $dirpath]} {
        if {![file isdirectory $dirpath]} {
            return -code error -errorcode wrong_website_structure 
        }

# dir exists already

        return -code ok
    }

    file mkdir $dirpath

    return -code ok
}

# -- create_website <path>
#
# this procedure is all about creating a new website
# with a consistent template. Assuming an emtpy
# directory exists we copy or create some basic
# files and the directory tree
#

proc create_website {website} {
    
# an empty folder should be existing already

    puts stderr "creating basic directories"
    set templates_dir [file join $::rivetweb::site_base $::rivetweb::base_templates]

    puts -nonewline stderr "Creating templates directory ($templates_dir)..."
    check_create_dir $templates_dir
    check_create_dir [file join $templates_dir $::rivetweb::default_template] 
    puts "ok"

# let's copy basic templates in it

    if {[catch {

        set script_templ_dir [file join $::rivetweb::scripts \
                                        $::rivetweb::rwtemplates]

        file copy [file join $script_templ_dir init.tcl] $website
        file copy [file join $script_templ_dir exit.tcl] $website

# let's create the directory tree for the default template. Tcl creates
# also the parent directory

        check_create_dir [file join $website $::rivetweb::picts_path \
                                    $::rivetweb::default_template]

        check_create_dir [file join $website $::rivetweb::base_templates \
                                    $::rivetweb::default_template]

# we create also the directory for xml data

        check_create_dir [file join $website $::rivetweb::static_pages]
        check_create_dir [file join $website $::rivetweb::sitemap]
        file copy [file join $script_templ_dir sitemap.xml] \
                  [file join $website $::rivetweb::sitemap sitemap.xml]

# we copy into the target dir the new index.xml file

        set indexfp [open [file join $script_templ_dir index.xml] r]
        set xml [read $indexfp]
        close $indexfp

        regsub AUTHOR $xml [exec whoami] xml
        regsub CREATION_DATE $xml [clock format [clock seconds]] xml

        set indexfp [open [file join $website $::rivetweb::static_pages \
                                              $::rivetweb::${index}.xml] w]
        puts $indexfp $xml
        close $indexfp

    } e]} {
        puts "Error creating new website:\n $e"
        exit
    }   
}

#set site_base       [pwd]
#set rivetweb_conf   [file join $site_base rivetweb.tcl]
#
#if {![file exists $rivetweb_conf]} {
#    puts "Error: rivetweb.tcl not existing."
#    exit
#}
#
## By reading this we establish where Rivetweb scripts are (::rivetweb::scripts)
#
#source $rivetweb_conf

set script_dir      [file dirname [info script]]

#if {![info exists ::rivetweb::scripts]} {
#    set linea [leggi_linea stdin "rivetweb script directory: "]
#}

# rivetweb_ns.tcl defines Rivetweb status and configuration variables

#source [file join $::rivetweb::scripts rivetweb_ns.tcl]

## site_defs.tcl overrides default
#
#set defs_location [file join $::rivetweb::site_base site_defs.tcl]
#
#puts "reading definitions from $defs_location"
#source $defs_location
#

#::rwterm::termio_setup

while {1} {
    set linea [::rwterm::read_input_line stdin "Linea: "]
    if {[string match $linea END] || [eof stdin]} { puts ""; break }
    puts " ---> $linea"
}

