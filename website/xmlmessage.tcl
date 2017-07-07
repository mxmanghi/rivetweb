package require Itcl
package require UrlHandler
package require rwcontent


namespace eval ::rwpage {

    ::itcl::class XMLResponse {
        inherit RWContent

        private variable xmlbuffer
        private variable filelist

        constructor {key} {RWContent::constructor $key "text/xml"} {}

        public method init {} { 

            set flist {}
            foreach dir {. tcl tcl/datasource tcl/hooks} {
                lappend flist {*}[glob [file join $::rivetweb::rivetweb_root $dir *.tcl]]
            }
            set filelist [lmap f $flist { file tail $f }]

            ::rivet::apache_log_error notice "loaded [llength $flist] rivetweb file names"
        }

        public method content_length {} { return [string length $xmlbuffer] }

        public method mimetype {} {
            set urlargs [$this url_args]

            if {![dict exists $urlargs timeinfo]} {
                return "text/plain"
            } else {
                return [RWContent::mimetype]
            }

        }

        public method prepare { language argsqs } {

            if {[::rivet::var exists term]} {
                set term [::rivet::var get term]
                ::rivet::apache_log_error info "searching term: $term"
            } 

            if {[dict exists $argsqs timeinfo]} {
                set exectime [time {
                    set current_time [::rivet::xml [clock format [clock seconds] -format "%D %T"] curtime]
                    set uptime       [::rivet::xml [string trim [exec /usr/bin/uptime]] utime]
                    set uname        [::rivet::xml [string trim [exec /bin/uname -a]] uname]
                    set hname        [::rivet::xml [string trim [exec /bin/hostname]] hostname]
                }]
                set exec_time [::rivet::xml $exectime exectime]

                set    xmlbuffer "<?xml version=\"1.0\" encoding=\"$::rivetweb::http_encoding\"?>\n"
                append xmlbuffer [::rivet::xml [join [list $current_time $uptime $uname $exec_time $hname] "\n"] xmlmessage]

            } else {

                if {[info exists term]} {
                    set xmlbuffer [lmap f $filelist { if {[string match "${term}*" $f]} { format "\"%s\"" $f } else { continue }} ]
                } else {
                    set xmlbuffer [lmap f $filelist {format "\"%s\"" $f}]
                }

                set xmlbuffer "\[[join [lsort $xmlbuffer] ,]\]" 

            }

            return $this
        }

        public method print_content { language } { 
            puts $xmlbuffer
        }
    }
}

namespace eval ::rwdatas {
    
    ::itcl::class XMLMessage {
        inherit Datasource

        public method willHandle {arglist keyvar} 
        #public method will_provide {keyword reassigned_key}
        #public method resource_exists {resource_key} 
        public method has_updates {} { return true }
        public method fetchData {key reassigned_key}


    }

    ::itcl::body XMLMessage::willHandle {arglist keyvar} {
        upvar $keyvar key 

        if {[dict exists $arglist timeinfo] || [dict exists $arglist filelist]} {
            set key ajaxdata
            return -code break -errorcode rw_ok 
        }

        return -code continue -errorcode rw_continue
    }

    ::itcl::body XMLMessage::fetchData {key reassigned_key} {
        upvar $reassigned_key rkey
        
        set rkey $key
        switch $key {

            ajaxdata {
                set pobj [::rwpage::XMLResponse ::#auto $key]
                $pobj init
                return $pobj
            }
            default {
                set rkey page_not_found_error
                return ""
            }
        }
    }
}
package provide XMLMessage 1.0
