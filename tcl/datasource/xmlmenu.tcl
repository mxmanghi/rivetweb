#
# -- XMLMenu: Data source responsible for reading
# menu data from <website-root>/sitemap/ and talk
# to the sitemap manager to build a menu tree
#
#

package require tdom
package require rwconf
package require rwlogger
package require rwsitemap


namespace eval ::XMLMenu {

    variable sitemap

    proc init {xmlpath} {
        variable sitemap

        set sitemap $xmlpath

        if {![file isdirectory $sitemap]} {

            return -code error  -error_code invalid_path \
                                -errorinfo "Wrong path $sitemap" \
                                "Wrong path $sitemap"

        }

    }

    



}


package provide XMLMenu 1.0
