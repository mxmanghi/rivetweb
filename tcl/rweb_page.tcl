# -- rweb_page.tcl
#
# base class for every HTML page 
#

package require rwcontent

namespace eval ::rwpage {

    ::itcl::class RWPage {
        inherit RWContent

        private variable metadata
        private variable title
        private variable headline

        constructor {pagekey} {RWContent::constructor $pagekey} {
            set metadata    [dict create]
            set title       [dict create]
            set headline    [dict create]
        }

        public method set_key {k} { set key $k }
        public method key {} { return $key }
        public method add_metadata {field value} 
        public method set_metadata {mdlist}
        public method put_metadata {dictionary} 
        public method clear_metadata { } { set metadata [dict create] }
        public method languages { } { return $::rivetweb::default_lang } 
        public method metadata {{key ""}}
        public method postproc_hooks { ds hooks_d hooks_class {language ""}} {}
        public method metadata_hooks { hooks_d } 
        public method to_string {} { return [dict create metadata $metadata hits $hits key $key] }
        public method set_title {language title_t} { $this title $language $title_t } ; #DEPRECATED 
        public method title {language {txt ""}}
        public method headline {language {hdl ""}}

        #####

        # interface designed for the Scripted datasource. Can be moved into
        # application specific code

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

        ##### 

        public method binary_content { } { return false }
        public method content_field {language field {default_val ""}} {return ""}
        public method prepare {language argqs} { return [RWContent::prepare $language $argqs] }
        protected method postprocessing {urlhandler}
    }

# -- postprocessing
#
# method to store in a page instance the metadata associated
# with the keyword 'field' and whose value is 'value'
#

    ::itcl::body RWPage::postprocessing {urlhandler} {
        RWContent::postprocessing $urlhandler

        if {[catch {

           $this postproc_hooks   $urlhandler               \
                                  $::rivetweb::hooks        \
                                  xmlpostproc               \
                                  $::rivetweb::language

           $this metadata_hooks $::rivetweb::hooks

        } e einfo]} {

            ::rivet::apache_log_error err "Error processing data for page ($e)"
            ::rivet::apache_log_error err $einfo

            set ::rivetweb::current_page [::RWDummy fetch_page postproc_hook_error rkey]

        }

    }

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

# -- title
#
# A method for getting the page title goes in the base RWPage class
# because <title>...</title> is an element that goes in the <head>...</head>
# section of a page and it's part of the standard HTML ever since
#

    ::itcl::body RWPage::title {language {titletxt ""}} { 
        if {$titletxt != ""} {
            dict set title $language $titletxt
            return $titletxt
        } elseif {[dict exists $title $language]} {
            return [dict get $title $language]
        } else {
            return ""
        }
    }

# -- headline
#
# I add a 'headline' method for sake of simplicity, but there is
# no compelling reason to make this a base class method. 

    ::itcl::body RWPage::headline {language {hdl ""}} { 
        if {$hdl != ""} {
            dict set headline $language $hdl      
        } elseif {[dict exists $headline $language]} {
            return [dict get $headline $language]
        } else {
            return [$this title $language]
        }
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

# -- put_metadata 
# 
# metadata dictionary is replaced by the <dictionary> value
# 

    ::itcl::body RWPage::put_metadata {dictionary} {
        set metadata $dictionary
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

    proc create {key {class RWStatic}} {
        return [$class ::#auto $key]
    }

    namespace export create
    namespace ensemble create
}

package provide rwpage 2.0

