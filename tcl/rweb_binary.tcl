#
# -- rweb_binary
#
# page model for a binary data transfer function
#
#
package require rwcontent

namespace eval ::rwpage {

    ::itcl::class RWBinary {
        inherit RWContent

        protected variable data_transmitted

        constructor {pagekey} {RWContent::constructor $pagekey} { set data_transmitted 0 }

        public method binary_data {language} {}
        public method print_binary {language}
        public method content_disposition {} { return "" }
        public method content_length {} { return "" }
        public method send_output {language} { $this print_binary $language }
        public method send_headers {} 

    }

    ::itcl::body RWBinary::send_headers {} {

        RWContent::send_headers 

        set content_disposition [$this content_disposition] 
        if {$content_disposition != ""} {
            ::rivet::headers add Content-Disposition $content_disposition
        }

        set content_length      [$this content_length]
        if {$content_length != ""} {
            ::rivet::headers add Content-Length	$content_length
        }

    }


    ::itcl::body RWBinary::print_binary {language} {

        ::rivetweb::save_channel_status 
            
        fconfigure stdout -translation binary
        if {[catch { set data_transmitted [$this binary_data $language] } err einfo]} {

            ::rivet::apache_log_error err "Error in RWBinary::binary_data"

        }

        ::rivetweb::restore_channel_status

        return $data_transmitted
    }

}

package provide rwbinary 1.0
