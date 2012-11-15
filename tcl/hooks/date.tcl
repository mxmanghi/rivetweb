# -- date
#
# An extractor of the text in the 'date' metadata field. Nothing special, just
# another example of metadata processor. It might be in charge also for getting
# other time and date related information
#

set hook_descriptor(tag)            date
set hook_descriptor(function)       timestamps_extraction
set hook_descriptor(descrip)        "a function storing the content of the date metadata field"
set hook_descriptor(stage)          metadata

proc timestamps_extraction { pageobj } {

#    namespace eval ::rivetweb::pagestatus { set date "" }
#
#    set ::rivetweb::pagestatus::date [$::rivetweb::pmodel metadata $pageobj date]
#
#    return $pageobj

}
