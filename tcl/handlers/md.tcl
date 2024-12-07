# -- md.tcl
#
# Attempt to implement a Markdown languange document
# handler. In this experimental implementation the 
# handler inherits and specializes XMLBase, building
# an XML document out of a MD document


package require tdom
package require rwlogger
package require rwsitemap
package require rwstatic
package require XMLBase


namespace eval ::rwdatas {

    ::itcl::class MarkDown {
        inherit XMLBase

        public method init {args}
    }

    # -- init
    #
    #

    ::itcl::body MarkDown::init {args} {
        XMLBase::init $args
    }

}

