#
# -- datachannel.tcl
#
#

package require Thread
package require rwconf
package require rwlogger


namespace eval ::DataChannel {
    
    variable xmlpath
    variable status

    proc init {xmlpth} { 
        variable xmlpath
        variable status


        set xmlpath $xmlpth
        set status [dict create result "" error_code RW_OK]
    }


    proc fetchData {data_key} {
        variable status

        set status RW_WAIT

        set xmlfile [file join $xmlpath ${key}.xml]
        $::rivetweb::logger log info "->opening $xmlfile" 

        if {[file exists $xmlfile]} {
            if {[catch {
                set xmlfp    [open $xmlfile r]
                set xmldata  [read $xmlfp]
                set xmldata  [regsub -all {<\?} $xmldata {\&lt;?}]
                set xmldata  [regsub -all {\?>} $xmldata {?\&gt;}]
#               puts stderr $xmldata
                close $xmlfp
            } fileioerr]} {
                
                

            } else {

                set pagedbentry [buildPageEntry $key $xmldata rkey]
                return $pagedbentry

            }
        } else {



            $::rivetweb::logger log info "$xmlfile not found"
            set notexisting_msg "The requested page does not exist"
#           return [::rivetweb::buildSimplePage $notexists_msg message $page_id]
            return -code error  -errorcode not_existing         \
                                -errorinfo $notexisting_msg     $notexisting_msg
        }
        

        set status RW_OK
    }

}
