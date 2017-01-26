#
# -- XMLBase
#
# Base unified datasource model. This model reads sitemap files to 
# build a menu tree and reads XML data from files to build pages objects
#
#

package require Itcl
package require tdom
package require rwconf
package require rwlogger
package require rwsitemap
package require rwstatic
package require rwmenu
package require rwlink
package require Datasource
package require struct::stack
package require rwbasicpage

# temporary variable names
#
# - sitemap_dir -> Path to sitemap dir
# - timestamp -> saved timestamp of the sitemap dir
# - sitemap_stat -> [file stat] info for sitemap dir
# - xmlpath -> path to xml pages
#

namespace eval ::rwdatas {

    ::itcl::class XMLBase {
        inherit Datasource

        public  variable menutclclass "" {set forceupdate 1}
        public  variable sitemap
        private variable sitemap_dir        sitemap
        private variable static_pages       pages
        private common   LOCAL_PAGES	    docs
        private variable timestamp          0
        private variable sitemap_stat   
        private variable xmlpath
        private variable current
        private variable forceupdate        0

        private method buildPageEntry {key xmldata reassigned_key}
        private method time_reference {xmlbase} 
        private method listStaticMenus {sm parent_mg}
        private method menuclass {menu_o}        
        protected method xmlfile {key} { return [file join $static_pages ${key}.xml] }
        protected method xmlsitemaps {sitemap_key} { return [glob -nocomplain [file join $sitemap_key *.xml]] }

        public method init {args}
        public method willHandle {arglist keyvar}
        public method fetchData {key reassigned_key}
        public method storeData {key data_dict}
        public method create {key page_data}
        public method is_stale {key timereference}
        public method has_updates {} 
        public method name {} { return "XMLBase" }
        public method load_sitemap {sitemap_mgr {ctx ""}}
        public method menu_list {page} 
        public method resource_exists {resource_key} 
        public method get_resource_repr {resource_key} 
        public method to_url {lm}
        public proc   makeUrl {reference} 
    }

    ::itcl::body XMLBase::init {args} {

        $::rivetweb::logger log debug "working from directory $::rivetweb::site_base"
        set ::rwdatas::static_pages $static_pages
        set ::rwdatas::local_pages  $LOCAL_PAGES

    # we first set up the variables controlling the sitemap

        array set sitemap_stat {}

    # let's rewrite the path to the sitemap

        set sitemap_dir  [file normalize [file join $::rivetweb::site_base $sitemap_dir]]
        if {![file exists $sitemap_dir]} {

            $::rivetweb::logger log notice "creating sitemap path dir ($sitemap_dir)"
            file mkdir $sitemap_dir

        } elseif {![file isdirectory $sitemap_dir]} {

            $::rivetweb::logger log notice "Wrong path for sitemap ($sitemap_dir)"
            return -code error  -error_code invalid_path                \
                                -errorinfo  "Wrong path $sitemap_dir"   \
                                            "Wrong path $sitemap_dir"
        } else {
            $::rivetweb::logger log notice "setting sitemap path as $sitemap_dir"
        }

        set static_pages [file normalize [file join $::rivetweb::site_base $static_pages]]
        if {![file exists $static_pages]} {

            $::rivetweb::logger log notice "creating sitemap path dir ($static_pages)"
            file mkdir $static_pages

        } elseif {![file isdirectory $static_pages]} {
            $::rivetweb::logger log notice "Wrong path for sitemap ($static_pages)"
            return -code error  -error_code invalid_path                \
                                -errorinfo  "Wrong path $static_pages"   \
                                            "Wrong path $static_pages"
        } else {
            $::rivetweb::logger log notice "setting pages path as $static_pages"
        }
        
    # and the we set the path to the XML pages

        set xmlpath [file join $::rivetweb::site_base pages]
        set sitemap [::rwsitemap::create ::XMLBase]
        load_sitemap $sitemap

        set menutclclass $::rivetweb::menuclass
    }

#
# -- willHandle
#
# fundamental method that has to return a string to work as a unique 
# key in the website database.
# If the datasource is not to handle the request the procedure has
# to return with a -status continue
#

    ::itcl::body XMLBase::willHandle {arglist keyvar} {
        upvar $keyvar key 

        ## debug puts "<pre>arglist = $arglist</pre>"
        set key         index
        if {[dict exists $arglist show]} {
            set key [dict get $arglist show]
        } elseif {[dict exists $arglist store]} {
            set key [dict get $arglist store]
        } else {

            set ag $arglist
            ### puts "<pre>ag = $ag ($::rivetweb::passthroughs)</pre>"
            foreach {urlarg argval} $arglist {
                if {[lsearch $::rivetweb::passthroughs $urlarg] < 0} {
                    continue
                } else {
                    set ag [lassign $ag a b]
                }
            }

            if {[llength $ag] > 0 } {
                return -code continue -errorcode rw_continue
            }
            ### puts "<pre>ag = $ag</pre>"
        } 
        if {$key == "index"} { set ::rivetweb::is_homepage 1 }

        $::rivetweb::logger log info "mapping key $key for processing"

        return -code break -errorcode rw_ok 
    }

#
# -- buildPageEntry
#
#
#

    ::itcl::body XMLBase::buildPageEntry {key xmldata reassigned_key} {
        upvar $reassigned_key rkey

        $::rivetweb::logger log debug "getting data for key $key"

        set xmldom [dom parse $xmldata]
        set domroot [$xmldom documentElement root]
        if {[$domroot hasAttribute id]} {
            set rkey [$domroot getAttribute id]
            set key  $rkey
        } else {
            set rkey $key
        }

        set menu_d      [dict create]
        set metadata_l  {}

# metadata are stored accordingly. <menu>...</menu> elements
# receive a special treatment and go into the menu_d dictionary
# before they get into the page metadata

        foreach c [$domroot child all] {
            switch [$c tagName] {
                content {
                    continue
                }
                menu {
                    if {[$c hasAttribute position]} {
                        set position [$c getAttribute position]
                    } else {
                        set position $::rivetweb::menu_default_pos
                    }
                    dict set menu_d menu [$c getAttribute position $position] [$c text]
                }
                title -
                headline {
                    # we ignore these elements in the page root and
                    # we'll consider only title and headline in
                    # the <content>...</content> element

                    continue
                }
                default {
                    lappend metadata_l [$c tagName] [::rivet::escape_shell_command [$c text]]
                }
            }
        }

        set newpage [::rwpage::RWStatic ::#auto $key]
#       puts "<br/>[html $metadata_l b u]"
#       $::rivetweb::pmodel set_metadata newpage $metadata_l
        set menu_d [dict merge $menu_d [dict create {*}$metadata_l]]
        $newpage put_metadata $menu_d
        $newpage add_metadata datasource ::XMLBase

# data are scanned for <content>...</content> elements to be stored in the page object 'newpage'

        foreach content [$domroot getElementsByTagName content] {

            if {[$content hasAttribute language]} {
                set clang [$content getAttribute language]
            } else {
                set clang $::rivetweb::default_lang
            }

            foreach c [$content childNodes] {

# adding content for language '$clang'

                set node_name [$c nodeName]
                switch $node_name {
                    pagetext {

# creiamo un nuovo dom

                        set cdom [dom parse [$c asXML]]
                        $::rivetweb::logger log info "Adding content for language $clang ($key)"
                        $newpage set_content $clang pagetext $cdom

                    } 
                    title {
                        $newpage title $clang [$c text]
                    }
                    default {
                        $newpage set_content $clang $node_name [$c text]
                    }
                }
            }
        }

        return $newpage
    }

# -- time_reference 
#
# returns a time stamp of the requested resource. This method
# is private and we assume it's called after the existence of 'key'
# has been checked by calling [resource_exists]
#
    ::itcl::body XMLBase::time_reference {key} {

        file stat [$this xmlfile $key] file_stat
        return $file_stat(mtime)

    }

# -- is_stale
#
# returns a boolean condition if the resource linked to 'key' has
# to be refreshed
#
    ::itcl::body XMLBase::is_stale {key timereference} {
        
        if {$key == "xml_page_not_found_error"} { return true }

        if {[$this resource_exists $key]} {
            set current_timeref [$this time_reference $key]
            return [expr $timereference < $current_timeref]
        } else {
            set errinfo "[$this name] Resource $key not found"
            return -code error -errorcode resource_not_found -errorinfo $errinfo $errinfo
        }
    }

# -- resource_exists
# -- get_resource_repr
#

    ::itcl::body XMLBase::resource_exists {key} {

        if {$key == "xml_page_not_found_error"} { return 1 }

        return [file exists [$this get_resource_repr $key]]
    }

    ::itcl::body XMLBase::get_resource_repr {key} {   
        return [$this xmlfile $key]
    }


# -- fetchData 
# 
# This method retrieves a page content from the backend. This implementation
# looks for an XML file in the website directory tree ( now ::XMLBase::static_pages). 
#

    ::itcl::body XMLBase::fetchData {key reassigned_key} {
        upvar $reassigned_key rkey
        
        set rkey $key
        if {$key == "xml_page_not_found_error"} {

            set pagedbentry [::rwpage::RWBasicPage ::#auto $key "XML File not found"]

        } elseif {[$this resource_exists $key]} {

            set xmlfile [$this get_resource_repr $key]

            $::rivetweb::logger log info "->opening $xmlfile" 
            if {[catch {
                set xmlfp    [open $xmlfile r]
                set xmldata  [read $xmlfp]
                set xmldata  [regsub -all {<\?} $xmldata {\&lt;?}]
                set xmldata  [regsub -all {\?>} $xmldata {?\&gt;}]
#               puts stderr $xmldata
                close $xmlfp
            } fileioerr]} {
                set page_error_msg "Impossible to read page '$key' ($fileioerr)"
                $::rivetweb::logger err "[$this name] $page_error_msg"
                set pagedbentry [::rwpage::RWBasicPage ::#auto xmlbase_error_reading_data $page_error_msg]
            } else {
                set pagedbentry [$this buildPageEntry $key $xmldata rkey]
            }

        } else {

            $::rivetweb::logger log notice "page for key '$key' not found ([$this get_resource_repr $key])"
            set pagedbentry ""
            set rkey xml_page_not_found_error
        }

        return $pagedbentry
    }

# -- has_updates
#
#

    ::itcl::body XMLBase::has_updates {} {

        if {$forceupdate} {
            set forceupdate 0
            return true
        }

        file stat $sitemap_dir sitemap_stat

        $::rivetweb::logger log debug " menu timestamp t1: $sitemap_stat(mtime), t2: $timestamp"
        if {($sitemap_stat(mtime) > $timestamp)} { 

            return true
        }

        return false
    }

# -- storeData
#
#

    ::itcl::body XMLBase::storeData {key data_dict} {

        set xmldata [$this create $key $data_dict]
        
        return [$this buildPageEntry $key $data_dict reassigned_key]

    }
    

# -- create
#
#

    ::itcl::body XMLBase::create {key page_data} {

        set msgdom  [dom createDocument page]
        set xml_o   [$msgdom documentElement]
        $xml_o setAttribute id $key

# ident metadata element

        set elem_o [$msgdom createElement ident]
        set dom_txt [$msgdom createTextNode "\$Id: [clock format [clock seconds]]"]
        $xml_o appendChild $elem_o

        set elem_o [$msgdom createElement date]
        set dom_txt [$msgdom createTextNode [clock format [clock seconds] -format "%Y-%m-%d"]
        $xml_o appendChild $elem_o

# if an author is existing

        set elem_o [$msgdom createElement author]
        if {[dict exists $page_data author]} {
            set dom_txt [$msgdom createTextNode [dict get $page_data author]]]

        } else {
            set dom_txt [$msgdom createTextNode ""]
        }
        $xml_o appendChild $elem_o

# if there are menus in the data

        if {[dict exists $page_data menus]} {

            foreach pos [dict get $page_data menus] {

                set elem_o  [$msgdom createElement menu]
                set dom_txt [$msgdom createTextNode [dict get $page_data menus $pos]]

            }
        }
        $xml_o appendChild $elem_o

# finally we get to the page creation

        set lang $::rivetweb::default_lang
        if {[dict exists $page_data language]} {
            set lang [dict get $page_data language]
        }

        if {[dict exists $page_data language]} {
            set language [dict get $page_data language]
        } else {
            set language $::rivetweb::default_lang
        }

        set content_o [$msgdom createElement content]
        $content_o setAttribute language $language
# 
        set content ""
        set title   ""

        if {[dict exists $page_data title]} {
            set title   [dict get $page_data title]
        }
        set title_o  [$msgdom createElement title]
        set dom_txt [$msgdom createTextNode $title]
        $title_o appendChild $dom_txt

        set headline $title
        if {[dict exists $page_data headline]} {
            set headline [dict get $page_data headline]
        }
        set head_o  [$msgdom createElement headline]
        set dom_txt [$msgdom createTextNode $headline]
        $head_o appendChild $dom_txt

        if {[dict exists $page_data content]} {
            set content [dict get $page_data content]
        }
        set pagetxt_o [$msgdom createElement pagetext]
        set dom_txt   [$msgdom createTextNomde $content]
        $pagetxt_o appendChild $dom_txt

        $content_o appendChild $head_o
        $content_o appendChild $title_o
        $content_o appendChild $pagetxt_o

        return $xml_o
    }

# -- menuclass
#
#

    ::itcl::body XMLBase::menuclass {menu} {

        if {[$menu hasAttribute tclclass]} {
            return [$menu getAttribute tclclass]
        }

        # we may dispose of this...

        if {[string length $menutclclass] > 0} {
            return $menutclclass
        }

        if {[dict exists $::rivetweb::templates_db menuclass]} {
            return [dict get $::rivetweb::templates_db menuclass]
        }

        return $::rivetweb::menuclass
    }


# -- listStaticMenus
#
# private method that walks the menu tree and actually builds
# the menu objects (either instances of ::rwmenu:RWMenu or ::rwmenu::$tclclass)
# Also their link objects lists (lists of ::rwlink::RWLink class instances) are
# created and associated to the menu objects
#

    ::itcl::body XMLBase::listStaticMenus {sm parent_mg} {
        
        set menumodel $::rivetweb::menumodel
        array set group_menu_list {}

        foreach menu [$sm getElementsByTagName menu] {
            foreach cn [$menu childNodes] {
                $::rivetweb::logger log debug "  $menu: [$cn nodeName] - [$cn asXML]"
            }                            

# again, menus without an id are ignored. 
# How can we be sure to avoid id definition clashes?
# This is an issue still to be solved....

            if {[$menu hasAttribute id]} {

                if {[$menu hasAttribute parent]} {
                    set parent  [$menu getAttribute parent]
                } else {
                    set parent  $parent_mg
                }

                if {[$menu hasAttribute visibility]} {
                    set visibility [$menu getAttribute visibility]
                } else {
                    
                    if {[$menu hasAttribute type]} {
                        set visibility [$menu getAttribute type]
                    } else {
                        set visibility normal
                    }

                }

                # let's rely entirely on the inner machinery for
                # determining the menu classes

                set tclclass [$this menuclass $menu]
                package require [string tolower $tclclass]

                set menuobj [::rwmenu::$tclclass ::rwmenu::#auto [$menu getAttribute id] $parent $visibility]

                # Elements within 'menu' are <title lang="..">...</title> and
                # one or more <link>....</link>

                set headers [$menu getElementsByTagName title]
                foreach title $headers {

                    if {[$title hasAttribute lang]} {
                        set language [$title getAttribute lang]
                    } elseif {[$title hasAttribute language]} {
                        set language [$title getAttribute language]
                    } else {
                        set language $::rivetweb::default_lang
                    }

                    $menuobj assign title [$title text] $language
                }

                $menuobj assign parent $parent_mg

        # links are interpreted here. A link obj should be created
        # for each of them using the linkmodel interface

                set links [$menu getElementsByTagName link]
                set lm    $::rivetweb::linkmodel
                foreach l $links {

                    set ltype ""
                    set lref  index
                    set linfo [dict create]
                    set ltext [dict create]
                    set largs [dict create]
                    set attributes {}
                    set doctarget ""
                    set lowner    [$this name]
                    foreach linkdata [$l childNodes] {

        # In order not to replicate the same snippet of code
        # we anyway try to determine the language of the link, 
        # regardless it's meaninful or not
                    
                        if {[$linkdata hasAttribute lang]} {
                            set language [$linkdata getAttribute lang]
                        } elseif {[$linkdata hasAttribute language]} {
                            set language [$linkdata getAttribute language] 
                        } else {
                            set language $::rivetweb::default_lang
                        }

        # XMLBase assumes every tag not explicitly handled to be an attribute
        # of the <a ...> tag. This comes from the subsequent adjustments done
        # on the XML sitemap definition, but are arguably correct or well designed.

                        set tagname   [$linkdata tagName]
                        switch $tagname {
                            text {
                                dict set ltext $language [$linkdata text]
                                foreach infoel [$linkdata getElementsByTagName info] {
                                    dict set linfo $language [$infoel text]
                                }
                            }
                            datasource 
                            {
                                set lowner [$linkdata text]
                            }
                            type {
                                set ltype [$linkdata text]        
                            }
                            url -
                            reference {
                                set lref [$linkdata text]
                            }
                            args {
                                foreach argument [$linkdata getElementsByTagName param] {
                                    if {[$argument hasAttribute value]} {
                                        dict set largs [$argument text] [$argument getAttribute value]
                                    }
                                }
                            }
                            doctarget {
                                set doctarget [$linkdata text]
                            }
                            default {
                                lappend attributes $tagname [$linkdata text]
                            }
                        }
                    }
                    set linkobj [$lm create $lowner $lref $ltext $largs $linfo]
                    $lm set_property linkobj type $ltype
                    if {$doctarget != ""} { $lm set_urltarget linkobj $doctarget }

                    set attributes [string trim $attributes]

                    #::rivet::apache_log_error err "Attributes: $attributes [::rivet::lempty $attributes] [llength $attributes]"
                    if { [llength $attributes] > 0 } { $lm set_attribute linkobj $attributes }
                    $menuobj add_link $linkobj
                    ### coredump here !!!! #### ::rivet::apache_log_error notice "adding link for [$this to_url $linkobj]"
                }

            # checking 'position' attribute

                if {[$menu hasAttribute position]} {
                    set position [$menu getAttribute position]
                    $::rivetweb::logger log debug "$menuobj has position $position"
                    if {[string is integer $position]} {
                        lappend group_menu_list($position) $menuobj
                    } else {
                        lappend group_menu_list(1000) $menuobj
                    }
                } else {
                    lappend group_menu_list(1000) $menuobj
                }
            }
        }

        $::rivetweb::logger log debug "->collected menus [array get group_menu_list]"
        set positions [lsort -integer [array names group_menu_list]]
        set group_list {} 
        foreach group_pos $positions { lappend group_list {*}$group_menu_list($group_pos) }

        return $group_list
    }

# -- load_sitemap
#
# Must call the sitemap manager methods to build (update) a sitemap 
#
#

    ::itcl::body XMLBase::load_sitemap {sitemap_mgr {ctx ""}} {

        set logger $::rivetweb::logger
        $logger log info "recreating sitemap"

        $sitemap_mgr recreate

        file stat $sitemap_dir  sitemap_stat
        set timestamp $sitemap_stat(mtime) 

        array unset xmlmenu

# This object assumes the files to be in the 'sitemap_dir' directory
# (its existence has been already checked in 'init')

        set xmlmenus [xmlsitemaps $sitemap_dir]

# if there is no menu tree defined we give the database tree 
# an empty root menu

        if {[llength $xmlmenus] == 0} {
            $logger log notice "no menu file found"
            set xml "<sitemenus id=\"home\"></sitemenus>"
        } else {

            foreach xmlfile $xmlmenus {
                $logger log notice "reading $xmlfile..."

                set xml [::rivet::read_file $xmlfile]
                set map [file tail $xmlfile]
                if {[catch { set xmlmenu($map) [dom parse $xml] } e]} {
                    $logger log err "could not parse map $map: $e"
                }
            }

        }

        foreach mdoc [array names xmlmenu] {
            
            $logger log info "analyzing data for $mdoc...."

            set sitemenus [$xmlmenu($mdoc) getElementsByTagName sitemenus]
            foreach sm $sitemenus {

# any menu without an id is simply ignored. This should be documented

                if {[$sm hasAttribute id]} {

                    set group_menu_id   [$sm getAttribute id]
                    set group_parent    [$sm getAttribute parent root]
                    
# it seems the position isn't used in any way....

                    if {[$sm hasAttribute position]} {
                        set position [$sm getAttribute position]
                        if {![string is integer $position]} { set position end }
                    }

                    $sitemap_mgr add_menu_group $group_parent $group_menu_id \
                                            [listStaticMenus $sm $group_parent]
                    
                    $logger log notice "adding $group_menu_id to $group_parent"

                } else {

                    $logger log alert "skipping data from $mdoc, missing menu id"

                }
            }
        }
    }

# -- menu_list
#
# XMLBase::menu_list has the special role to provide the base menu 
#

    ::itcl::body XMLBase::menu_list {page} {

#       puts "<br/><b>pmodel</b>: $page"
#       puts "<br/><b>ds</b>: [$page metadata datasource]"

        if {[has_updates]} {
            load_sitemap $sitemap
        }

        if {[$page metadata datasource] == "::XMLBase"} {

            set menul [$page metadata menu]

        } else {

            set menul [dict create  $::rivetweb::default_menu_pos \
                                    $::rivetweb::default_menu]

        }

        #puts "<pre>menul: $menul</pre>"
        set menudb [dict create]
        foreach {group menuid} $menul {
            set menuid_list [$sitemap menu_list $menuid]
            if { [llength $menuid_list] > 0 } {
                dict set menudb $group $menuid_list
            }
        }
        #puts "<pre>menudb: $menudb</pre>"

        return $menudb
    }

# -- to_url
#
# metodo che deve elaborare il link object e trasformarlo 
# componendo la url finale (chiamando makeUrl)

    ::itcl::body XMLBase::to_url {lm} {
        set linkmodel $::rivetweb::linkmodel
        switch [$linkmodel property $lm type] {

            internal {
                $linkmodel set_attribute lm [list href [::rwdatas::XMLBase::makeUrl $lm]]
            }
            local {
                set lref [$linkmodel reference $lm]
                if {[::rwdatas::Datasource::get_alias $lref lref]} {
                    set href $lref
                } else {
                    set href [file join "/" $LOCAL_PAGES $lref]
                }
                $linkmodel set_attribute lm [list href $href]
            }
            external {
                $linkmodel set_attribute lm [list href [$linkmodel reference $lm]]
            }
            default {

                ::rivet::apache_log_error err "Invalid reference for link $lm for data source [$this name]"
                $::rivetweb::linkmodel set_attribute lm {href ""}
            }

        }
        return $lm
    }

# -- makeUrl
#
#
# References are built accordingly to the mode we are generating a page
# (either static or dynamic). In case the 'lang' or 'reset' parameters are 
# passed in their values are appended to the local path
#
# Arguments:
#
#   reference:  a string that works as a key to the page to be generated. 
#
# Returned value:
#
#   the URL to the page in relative form.
#
# 21-11-2012 Rivetweb has gone dynamic. Supporting static links requires every datasource to
# provide a one-to-one map between keys and set of parameters. 
#

    ::itcl::body XMLBase::makeUrl {lm} {

        set linkmodel $::rivetweb::linkmodel
        set reference [$linkmodel reference $lm]

        if {[string length $reference] == 0} {
            set reference $::rivetweb::index
        }

# URL arguments composition

        set urlargs [dict create show $reference {*}[$linkmodel arguments $lm]]
        if {[$linkmodel get_urltarget $lm target]} {
            lappend urlargs # $target
        }
 
        return [::rivetweb::composeUrl {*}$urlargs]
    }
}

package provide XMLBase 2.1
