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

        constructor {pagekey} {
            set key         $pagekey
            set stored_vars [dict create]
            set hits        0
        }

        public method key {} { return $key }
        public method destroy {}
        public method url_args {} { return $stored_vars }
        public method prepare_page {language argsqs}
        public method prepare {language argsqs} {}
        public method binary_content { } { return true }
        public method resource_exists {resource_key} { return false }
        public method get_resource_repr {resource_key} {return ""}
        public method print_content { language } { }
        public method postprocessing {} {}
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
    ::itcl::body RWPage::prepare_page {language argsqs} { 
        set stored_vars $argsqs 
        incr hits

        $this prepare $language $argsqs

        $this postprocessing

        return $this
    }
}
package provide rwcontent 1.0
