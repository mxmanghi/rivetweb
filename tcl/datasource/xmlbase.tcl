#
# -- XMLBase
#
# Base unified datasource model. This model reads sitemap files to 
# build a menu tree and reads XML data from files to build pages objects
#
#

package require Thread

package require tdom
package require rwconf
package require rwlogger
package require rwsitemap
package require rwpmodel

# temporary variable names
#
# - sitemap -> Path to sitemap dir
# - timestamp -> saved timestamp of the sitemap dir
# - sitemap_stat -> [file stat] info for sitemap dir
# - xmlpath -> path to xml pages
#

namespace eval ::XMLBase {
    variable sitemap
    variable timestamp          0
    variable sitemap_stat   
    variable xmlpath
    variable datachannel

    proc init {xmldata xmlsitemap} {
        variable xmlpath
        variable sitemap
        variable sitemap_stat   
        variable datachannel

# we first set up the variables controlling the sitemap

        array set sitemap_stat {}
        set sitemap [file normalize [file join $::rivetweb::site_base $xmlsitemap]]

        if {![file isdirectory $sitemap]} {

            return -code error  -error_code invalid_path \
                                -errorinfo  "Wrong path $sitemap" \
                                            "Wrong path $sitemap"

        }
        
# and the we set the path to the XML pages

        set xmlpath [file join $::rivetweb::site_base pages]

        set datachannel [::thread::create {

            set mtx [::thread::mutex create]
        }]


        ::thread::send $datachannel [list set xmlpath $xmlpath]
    }




}
