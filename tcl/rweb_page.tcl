# -- rweb_page.tcl
#
# base class for every page model providing for base
# methods and common interface to every other page model
#

package require Itcl

namespace eval ::rwpage {

    ::itcl::class RWPage {
        private variable metadata
        private variable key
        private variable stored_vars
        private variable hits

        constructor {pagekey} {
            set key         $pagekey
            set metadata    [dict create]
            set stored_vars [dict create]
            set hits        0
        }

        public method key {} { return $key }
        public method add_metadata {field value} 
        public method set_metadata {mdlist}
        public method put_metadata {dictionary} 
        public method prepare {language argsqs}
        public method url_args {} { return $stored_vars }
        public method languages { } 
        public method metadata {{key ""}}
        public method postproc_hooks { ds hooks_d hooks_class {language ""}}
        public method metadata_hooks { hooks_d } 
        public method print_content { language }
        public method destroy {}
        public method to_string {}
        public method set_title {language title_t}
        public method title {language {txt ""}}
        public method headline {language {hdl ""}}
        public method store {var value} { dict set stored_vars $var $value }
        public method lappend {var value} { dict lappend stored_vars $var $value }
        public method erase {var} {
            if {[dict exists $stored_vars $var]} {
                dict unset stored_vars $var
            }
        }
        public method recall {var {defvar value}} {
            upvar 1 $defvar retvalue
            # puts "--> $stored_vars<br/>"
            if {[dict exists $stored_vars $var]} {
                set retvalue [dict get $stored_vars $var]
                return true
            } else {
                set retvalue ""
                return false
            }
        }
        public method clear_metadata { } { set metadata [dict create] }
        public method binary_content { } { return false }
        public method content_field {language field {default_val ""}} {return ""}
        public method resource_exists {resource_key} { return false }
        public method get_resource_repr {resource_key} {return ""}
    }


# -- add_metadata 
#
# method to store in a page instance the metadata associated
# with the keyword 'field' and whose value is 'value'
#
#
    ::itcl::body RWPage::add_metadata {field value} {

        dict set metadata $field $value

    }

# -- set_metadata
#
# the list 'mdlist' is treated as a even length list to be interpreted
# as a sequence of keyword-value pairs. The keywords are assembled and 
# become the new metadata of the instance 'pageobj' erasing metadata 
# that could have been defined beforehand  

    ::itcl::body RWPage::set_metadata {mdlist} {

        set metadata [dict merge $metadata $mdlist]

    }

# -- set_title
#
# utility method to set the page title
#
    ::itcl::body RWPage::set_title {language title_t} {
        dict set metadata title $language $title_t
    }

# -- title
#
# A method for getting the page title goes in the base RWPage class
# because <title>...</title> is an element that goes in the <head>...</head>
# section of a page and it's part of the standard HTML ever since
#

    ::itcl::body RWPage::title {language {titletxt ""}} { 
        if {$titletxt != ""} {
            $this set_title $language $titletxt
        }

        if {[dict exists $metadata title $language]} {
            return [dict get $metadata title $language]
        } else {
            return ""
        }
    }

# -- put_metadata 
# 
# metadata dictionary is replaced by the <dictionary> value
# 

    ::itcl::body RWPage::put_metadata {dictionary} {
        set metadata $dictionary
    }

# -- prepare
#
#
# 
    ::itcl::body RWPage::prepare {language argsqs} { 
        set stored_vars $argsqs 
        incr hits

        return $this
    }

# -- languages
#
# returns a list of available languages for <pageobj>. The list is assumed
# to always have length > 0 as the default language has to be present
#

    ::itcl::body RWPage::languages { } {
        return $::rivetweb::default_lang
    }


# -- metadata
#
# when called with no argument 'metadata' returns the whole metadata section,
# when called with a 'key' argument the call returns the metadata value
# corresponding to the 'key'. If the 'key' metadata doesn't exist in the page
# object an empty string is returned.
# 

    ::itcl::body RWPage::metadata {{key ""}} {

        if {$key == ""} {
            return $metadata
        } else {

            if {[dict exists $metadata $key]} {
                return [dict get $metadata $key]
            } else {
                return ""
            }

        }

    }

# -- destroy
#
# releases objects which may hold data stored in the pool (e.g.
# tdom objects). Abstract method for this class

    ::itcl::body RWPage::destroy { } {
        ::itcl::delete object $this
    }

# -- postproc_hooks
#
# general purpose method to call specific code for handling 
# elements of a page. It should be general enough to hide 
# the page internal implementation.
#
# When a transformation actually takes place a hook should return a dictionary 
# storing a new tag name (key: tagname), a list of transformed attributes 
# (key: attributes) and the new text within the element, if any (key: text).
# Otherwise the processor will return an empty string. 
#
#       <processor_name> { element_text attributes }
#

    ::itcl::body RWPage::postproc_hooks {ds hooks_d hooks_class {language ""}} { }

# -- metadata_hooks
#
# metadata hooks are processed in a similar wayto xml postproc hooks, 
# but they apply in slightly different manner
#

    ::itcl::body RWPage::metadata_hooks { hooks_d } {

        if {[dict exists $hooks_d metadata]} {
            set ppp [dict get $hooks_d metadata]
            foreach hk [dict keys $ppp] {
                $::rivetweb::logger log info "processing hook: [dict get $ppp $hk descrip]"
                set processor [dict get $ppp $hk function]
                
                ::rivetweb::$processor $this
            }
        }
    }

# -- print_content
# 
# 
    ::itcl::body RWPage::print_content {language} { }

    proc create {key {class RWStatic}} {
        return [$class ::#auto $key]
    }

# -- to_string 
#

    ::itcl::body RWPage::to_string {} { return [dict create metadata $metadata hits $hits key $key] }

# -- headline
#
# I add a 'headline' method for sake of simplicity, but there is
# no compelling reason to make this a base class method. 

    ::itcl::body RWPage::headline {language {hdl ""}} { 
        if {$hdl != ""} {
            dict set metadata headline $language $hdl      
        } elseif {[dict exists $metadata headline $language]} {
            return [dict get $metadata headline $language]
        } else {
            return [$this title $language]
        }
    }

    namespace export create
    namespace ensemble create
}

package provide rwpage 0.1

