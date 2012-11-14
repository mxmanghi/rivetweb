#
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

        constructor {pagekey} {
            set key $pagekey
            set metadata [dict create]
        }

        public method key {} { return $key }
        public method add_metadata {field value} 
        public method set_metadata {mdlist}
        public method put_metadata {dictionary} 
        public method languages { } 
        public method metadata {{key ""}}
        public method dispose { }
        public method postproc_hooks { hooks_d hooks_class {language ""}}
        public method metadata_hooks { pageobj hooks_d } 
        public method print_content {language}
        public method destroy {}
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

        dict set metadata [eval dict create $mdlist]

    }

# -- put_metadata 
# 
# metadata dictionary is replaced by the <dictionary> value
# 

    ::itcl::body RWPage::put_metadata {dictionary} {
 
        set metadata $dictionary       
    }

# -- languages
#
# returns a list of available languages for <pageobj>. The list is assumed
# to always have length > 0 as the default language has to be present
#

    proc languages { } {
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
        if {$key == "" } {
            return $metadata
        } else {

            if {[dict exists $metadata $key]} {
                return [dict get $metadata $key]
            } else {
                return ""
            }

        }
    }

# -- dispose
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

    ::itcl::body RWPage::postproc_hooks { hooks_d hooks_class {language ""}} { }

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
                
                ::rivetweb::$processor $pageobj 

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

    namespace export create
    namespace ensemble create
}

package provide rwpage 0.1

