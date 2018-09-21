# -- pagecache.tcl
#
# This class is meant to be an internal class of the UrlHandler.
# Its purpose is to provide an abstraction layer for each url 
# handler page cache
#
    package require Itcl

    catch {::itcl::delete class PageCache}
    catch {::itcl::delete class A}

    ::itcl::class PageCache {
        private variable cache [dict create]

        public method store_entry {key pobj}
        public method clear_entry {key}
        public method key_query {key}
        public method forall {key_var value_var tclcode}
        public method get_page_object { key } 
        public method cache {} { return $cache }
    }


# -- store_entry
#
#
    ::itcl::body PageCache::store_entry {key pageobj} {
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

    ::itcl::body PageCache::get_page_object {key} {
        return [dict get $cache $key object]
    }

    ::itcl::body PageCache::forall {kvar vvar tclcode} {
        upvar $kvar key
        upvar $vvar value

        dict for {key value} $cache { uplevel $tclcode }
    }

    set pc [PageCache #auto]
    ::itcl::class A {}
    $pc store_entry a0 [A #auto]
    $pc store_entry a1 [A #auto]
    $pc store_entry a2 [A #auto]
