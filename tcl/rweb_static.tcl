#
# -- rweb_page.tcl
#
# base class for every page model providing for base
# methods and common interface to every other page model
#

package require Itcl

namespace eval ::rwpage {

    ::itcl::class RWStatic {
        inherit RWPage

        constructor {pagekey} {RWPage::constructor $pagekey} {

        }

        public method set_pagetext {language page_text {rootel "p"}} 
    }

# -- set_pagetext
#
#

    ::itcl::body RWStatic::set_pagetext {language page_text {rootel "p"}} {

        set page_dom  [dom createDocument pagetext]
        set page_o    [$page_dom documentElement]

        $page_o appendXML "<${rootel}>$page_text</${rootel}>"

        dict set content $language pagetext $page_dom
    }

}
package provide rwstatic 0.1
