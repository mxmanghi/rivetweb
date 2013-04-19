#
# -- rweb_menumodel.tcl
#
# Model for menu data.
#
#

package require Itcl
package require rwconf
package require rwlogger
package require rwlink

namespace eval ::rwmenu {

    ::itcl::class RWMenu {
        private variable    menuid
        private variable    parent
        private variable    visibility
        private variable    title
        private variable    links
        private variable    attributes
        private variable    index
        private variable    cssclass

        constructor {id {parent_menu none} {menu_visibility normal} {css_class ""}} {
            set menuid      $id
            set parent      $parent_menu
            set visibility  $menu_visibility
            set title       [dict create]
            set links       {}
            set attributes  {}
            set index       end
            set cssclass    $css_class
        }

        private method get_title {language}
        private method set_title {testo {language ""}}

        public method destroy {} { ::itcl::delete object $this }
        public method title {{language ""} {testo ""}}
        public method parent {}
        public method index {} 
        public method attributes {} 
        public method peek {param} 
        public method assign {param pvalue args}
        public method add_link {linkmodel {pos ""}}
        public method links {}
        public method id {}
    }

    ::itcl::body RWMenu::get_title {language} {
        if {[string length $language] == 0} {
            set language $::rivetweb::default_lang
        }
        #puts "<pre><b>$::rivetweb::default_lang -%gt; $title</b></pre>"
        if {[dict exists $title $language]} {
            return [dict get $title $language]
        } else {
            return [dict get $title $::rivetweb::default_lang]
        }
    }

    ::itcl::body RWMenu::set_title {testo {language ""}} {
        if {[string length $language] == 0} {
            set language $::rivetweb::default_lang
        }

        dict set $title $language $testo
        if {![dict exists $title $::rivetweb::default_lang]} {
            dict set title $::rivetweb::default_lang $testo
        }

    }

# -- title <menuobj> ?language?. 
#
# Accessor to the title to be printed in the menu. If
# no ?language? parameter is passed then the title
# for the default language is returned

    ::itcl::body RWMenu::title {{language ""} {testo ""}} {

        if {$testo == ""} { 
            return [$this get_title $language] 
        } else {
            $this set_title $testo $language
        }

    }

# -- parent, index, attributes
# 
# specific accessors for structural information of a menuobj. 
#
#    - parent: id of the parent. If a menuobj has no parent 
#      it will be put as root of menu hirarchy
#    - index: not used
#    - attributes: not handled. It's supposed to return a 
#      list of HTML attribute-value pairs.
#

    ::itcl::body RWMenu::parent {} { return $parent }
    ::itcl::body RWMenu::index {} { return $index }
    ::itcl::body RWMenu::attributes {} { return $attributes }

# -- peek: 
#
# generic accessor for a custom parameter
# associated to the menuobj. if the attribute 'param'
# is not existing in the object an error is raised
#

    ::itcl::body RWMenu::peek {param} {
        return [set $param]
    }

# -- assign: multipurpose method to assign various parameters
#

    ::itcl::body RWMenu::assign {parameter pvalue args} {

        switch $parameter {

            attributes {
                set attributes $pvalue
            }
            parent {
                set parent $pvalue
            }
            cssclass {
                set cssclass $pvalue
            }
            title {
                lassign $args language

# the 'title' parameter expects the argument to be a dictionary
                set_title $pvalue $language
            }
            index {
                set index $pvalue             

                if {![string is integer $index] && ($index != "end")} {
                    return -code error \
                        "Wrong index parameter, must be either 'end' or integer"
                } elseif {[string is integer $index] && ($index < 0)} {
                    set index "end-${index}"
                }
            }
            default {
                $::rivetweb::logger log err "unmanaged parameter $parameter"
            }
        }

    }

# --add_link
#
# Adds a link object to the menu
#

    ::itcl::body RWMenu::add_link {linkmodel {position ""}} {
        lappend links $linkmodel
    }

# -- links
#
#
    ::itcl::body RWMenu::links {} {
        return $links 
    }

# -- id 
#
#
    ::itcl::body RWMenu::id {} {
        return $menuid
    }


# -- create <id> ?<parent> none? ?<visibility> normal?
#
# 
    proc create_menu { id {parent none} {visibility normal} } {
        return [RWMenu ::#auto $id $parent $visibility]
    }

    namespace export create_menu
    namespace ensemble create
}

package provide rwmenu 1.0
