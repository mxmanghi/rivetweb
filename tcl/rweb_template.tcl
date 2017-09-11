# -- rweb_template.tcl
#
#
#
#

package require Itcl

namespace eval ::rivetweb {

    variable menuclass              RWMenu

    ::itcl::class RWTemplate {
        public common templates_db     [dict create]

        # defaults taken from rwbase/rwtemplate.tcl

        private variable rwtemplate	    xhtml10.rvt
        private variable rwcss	        xhtml10.css
        private variable menu_html      {li ""}
        private variable title_html     {h2 ""}
        private variable it_cont_html   {ul ""}
        private variable item_html      {li ""}
        private variable link_class     navitem
        private variable pictures       images
        private variable menuclass      RWMenu

        private variable template_key

        constructor {key} {
            set template_key $key
        }

        public method init {descriptor} 
        public method getprop {prop}
        public method serialize {}
        public method register_formatter {formatter}
        public method formatters_ns {}

        public proc load_templates {templates_root}
        public proc template {template_key {prop ""}}
    }

    ::itcl::body RWTemplate::getprop {prop} {

        if {$prop == "css"} { return $rwcss }
        if {$prop == "template"} { return $rwtemplate }

        if {[info exists $prop]} {
            return [set $prop]
        } else {
            return ""
        }
    }

    ::itcl::body RWTemplate::serialize {} {
        return [dict create css             $rwcss          \
                            template        $rwtemplate     \
                            menu_html       $menu_html      \
                            title_html      $title_html     \
                            it_cont_html    $it_cont_html   \
                            item_html       $item_html      \
                            link_class      $link_class     \
                            pictures        $pictures       \
                            menuclass       $menuclass]
    }

    ::itcl::body RWTemplate::init {descriptor_file} {
        source $descriptor_file
    }

    ::itcl::body RWTemplate::register_formatter {formatter} {
        namespace eval [$this formatters_ns] $formatter 
    }

    ::itcl::body RWTemplate::formatters_ns {} { return "[namespace current]::${template_key}" }

    ::itcl::body RWTemplate::load_templates {templates_dir} {

        foreach template [glob -directory $templates_dir *] {
            if {[file isdirectory $template]} {

                set template_key [file tail $template]

                #puts "searching for [file join $template rwtemplate.tcl]"

                set base_descriptor [file join $template rwtemplate.tcl]
                if {[file exists $base_descriptor]} {
                    set template_o [::rivetweb::RWTemplate [namespace current]::${template_key} $template_key]
                    $template_o init $base_descriptor

                    dict set templates_db $template_key $template_o
                }

                set formatters [file join $template formatters.tcl]
                if {[file exists $formatters]} {
                    #puts "reading formatters $formatters"
                    set fp [open $formatters r]
                    set formatters_code [read $fp]
                    close $fp

                    $template_o register_formatter $formatters_code
                }
            }
        }

    }

    ::itcl::body RWTemplate::template {template_key {prop ""}} {
        if {![dict exists $templates_db $template_key]} { return "" }
        set template_o [dict get $templates_db $template_key]
        if {$prop == ""} {
            return $template_o
        } else {
            return [$template_o getprop $prop]
        }
    }
}

package provide RWTemplate 1.0
