# -- rweb_webservice.tcl
#
#   Abstract class for webservices. Provides a way to
#   log Tcl errors that otherwise would go into the
#   output channel but totally undetected by an Ajax client
#

package require Itcl

namespace eval ::rwpage {

    ::itcl::class RWWebService {
        inherit RWContent

        constructor {pagekey {content_type "application/json;charset=utf-8"}} \
            {RWContent::constructor $pagekey $content_type } {

        }

        # -- notify_error
        #
        # this method provides a way to encapsulate the error info in 
        # a JSON or XML message that can be parsed by the JavaScript
        # code of the client

        protected method notify_error {ecode einfo} {

        }

        public method prepare {language argsqs} {

            ::rivet::apache_log_error err "Running webservice: $argsqs"
            if {[catch {$this webservice $language $argsqs} e einfo]} {
                ::rivet::apache_log_error err "Error in webservice: $e"
                dict for {einfo_code einfo_text} $einfo {
                    ::rivet::apache_log_error err "$einfo_code -----------------"
                    foreach l [split $einfo_text "\n"] {
                        ::rivet::apache_log_error err $l
                    }
                }
                $this notify_error $e $einfo
            }

            return $this
        }
    }

}
package provide rwwebservice 1.0

