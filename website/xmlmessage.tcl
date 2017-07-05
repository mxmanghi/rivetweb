package require Itcl
package require UrlHandler
package require rwcontent


namespace eval ::rwpage {

    ::itcl::class XMLResponse {
        inherit RWContent

        constructor {key} {RWContent::constructor $key "text/xml"} {}

        public method print_content { language } { 

            switch [$this key] {

                timeinfo {
                    set exectime [time {
                        set current_time [::rivet::xml [clock format [clock seconds] -format "%D %T"] curtime]
                        set uptime       [::rivet::xml [string trim [exec "/usr/bin/uptime"]] utime]
                    }]
                    set exec_time [::rivet::xml $exectime exectime]

                    puts [::rivet::xml [join [list $current_time $uptime $exec_time] "\n"] xmlmessage]

                }
                default {
                    puts "<xmlerror>unrecognized command</xmlerror>"
                }

            }

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
