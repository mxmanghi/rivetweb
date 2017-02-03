#
# -- dummy.tcl
#
# dummy datasource for pages generated on the fly
#
#

package require Itcl
package require rwconf
package require rwlogger
package require rwpage
package require Datasource
package require rwbasicpage

namespace eval ::rwpage {

    ::itcl::class RWDumpPage {
        inherit RWPage

        constructor {pagekey} {RWPage::constructor $pagekey} {}

        public method print_content { language } {
            #puts -nonewline [$::rivetweb::rwebdb coredump]

            foreach ds $::rivetweb::datasources {
                set tbhead "$ds ([$ds name])"
                set dscache [$ds cache]
                set tbody ""
                dict for {key p} $dscache {
                    dict with p {

                        set rowfields "<td>$object</td>\
                                       <td>[$object key]</td>\
                                       <td>[clock format $timestamp]</td>\
                                       <td>[$object info class]<td>"

                        
                    }
                    append tbody [::rivet::xml $rowfields tr]
                }
                set tbody [::rivet::xml $tbody tbody]
                set thead [::rivet::xml $tbhead thead [list th colspan 4]]
                puts [::rivet::xml "$thead $tbody" [list table style "margin: 1em auto;"]]
            }
        }
    }
}
    

namespace eval ::rwdatas {

    ::itcl::class RWDummy { 
        inherit Datasource

        private variable urlargs
        private common MESSAGES

        public method init {args} {
            set MESSAGES [dict create \
                unknown_error_condition "Unknwon error condition (key: \$key)" \
                page_not_found_error    "page not found error. key: \$key arglist: \$urlargs" \
                wrong_datasource_returned_key {
A datasource didn't returned a valid page object
and failed to reassigned the resource key ($key)} \
                postproc_hook_error     "Error in page postprocessing"\
]
        }
        public method name {} { return "Dummy" }
        public method resource_exists {resource_key} { return true }
        public method to_url {lm} {

            set linkmodel   $::rivetweb::linkmodel

            set urlargs [$linkmodel arguments $lm]
            set urlargs [::rivetweb merge_sticky_args $urlargs]
            #::rivet::html "base href: $href ($urlargs)" div b

            set href [::rivetweb::composeUrl {*}$urlargs]

# we now set the href attribute of the link

            $linkmodel set_attribute lm [list href $href]

            return $lm
        }

        public method is_stale {key timereference} {

            switch $key {
                rw_coredump {
                    return false
                }
                default {
                    return [Datasource::is_stale $key $timereference]
                }
            }

        }

        public method willHandle {arglist keyvar} { 
            upvar $keyvar key 

            set urlargs [dict create {*}$arglist]
            if {[dict exists $urlargs coredump]} { 
                set key rw_coredump
            } else {
                set key page_not_found_error
            }
            return -code break -errorcode rw_ok 
        }

        public method fetchData {key reassigned_key} {
            upvar $reassigned_key rkey

            set rkey $key
            if {$key == "rw_coredump"} {

                #set pobj [::rwpage::RWBasicPage ::#auto $rkey [$::rivetweb::rwebdb coredump]]
                set pobj [::rwpage::RWDumpPage ::#auto rw_coredump]
                $pobj set_title $::rivetweb::default_lang "Core database dump"
                
            } else {

                if {![dict exists $MESSAGES $key]} {
                    set rkey unknown_error_condition
                }

                set page_text [subst [dict get $MESSAGES $rkey]]
                set pobj [::rwpage::RWBasicPage ::#auto $rkey $page_text]
                $pobj set_title $::rivetweb::default_lang "Error $rkey"

            }
            return $pobj
        }

    # -- register_error
    #
    # We register to the message dictionary basic error messages
    # that might be useful in several context within an application


        public proc register_error {key error_message} {

            dict set MESSAGES $key $error_message

        }

    # -- rivetwebPage
    #
    # central hub method to create rivetweb specific 
    # messages
    #

        public proc rivetwebPage {page_key} {

        }

    }
}

package provide RWDummy 1.1
