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

        constructor {pagekey {contenttype "application/octet-stream"}} \
                    {RWContent::constructor $pagekey $contenttype} { set data_transmitted 0 }

        public method binary_data {language} {}
        public method print_binary {language}
        public method send_output {language} { $this print_binary $language }

    }

    ::itcl::body RWBinary::print_binary {language} {

        ::rivetweb::save_channel_status 
            
        fconfigure stdout -translation binary -encoding binary
        if {[catch { set data_transmitted [$this binary_data $language] } err einfo]} {
            ::rivet::apache_log_error err "Error in RWBinary::binary_data"
        }

        ::rivetweb::restore_channel_status

        return $data_transmitted
    }

}

package provide rwbinary 1.0
