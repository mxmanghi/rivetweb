#
# -- pagebroker.tcl
#
#

package require Itcl
package require rwlogger

namespace eval ::rivetweb {

    ::itcl::class PageBroker {
        private variable class_db       [dict create]
        private variable keyclassmap    [dict create]
        private variable log_prefix     "\[[namespace current]\]"

        public method check_class_loaded {class_name oosys}
        public method key_class_map {key {ooclass ""} {itcl_file ""} {oosys itcl}}
        public method register_class {class_name {itcl_file ""} {oosys itcl}}
        public method check_class {class_name}
        public method check_registered_classes {}
        public method configure_page {key args}
        public method create_page_obj {key ooclass rkey args}
    }
    
    # -- register_class
    #

    ::itcl::body PageBroker::register_class {class_name {itcl_file ""} {oosys itcl}} {

        set proposed_file_name "[string tolower [namespace tail $class_name]].tcl"
        if {$itcl_file == ""} {
            set itcl_file_found 0
            foreach subd {tcl class} {
                set itcl_file [file join $::rivetweb::site_base \
                                         $subd $proposed_file_name]

                if {[file exists $itcl_file]} { 
                    set itcl_file_found 1
                    break 
                }

            }
            if {$itcl_file_found == 0} {
                return -code error -errorcode class_file_not_found \
                                    "File for class '$class_name' not found"
            }
        }

        if {[dict exists $class_db $class_name]} {
            ::rwlogger log info "(register_class) registering $class_name twice ($itcl_file)"
            ::rwlogger log info "(register_class) skip registration for $class_name"
            return
        }

        # if a class has been already loaded by
        # another url handler we skip the file sourcing 

        #if {[$this check_class_loaded $class_name $oosys] == 0} {
        #    ::rwlogger log debug "loading $itcl_file for $class_name"
        #    source $itcl_file
        #}

        dict set class_db $class_name file $itcl_file 
        dict set class_db $class_name oosys $oosys
        dict set class_db $class_name mtime [file mtime $itcl_file]

        ::rwlogger log info "(register_class) class $class_name ($itcl_file)"
    }

    # -- key_class_map
    #
    #

    ::itcl::body PageBroker::key_class_map {key {ooclass ""} {itcl_file ""} {oosys itcl}} {

        if {$ooclass != ""} {
            $this register_class $ooclass $itcl_file $oosys
            dict set keyclassmap $key class $ooclass
        } elseif {[dict exists $keyclassmap $key class]} {
            set ooclass [dict get $keyclassmap $key class]
        }
        return $ooclass

    }

    # -- configure_page
    #
    #

    ::itcl::body PageBroker::configure_page {key args} {
        if {[dict exists $keyclassmap $key]} {
            dict set keyclassmap $key configure $args
        }
    }

    # -- create_page_obj
    #
    # sulla base della chiave si crea una pagina se esiste 
    # una definizione di classe associata ad essa tramite il 
    # metodo key_class_map
    #

    ::itcl::body PageBroker::create_page_obj {key ooclass reassigned_key args} {    
        upvar $reassigned_key rkey

        set rkey $key
        set pobj [eval $ooclass ::rwpage::#auto $key {*}$args]

        if {[dict exists $keyclassmap $key configure]} {
            eval $pobj configure [dict get $keyclassmap $key configure]
        }

        return $pobj
    }

# -- check_class_loaded
#
#

    ::itcl::body PageBroker::check_class_loaded {class_name oosys} {

        switch $oosys {
            itcl {
                return [::itcl::is class $class_name]
            }
            default {
                return false
            }
        }

    }

# -- check_registered_classes
#
#

    ::itcl::body PageBroker::check_registered_classes {} {
        foreach class_name [dict keys $class_db] { $this check_class $class_name }
    }

# -- check_class
#
#

    ::itcl::body PageBroker::check_class {class_name} {

        if {[dict exists $class_db $class_name]} {
            set itcl_file [dict get $class_db $class_name file]
            set oosys     [dict get $class_db $class_name oosys]
        } else {
            return false
        }

        set class_reload false

        if {[$this check_class_loaded $class_name $oosys] == 0} {

            ::rwlogger log debug \
                "$log_prefix: class $class_name not loaded, reading from $itcl_file"
            set class_reload true

        } else {

            set current_mtime   [file mtime $itcl_file]
            set last_mtime      [dict get $class_db $class_name mtime]
            if {$last_mtime < $current_mtime} {

                ::rwlogger log notice \
                    "$log_prefix: class $class_name stale, deleting and then reading from $itcl_file"
                ::rwdatas::UrlHandler::notify_handlers class_being_deleted $class_name
                ::itcl::delete class $class_name

                set class_reload true
            }

        }

        if {$class_reload} {
            source $itcl_file
            dict set class_db $class_name mtime [file mtime $itcl_file]
        }

        return $class_reload
    }
}

package provide rwpagebroker 1.0
