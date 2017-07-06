# -- rweb_content.tcl
#
# content generator root class. Each page or any other content
# generator should subclass this class. 
#
# with this class we inaugurate the term "urlhandler" which
# is meant to replace "datasource"
#

package require Itcl

namespace eval ::rwpage {

    ::itcl::class RWContent {
        private variable key
        private variable hits
        private variable stored_vars
        private variable url_handler
        private variable mimetype 

        constructor {pagekey {mime "application/octet-stream"}} {
            set key         $pagekey
            set stored_vars [dict create]
            set hits        0
            set mimetype    $mime
        }

        protected method postprocessing { urlhandler } {}

        public method set_key {k} { set key $k }
        public method key {} { return $key }
        public method destroy {}
        public method url_args {} { return $stored_vars }
        public method prepare_content { urlhandler language argsqs }
        public method prepare { language argsqs } { return $this }
        public method binary_content { } { return true }
        public method resource_exists {resource_key} { return false }
        public method get_resource_repr {resource_key} {return ""}
        public method print_content { language } { }
        public method current_handler { return $url_handler }
        public method mimetype {} { return $mimetype }
        public method content_disposition {} { return "" }
        public method content_length {} { return "" }
        public method send_headers {} 
        public method send_output {language} { $this print_content $language}
    }

# -- send_headers
#
#
    ::itcl::body RWContent::send_headers {} {

        ::rivet::headers type [$this mimetype]

        set content_disposition [$this content_disposition] 
        if {$content_disposition != ""} {
            ::rivet::headers add Content-Disposition $content_disposition
        }

        set content_length      [$this content_length]
        if {$content_length != ""} {
            ::rivet::headers add Content-Length	$content_length
        }

    }


# -- destroy
#
# releases objects which may hold data stored in the pool (e.g.
# tdom objects). Abstract method for this class

    ::itcl::body RWContent::destroy { } {
        ::itcl::delete object $this
    }

# -- prepare_content
#
#
# 
    ::itcl::body RWContent::prepare_content {urlhandler language argsqs} { 
        set stored_vars $argsqs 
        incr hits

        set url_handler $urlhandler

        set pobject [$this prepare $language $argsqs]
        $pobject postprocessing $urlhandler

        return $pobject
    }
}
package provide rwcontent 1.0
