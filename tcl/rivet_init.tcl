#
# $Id: rivet_init.tcl 2104 2011-12-18 00:24:45Z massimo.manghi $
#
#+
#  Child initialization
#-
#

package require tdom
package require Rivet

namespace eval ::rivetweb {

# this must be the local path to the site's document root

#   set site_base           [file dirname [info script]]
    set static_pages        [file join $site_base pages]
    set sitemap             [file join $site_base sitemap]
    set local_pages	        [file join $site_base docs]

    set sitemap_mtime       0

# these are relative to the DocumentRoot

    set picts_path          picts
    set css_path            css
    set base_templates      templates
    set running_template    [file join $base_templates base.rvt]
    set running_css         [file join $base_templates base.css]
    set default_template    rwbase

    set template_key        ""

# the procedure should quite easly evolve to have 
# the ability to handle multilingual contents. 'default_lang' 
# is the language if not explicitly defined in the url through
# the parameter 'lang'. This variable is given a value
# here but it will be assigned by the element <default_language>
# in site_structure.xml

    set default_lang        en

#   set sitemap_file        site_structure.xml
    set site_defs           site_defs.xml
    set language            $default_lang

# 'current_rev' is an integer number specifying
# the current revision of the site.
# When pages are generated dynamically we rebuild 
# menus and contents as 'current_rev' changes  or
# if 'reset' parameter is coded in the url

    set current_rev         0

# array that maps 'content' keys and xhtml (to be replaced
# by a dictionary?)

    array set pagine        {}

# default key for content generation: basically this
# is the key to the file containing the homepage.

    set index               index
    set page_content        0

# we assume we are running dynamic. A static parameter in the url
# would emulate a static site 

    set static_links        false

    set running_picts_path  $picts_path
    set running_css_path    $css_path

# static pages weill pretend to be stored in this directory

    set static_path         static

# page variables used to pass parameters between procs and pages

    array set html_menu     {}
    array set content       {}

    set page_headline       ""
    set page_title          ""
    set page_content_html   ""
    set last_modified       ""
    set page_authors        ""
    set ident               ""
    set site_structure_mtime 0

# the effect of this are rather sticky, because when enabled 
# rivetweb uses the in-memory cache whenever possible 
# and won't change attitude until che child process exits
 
    set use_page_cache      0

# dictionary defining tags and class attributes for elements a menu
# is made of

    set templates_db       [dict create]

    dict set templates_db rwbase menu_html       {div staticmenu}
    dict set templates_db rwbase title_html      {div menuheader}
    dict set templates_db rwbase it_cont_html    {div itemcontainer}
    dict set templates_db rwbase item_html       {span menuitem}
    dict set templates_db rwbase link_class      navitem

    set debug               0
    set hooks_dir           hooks

    set hooks               [dict create]

# parameters for downloading binary files

    set download_proc       download.tcl
    set dwload_threshold    65536
    set dwload_chunk_size   16384

# -- menuTitle
#
# menuTitle accepts a rivetweb xml object as argument. The procedure
# returns the contents of title element. 
#

    proc menuTitle {menuObj {language en}} {
        set title_candidate ""
        set title_objs  [$menuObj getElementsByTagName title]
        foreach tobj $title_objs {
            if {[$tobj hasAttribute language]} {
                set obj_l [$tobj getAttribute language]
                if {[string match $language $obj_l]} { return [$tobj text] }
            } else {
                set title_candidate [$tobj text]
            }
        }
        return $title_candidate
    }

# -- menuItems
#
# tdom objects representing the menu items are extracted and returned
# in a list
#

    proc menuItems {menuObj} {
        set items {}
        foreach c [$menuObj childNodes] {
            if {[string match [$c nodeType] ELEMENT_NODE] && \
                [string match [$c nodeName] link]} {
                lappend items $c
            }
        }
        return $items
    }

# -- htmlMenu 
#
# takes a tdom object command from the menu dom and generates the html
# code for the menu. This procedure uses tdom calls in order to obtain an xhtml
# page fragment.
#
# This is the general dom pseudo-structure of the menu 
#
# - <$menu_tag class="$menu_class" id="$menu_id">
#       <$title_tag class="$title_class"> $titolo_txt </$title_tag>
#         <div class="itemcontainer">
#             <span class="navitem"><a href="<hypetext-link-1>" class="$item_class" title="<info-1>"> 
#                link 1 </span>
#             <span class="navitem"><a href="<hypetext-link-2>" class="$item_class" title="<info-2>">
#                link 2 </span>
#       ....
#         </div>
#       </div>
#   </$menu_tag>
#
#
#   Arguments: 
#
#	- menuObj: tdom object representing the menu to be printed
#       - lang: language code
#	- menu_html: 2 element list. 
#		* Element 0: html element tag that will encompass the whole menu (default: div)
#		* Element 1: css class for the element (default: staticmenu)
#	- title_html: 2 element list
#		* Element 0: html element tag enclosing the menu title (def: div)
#		* Element 1: css class for the element (default: menuheader)
#	- it_cont_html: 2 element list
#		* Element 0: html element tag enclosing the menu items (def: div)
#		* Element 1: css class for the element (default: itemcontainer)
#	- item_html: 2 element list
#		* Element 0: html element delimiting an item (def: span)
#		* Element 1: css class for the element (default: navitem)
#
#   Returned value:
#
#	menu in XHTML 
#           

#proc htmlMenu {  menuObj {lang ""}                      \
#                {menu_html {div staticmenu}}            \
#                {title_html {div menuheader}}           \
#                {it_cont_html {div itemcontainer}}      \
#                {item_html {span menuitem}}             \
#                {link_class navitem} } 

    proc htmlMenu { menuObj lang menustruct } {

# let's remap menustruct into local variables

        foreach {v lv} $menustruct { set $v $lv }

# we extract tag and class names from the variable lists passed in
# by 'menustruct'

        set menu_class      [lindex $menu_html 1]
        set menu_tag        [lindex $menu_html 0]
        set title_class     [lindex $title_html 1]
        set title_tag       [lindex $title_html 0]
        set it_cont_tag     [lindex $it_cont_html 0]
        set it_cont_class   [lindex $it_cont_html 1]
        set item_tag        [lindex $item_html 0]
        set item_class      [lindex $item_html 1]

        if {([$menuObj tagName] eq "menu") && [$menuObj hasAttribute id]} { 
            if {$lang == ""} { set lang $::rivetweb::language }

            set menuid [$menuObj getAttribute id]
            set menuattributes  ""
            if {[$menuObj hasAttribute attr]} {
                set menuattributes  [split [$menuObj getAttribute attr] ","]
            } 
            set menudom [dom createDocument $menu_tag]
            set htmlmenu_o  [$menudom documentElement]
            eval $htmlmenu_o setAttribute id $menuid
            if {[string length $menu_class]} { eval $htmlmenu_o setAttribute class $menu_class }

            if {[lsearch $menuattributes "notitle"] < 0} {
                set titolo_txt  [menuTitle $menuObj $lang]
                if {[string length $titolo_txt]} {
                    set  titolo_o [$menudom createElement $title_tag]
                    $titolo_o setAttribute class $title_class
                    $htmlmenu_o appendChild $titolo_o

                    set t [$menudom createTextNode $titolo_txt]
                    $titolo_o appendChild $t
                }
            }

            set item_container_o [$menudom createElement $it_cont_tag]
            $item_container_o setAttribute class $it_cont_class
            $htmlmenu_o appendChild $item_container_o

            foreach item_o [menuItems $menuObj] {
                array unset item_text
                array unset item_a


#               puts "<pre>[escape_sgml_chars [$item_o asXML]]</pre>"
                foreach c [$item_o child all] {
                    set tag_name [$c tagName]
                    switch $tag_name {
                        text {
                            if {[$c hasAttribute language]} {
                                set item_language [$c getAttribute language]
#                               if {[string match [$c getAttribute language] $::rivetweb::language]} {
#                                   set item_text($item_language) [$c text]
#                               }
                                set item_text($item_language) [$c text]
                            } else {
                                set item_text($::rivetweb::default_lang) [$c text]
                            }
                        }
                        default {
                            set item_a($tag_name) [$c text]
                        }
                    }
                }

                if {![info exists item_text($::rivetweb::default_lang)]} {
                    set item_text($::rivetweb::default_lang) [$c text]
                }

#               parray item_a
#               parray item_text

                if {$::rivetweb::language == ""} {
                    set item_a(text)    $item_text($::rivetweb::default_lang)
                } elseif {[info exists item_text($lang)]} {
                    set item_a(text)    $item_text($::rivetweb::language)
                } else {
                    set item_a(text) $item_text($::rivetweb::default_lang)
                }

#               array set item_a [itemSerialize $item_o]
            
                set item_range_o [$menudom createElement $item_tag]
                $item_range_o setAttribute class $link_class
                $item_container_o appendChild $item_range_o

                set link_o [$menudom createElement a]
                $item_range_o appendChild $link_o

                if {[info exists item_a(type)]} {
                    if {[info exists item_a(text)]} {
                        set t [$menudom createTextNode $item_a(text)]
                        $link_o appendChild $t
                    }

                    if {[info exists item_a(info)]} {
                        $link_o setAttribute title $item_a(info)
                    }
#                   puts "<div>type $item_a(type)</div>"
                    switch $item_a(type) {
                        internal {
                            if {[info exists item_a(reference)]} {
                                $link_o setAttribute href [makeUrl $item_a(reference)]
                            }
                            $link_o setAttribute class $item_class
                        }
                        external {
                            if {[info exists item_a(url)]} {
                                $link_o setAttribute href "$item_a(url)"
                            }
                        }
                        local {
                            if {[info exists item_a(reference)]} {
                                $link_o setAttribute href "$item_a(reference)"
                            }
                        }
                    }
                    if {[info exists item_a(target)]} {
                        $link_o setAttribute target $item_a(target)
                    }
                }
            }
            set htmlMenu [$menudom asXML]
            $menudom delete
            return $htmlMenu
        } else {
            return ""
        }
    }

    namespace export menuHtml

# -- field
#
# field is a convenience proc that checks for the existence
# of a variable in an array. The function generates an error
# if the variable doesn't exist that can be caught for handling
#  
# Input: a       - array name
#        field   - name of the variable in the array
#
#

    proc field {a field} {
        upvar $a a
        
        if {[info exists a($field)]} { 
            return -code ok $a($field) 
        } else {
            return -code error
        }
    }

# -- makeUrl
#
# Central method for generating hypetext links pointing to other pages of the site.
#
# References are built accordingly with the mode we are generating a page (either static or dynamic). 
# In case the 'lang' or 'reset' parameters are passed in their values are appended to the local
# path
#
#
# Arguments:
#
#   reference:  a string that works as a key to the page to be generated. A value
#               'key' maps to 'index.rvt?show=<key>....' in dynamic mode or
#               to '/static/<key>.html' in static mode. 
#
# Returned value:
#
#   the URL to the page in relative form.
#

    proc makeUrl {reference} {
#       puts "generate reference for '$reference' (static = $::rivetweb::static_links)"

        if {$::rivetweb::static_links} {
#           apache_log_error err "static_links flag $::rivetweb::static_links"
            if {([string length $reference] == 0) || [string equal $reference index]}  {
                if {$::rivetweb::is_homepage} {
                    return index.html
                } else {
                    return [file join .. index.html]
                }
            } else {
                if {$::rivetweb::is_homepage} {
                    return [file join $::rivetweb::static_path ${reference}.html]
                } else {
                    return ${reference}.html
                }
            }
        } else {

            if {[string length $reference] == 0} {
                set reference $::rivetweb::index
            }

# we use therefore ::request::env(DOCUMENT_NAME) to infer the template name

            if {[info exists ::rivetweb::env(DOCUMENT_NAME)]} {
                set local_ref "$::rivetweb::env(DOCUMENT_NAME)?show=${reference}"
            } else {
                set local_ref "index.rvt?show=${reference}"
            }

# structural variables passover

            if {[var exists lang]}      { set local_ref "${local_ref}&lang=[var get lang]" }
            if {[var exists reset]}     { set local_ref "${local_ref}&reset=[var get reset]" }
            if {[var exists template]}  { set local_ref "${local_ref}&template=[var get template]" }
            return $local_ref
        }
    }

    namespace export makeUrl

# -- buildSimplePage 
#
# Utility function that builds a simple page out of a message 
# 
# Arguments: 
#
#    - mag	    Message text
#    - cssclass     css class the element enclosing the text must have
#    - pagina_id    identification of the page for subsequent retrieving 
#                   from the cache
#
#  Returned value:
#
#   - reference to the tdom object representing the page
#

    proc buildSimplePage {msg cssclass pagina_id} {

        if {![info exists ::rivetweb::pagine($pagina_id)]} {
            set msgdom  [dom createDocument page]
            set xml_o   [$msgdom documentElement]

# Let's add the menus to the dom

            set menu_o  [$msgdom createElement menu]
            $xml_o appendChild $menu_o
            set t   [$msgdom createTextNode "index"]
            $menu_o appendChild $t

# ...and then the page main content

            set content_o [$msgdom createElement content]
            $xml_o appendChild $content_o

            set headline_o [$msgdom createElement headline]
            set hdline_to  [$msgdom createTextNode "Rivetweb anomaly"]
            $headline_o appendChild $hdline_to
            set title_o   [$msgdom createElement title]
            set title_to  [$msgdom createTextNode "Rivetweb anomaly"]
            $title_o    appendChild $title_to
            $headline_o appendChild $hdline_to
            $content_o  appendChild $headline_o
            $content_o  appendChild $title_o

            set htmldiv_o [$msgdom createElement pagetext]
            $content_o appendChild $htmldiv_o
            eval $htmldiv_o setAttribute class $cssclass 

            set t [$msgdom createTextNode $msg]
            $htmldiv_o appendChild $t

        } else {
            set msgdom $::rivetweb::pagine($pagina_id)
        }

        return $msgdom
    }
    namespace export buildSimplePage

# -- buildPageDOM 
#
# does the actual work of building a dom tree of objects from 
# the page xml description 
# 
# Arguments:
#   
#   -xmldata:   xml text from which we are building a tdom 
#               document reference
#   -pageid:    name of a caller's variable that will contain the
#               real pageid. Site pages have an id attribute that
#               identifies them. This variable will contain this
#               attribute's value.
#
# Returned value:
#   
#   - page dom reference
#

    proc buildPageDOM {xmldata pageid} {
        upvar $pageid page_id

        set pagedom [dom parse $xmldata]
        set domroot [$pagedom documentElement root]
        if {[$domroot hasAttribute id]} {
            set page_id [$domroot getAttribute id]
        }

        return $pagedom
    }

# -- buildPage 
#
# gets a keyword to the page that has to be generated. 
# The content of the page will read from the file <keyword>.xml
# 
# arguments: 
#
#   - page_keyword:     keyword to the page to be generated
#   - paginaid:         actual xml id of the loaded page in case some
#                       redirection mechanism gets triggered within 
#                       buildPage (not yet implemented)
#

    proc buildPage {page_keyword {paginaid paginaid} {language ""}} {
        upvar $paginaid page_id
        
        if {$language == ""} { set language $::rivetweb::default_lang }

        set xmlfile [file join $::rivetweb::static_pages ${page_keyword}.xml]
        apache_log_error info "->opening $xmlfile" 
        if {[file exists $xmlfile]} {
            if {[catch {
                set xmlfp    [open $xmlfile r]
                set xmldata  [read $xmlfp]
                set xmldata  [regsub -all {<\?} $xmldata {\&lt;?}]
                set xmldata  [regsub -all {\?>} $xmldata {?\&gt;}]
#               puts stderr $xmldata
                close $xmlfp
            } fileioerr]} {
                set page_id errore_interno
                set notfound_msg "It was impossible to open the requested page ($fileioerr)"
                apache_log_error err "[pid] $notfound_msg"
                return [::rivetweb::buildSimplePage $notfound_msg message internal_error]
            } else {
                return [buildPageDOM $xmldata page_id]
            }
        } else {
            apache_log_error err "$xmlfile not found"
            set page_id not_existing
            set notexists_msg "The requested page does not exist"
            return [::rivetweb::buildSimplePage $notexists_msg message $page_id]
        }
    }
    namespace export buildPage


# -- makeCssPath 
#
#   creates rivetweb path to a CSS file
#
#   Arguments:
#
#	css_file:   CSS file name
#	style_dir:  template/CSS key
#
#   style_dir is supposed to be a 'key' in a database of templates, it
# represents the directory name where the CSS is located within the 
# ::rivetweb::running_css_path directory containing the css files for 
# the supported templates.
#


    proc makeCssPath {css_file {style_dir ""}} {
        return [file join $::rivetweb::running_css_path $style_dir $css_file] 
    }
    namespace export makeCssPath

# -- makePictsPath
#
#

    proc makePictsPath {picts_file {style_dir ""}} {

        apache_log_error debug "style $style_dir $::rivetweb::running_picts_path [pwd]"

# search list for a picts file. 
#    - We first try in the template's specific dir
#    - then we try the picts root directory 
#    - last we attempt in the rwbase dir


# we have to fake static links (relative to the ::rivetweb::static_path variable)
# but still be aware we are running from /index.rvt

        set fn [file join $::rivetweb::site_base $::rivetweb::picts_path $style_dir $picts_file]
        apache_log_error debug "1 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::running_picts_path $style_dir $picts_file]
        } 

        set fn [file join $::rivetweb::site_base $::rivetweb::picts_path $picts_file]
        apache_log_error debug "2 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::running_picts_path $picts_file]
        } 

        set fn [file join $::rivetweb::site_base $::rivetweb::picts_path $::rivetweb::default_template $picts_file]
        apache_log_error debug "3 pict file: >$fn<"
        return [file join $::rivetweb::running_picts_path $::rivetweb::default_template $picts_file]
    }
    namespace export makePictsPath


    proc buildTemplateName {template_name {template_dir ""}} {
        return [file join $::rivetweb::base_templates $template_dir $template_name]

    }
    namespace export buildTemplateName


# -- walkTree
#
# walks the menu tree and builds a new tree where only 'node' menu
# are present starting from a leaf group of menus upwards to the root
#
# Arguments: 
#
#   radice: dom element root of the tree
#   node: 
#

    proc walkTree { radice node {eltype "node"} {menu_list {}} } {

    #    puts "examining node '$node' (type '$eltype') menu_list: '$menu_list'"
     
        set menublock [$radice selectNodes {//sitemenus[@id=$node]}]
        if {$menublock == ""} { return $menu_list }
        if {[$menublock hasAttribute parent]} {

            set parent_block [$menublock getAttribute parent]

        } elseif {[$menublock hasAttribute id]} {

            if {[$menublock getAttribute id] == "root"} { set parent_block "" }

        } else {

            return  -code	    error                \
                    -errorcode  inconsistent_tree    \
                    -errorinfo  "Struttura menu inconsistente (manca 'radice')" $menu_list
        }

        set ml {}
        foreach cn [$menublock childNodes] {
            if {[$cn nodeName] == "menu"} {
                if {[$cn hasAttribute type]} {
                    set tipo [$cn getAttribute type]
                } else {
                    set tipo leaf
                }

                if {($tipo == "node") || ($eltype == $tipo)} {
                    lappend ml $cn
                }
            }
        }

        eval lappend menu_list $ml

        if {$parent_block == ""} {
            return $menu_list
        } else {
            return [walkTree $radice $parent_block node $menu_list]
        }

    }
    namespace export walkTree

# -- thisClass 
#
# returns a class="classname" attribute when we are generating
# a certain page. Useful in selectors both in forms or templates to highlight
# an element.

    proc thisClass {this_page page_reference class_selected {class_unselected ""}} {
        if {[string match $this_page $page_reference]} { 
            return " class=\"$class_selected\""
        } else {
            return ""
        }
    }

    namespace export thisClass

# -- itemSerialize 
#
# takes a tdom element object and makes a list of the child elements and their text nodes.
# Useful when a tdom element's children are leaves of the tree
#

    proc itemSerialize {itemObj} {
        set lista {}
        foreach c [$itemObj child all] {
            lappend lista [$c tagName] [$c text]
        }
        return $lista
    }

# more procedures for page generation here

    source [file join $rivetweb::rivet_scripts makepagehtml.tcl]
}


set ::rivetweb::pagine($::rivetweb::index) [::rivetweb::buildPage index ::rivetweb::page_content]

# costruiamo il database in memoria dei template disponibili
apache_log_error notice "pwd: [pwd]"

set templates_dir_list [glob -directory $::rivetweb::base_templates *]

foreach template $templates_dir_list {

    if {[file isdirectory $template]} {

        if {[catch {

# we prepare a clean namespace where variables will be stored

            catch {namespace delete ::rwtemplate}
            namespace eval ::rwtemplate {

                source [file join $template rwtemplate.tcl]
                if {![info exists rwtemplate] || ![info exists rwcss]} {
                    apache_log_error err "Descrittore template $template incompleto"
                    continue
                }

                set template_key [file tail $template]

                dict set ::rivetweb::templates_db $template_key template $rwtemplate 
                dict set ::rivetweb::templates_db $template_key css $rwcss

# along with template name and css file name, we build also a database of definitions
# for the menu definitions variables.

                if {[info exists ::rwtemplate::menu_html]} {
                    dict set ::rivetweb::templates_db $template_key menu_html $::rwtemplate::menu_html
                }
                if {[info exists ::rwtemplate::title_html]} {
                    dict set ::rivetweb::templates_db $template_key title_html $::rwtemplate::title_html
                }
                if {[info exists ::rwtemplate::it_cont_html]} {
                    dict set ::rivetweb::templates_db $template_key it_cont_html $::rwtemplate::it_cont_html
                }
                if {[info exists ::rwtemplate::item_html]} {
                    dict set ::rivetweb::templates_db $template_key item_html $::rwtemplate::item_html
                }
                if {[info exists ::rwtemplate::link_class]} {
                    dict set ::rivetweb::templates_db $template_key link_class $::rwtemplate::link_class
                }
            }

        } e]} {
            apache_log_error err "Error reading rwtemplate.tcl from $template ($e)"
        }
    }
}

foreach k [dict keys $::rivetweb::templates_db] {
    apache_log_error debug "$k: [dict get $::rivetweb::templates_db $k]"
}

# now we build the hooks database

namespace eval ::rivetweb {

    set hooks_dir_fq [file join $rivet_scripts $hooks_dir *.tcl]

    set nhooks 0

    if {[catch {set hooks_list [glob $hooks_dir_fq]} e]} {

        apache_log_error notice "no hooks read from $hooks_dir_fq"

    } else {

        foreach hook_file [glob $hooks_dir_fq] {

            array unset hook_descriptor
            source $hook_file

    # we assume everything has been stored in hook_descriptor

            if {[info exists hook_descriptor(tag)]} {
                dict set hooks  $hook_descriptor(stage)                          \
                                $hook_descriptor(tag)                            \
                                [dict create function $hook_descriptor(function) \
                                             descrip  $hook_descriptor(descrip)] 
                incr nhooks
            }
        }

        apache_log_error notice "$nhooks hooks processed"
        apache_log_error debug   $hooks
    }
}

# vi:shiftwidth=4:softtabstop=4:
