#
# -- rweb_binary
#
# page model for a binary transfer function
#
#
package require rwpage
package require Itcl

namespace eval ::rwpage {

    ::itcl::class RWBinary {
        inherit RWPage

        private     variable count

        constructor {pagekey} {RWPage::constructor $pagekey} { }

        public method binary_content {} { return true }
        public method binary_data {language} {}
        public method print_binary {language}
        public method mimetype {} { return "application/octet-stream" }
        public method content_disposition {} { return "" }
        public method content_length {} { return "" }
        protected method save_channel_status {}
        protected method restore_channel_status {}
    }

    ::itcl::body RWBinary::save_channel_status {} {

        set stored_translation  [fconfigure stdout -translation]
        set stored_encoding     [fconfigure stdout -encoding]

    }

    ::itcl::body RWBinary::restore_channel_status {} {

        fconfigure stdout -translation $stored_translation -encoding $stored_encoding

    }

    ::itcl::body RWBinary::print_binary {language} {

        ::rivet::headers type [$this mimetype]

        set content_disposition [$this content_disposition] 
        if {$content_disposition != ""} {
            ::rivet::headers add Content-Disposition $content_disposition
        }

        set content_length      [$this content_length]
        if {$content_length != ""} {
            ::rivet::headers add Content-Length	$content_length
        }

        $this save_channel_status 
            
        fconfigure stdout -translation binary
        if {[catch { $this binary_data $language } err einfo]} {

            ::rivet::apache_log_error err "Error in binary_data"

        }
        $this restore_channel_status

    }

}

package provide rwbinary 1.0
