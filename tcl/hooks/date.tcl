# -- date
#
# An extractor of the text in the 'date' metadata field. Nothing special, just
# another example of metadata processor. It might be in charge also for getting
# other time and date related information
#

set hook_descriptor(tag)            date
set hook_descriptor(function)       timestamps_extraction
set hook_descriptor(descrip)        "Extracting the page timestamp from metadata"
set hook_descriptor(stage)          metadata

proc timestamps_extraction { pageobj } {

    set datetime [$pageobj metadata date]
    if {$datetime == ""} { return }
    
    if {[regexp {\$Date: (.+) \$} $datetime m dt]} {
        $pageobj set_metadata [list date $dt]
    }

}
