# -- pagecache.tcl
#
# This class is meant to be an internal class of the UrlHandler.
# Its purpose is to provide an abstraction layer for each url 
# handler page cache
#

#package require Itcl
#catch {::itcl::delete class PageCache}
#catch {::itcl::delete class A}

namespace eval ::rivetweb {

    ::itcl::class PageCache {
        private variable cache [dict create]

        public method store_page {key pobj}
        public method clear_entry {key}
        public method key_query {key}
        public method forall {key_var value_var tclcode}
        public method get_entry_prop {key prop}
        public method get_page_object { key } 
        public method get_entry { key }
        public method cache {} { return $cache }
    }

# -- get_entry 
#
#

    ::itcl::body PageCache::get_entry { key } {
        if {[$this key_query $key]} {
            return [dict get $cache $key]
        }
    }

# -- store_page
#
#
    ::itcl::body PageCache::store_page {key pageobj} {
        dict set cache $key object      $pageobj
        dict set cache $key timestamp   [clock seconds]
        dict set cache $key class       [$pageobj info class]
    }

# -- clear_entry
#
#

    ::itcl::body PageCache::clear_entry {key} {
        if {[$this key_query $key]} { dict unset cache $key }
    }

# -- key_query 
#
#

    ::itcl::body PageCache::key_query {key} {
        return [dict exists $cache $key]
    }

# -- get_entry_prop
#
#    cache entry property accessor 
#

    ::itcl::body PageCache::get_entry_prop {key prop} {
        if {[dict exists $cache $key $prop]} {
            return [dict get $cache $key $prop]
        } else {
            return ""
        }
    }

    ::itcl::body PageCache::get_page_object {key} {
#       return [dict get $cache $key object]
        return [$this get_entry_prop $key object]
    }

    ::itcl::body PageCache::forall {kvar vvar tclcode} {
        upvar $kvar key
        upvar $vvar value

        dict for {key value} $cache { uplevel $tclcode }
    }
}

package provide rwpagecache 1.0

#set pc [::rivetweb::PageCache #auto]
#::itcl::class A {}
#$pc store_page a0 [A #auto]
#$pc store_page a1 [A #auto]
#$pc store_page a2 [A #auto]
#
#$pc forall k v {
#
#    puts "$k: $v"
#
#}

