# -- rweb_content.tcl
#
# content generator root class. Each page or any other content
# generator should subclass this class
#

package require Itcl

namespace eval ::rwpage {

    ::itcl::class RWContent {
        private variable key
        private variable hits
        private variable stored_vars
        private variable url_handler

        constructor {pagekey} {
            set key         $pagekey
            set stored_vars [dict create]
            set hits        0
        }

        protected method postprocessing { urlhandler } {}

        public method key {} { return $key }
        public method destroy {}
        public method url_args {} { return $stored_vars }
        public method prepare_content { urlhandler language argsqs }
        public method prepare { language argsqs } {}
        public method binary_content { } { return true }
        public method resource_exists {resource_key} { return false }
        public method get_resource_repr {resource_key} {return ""}
        public method print_content { language } { }
        public method current_handler { return $url_handler }
    }

# -- destroy
#
# releases objects which may hold data stored in the pool (e.g.
# tdom objects). Abstract method for this class

    ::itcl::body RWPage::destroy { } {
        ::itcl::delete object $this
    }

# -- prepare
#
#
# 
    ::itcl::body RWPage::prepare_content {urlhandler language argsqs} { 
        set stored_vars $argsqs 
        incr hits

        set url_handler $urlhandler

        $this prepare $language $argsqs
        $this postprocessing $urlhandler

        return $this
    }
}
package provide rwcontent 1.0
