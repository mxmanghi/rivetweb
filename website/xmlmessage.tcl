package require Itcl
package require UrlHandler
package require rwcontent


namespace eval ::rwpage {

    ::itcl::class XMLResponse {
        inherit RWContent

        private variable xmlbuffer

        constructor {key} {RWContent::constructor $key "text/xml"} {}

        public method content_length {} { return [string length $xmlbuffer] }

        public method prepare { language argsqs } {

            set xmlbuffer "<?xml version=\"1.0\" encoding=\"$::rivetweb::http_encoding\"?>"

            switch [$this key] {

                timeinfo {
                    set exectime [time {
                        set current_time [::rivet::xml [clock format [clock seconds] -format "%D %T"] curtime]
                        set uptime       [::rivet::xml [string trim [exec /usr/bin/uptime]] utime]
                        set uname        [::rivet::xml [string trim [exec /bin/uname -a]] uname]
                        set hname        [::rivet::xml [string trim [exec /bin/hostname]] hostname]
                    }]
                    set exec_time [::rivet::xml $exectime exectime]

                    append xmlbuffer [::rivet::xml [join [list $current_time $uptime $uname $exec_time $hname] "\n"] xmlmessage]

                }
                default {
                    set xmlbuffer "<xmlerror>unrecognized command</xmlerror>"
                }

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

        if {[dict exists $arglist timeinfo]} {
            set key timeinfo
            return -code break -errorcode rw_ok 
        }

        return -code continue -errorcode rw_continue
    }

    ::itcl::body XMLMessage::fetchData {key reassigned_key} {
        upvar $reassigned_key rkey
        
        set rkey $key
        switch $key {

            timeinfo {
                return [::rwpage::XMLResponse ::#auto $key]
            }
            default {
                set rkey page_not_found_error
                return ""
            }
        }
    }
}
package provide XMLMessage 1.0
