# -- rweb_template.tcl
#
#
#
#

package require Itcl

namespace eval ::rivetweb {

    variable menuclass                  RWMenu

    ::itcl::class RWTemplate {

        # layout database

        private common LAYOUT

        public common templates_db     [dict create]

        # defaults taken from rwbase/rwtemplate.tcl

        private variable rwtemplate	    xhtml10.rvt
        private variable rwcss          xhtml10.css
        private variable menu_html      {li ""}
        private variable title_html     {h2 ""}
        private variable it_cont_html   {ul ""}
        private variable item_html      {li ""}
        private variable link_class     navitem
        private variable pictures       images
        private variable menuclass      RWMenu
        private variable dir            rwbase
        private variable auxiliary      [dict create]
        private variable template2      ""
        private variable template_key

        constructor {key} {
            set template_key $key
            set dir          $key
        }

        public method init {descriptor} 
        public method getprop {prop}
        public method serialize {}
        public method register_formatter {formatter}
        public method formatters_ns {}
        public method setprop {prop value}
        public method build {args}
        public method layout {page menu_d}

        public proc read_template_data {dir}
        public proc read_formatters {dir template_o}
        public proc make_template_object {template_key}
        public proc load_templates {templates_root args}
        public proc register_template {templay_key template_o}
        public proc template {template_key {prop ""}}
        public proc select_component {position} 
    }

    ::itcl::body RWTemplate::getprop {prop} {

        if {$prop == "css"} { return $rwcss }
        if {$prop == "template"} { return $rwtemplate }

        if {[info exists $prop]} {
            return [set $prop]
        } elseif {[dict exists $auxiliary $prop]} {
            return [dict get $auxiliary $prop]
        } else {
            return ""
        }

    }

    ::itcl::body RWTemplate::setprop {prop value} {
        if {$prop == "css"} { 
            set prop "rwcss" 
        } elseif {$prop == "template"} {
            set prop "rwtemplate"
        }

        if {[info exists $prop]} {
            set $prop $value
        } else {
            dict set auxiliary $prop $value
        }

    }

    ::itcl::body RWTemplate::build {args} {
        foreach {prop propvalue} $args { 
            $this setprop $prop $propvalue 
        }
    }

    # -- serialize
    #
    # serialization method that returns a list of the basic variables
    # that control the menu HTML generation
    #

    ::itcl::body RWTemplate::serialize {} {
        return [dict create css             $rwcss          \
                            template        $rwtemplate     \
                            menu_html       $menu_html      \
                            title_html      $title_html     \
                            it_cont_html    $it_cont_html   \
                            item_html       $item_html      \
                            link_class      $link_class     \
                            pictures        $pictures       \
                            dir             $dir            \
                            menuclass       $menuclass      \
                            auxiliary       $auxiliary]
    }

    ::itcl::body RWTemplate::init {descriptor_file} {
        source $descriptor_file
    }

    ::itcl::body RWTemplate::register_formatter {formatter} {
        namespace eval [$this formatters_ns] $formatter 
    }

    ::itcl::body RWTemplate::formatters_ns {} { return "[namespace current]::${dir}" }

    # -- make_template_object
    #
    #

    ::itcl::body RWTemplate::make_template_object {template_key} {
        return [::rivetweb::RWTemplate [namespace current]::${template_key} $template_key]
    }

    # -- read_template_data
    #
    # template object construction procedure. We don't just create
    # an instance of RWTemplate, we fill it's variables with
    # the definitions shipped rwtemplate.tcl and we assign
    # the 'dir' property, fundamental for retriving the
    # formatters.tcl file and more template specific resources

    ::itcl::body RWTemplate::read_template_data {dir} {
        set template_key [file tail $dir]

        set template_o [RWTemplate::make_template_object $template_key]
        $template_o setprop dir $template_key
    
        set base_descriptor [file join $dir rwtemplate.tcl]
        if {[file exists $base_descriptor]} {
            $template_o init $base_descriptor
        }

        return $template_o
    }

    # -- read_formatters
    #
    # legge un file contenente le procedure di formattazione
    # di parti di un template e quindi ne registra il contenuto
    # con una chiamata a register_formatter che tiene
    # un database di formatters

    ::itcl::body RWTemplate::read_formatters {dir template_o} {
        $::rivetweb::logger log info "read_formatters [pwd] $dir $template_o"
        set formatters [file join $dir formatters.tcl]
        if {[file exists $formatters]} {
            $::rivetweb::logger log debug "reading formatters $formatters"
            set fp [open $formatters r]
            set formatters_code [read $fp]
            close $fp

            $template_o register_formatter $formatters_code
        } else {
            $::rivetweb::logger log debug "unable to read formatters definitions $formatters"
        }

    }

    ::itcl::body RWTemplate::register_template {template_key template_o} {
        dict set templates_db $template_key $template_o 
    }

    # -- load_templates
    #
    # the whole templates hierarchy is read and a templates
    # database (templates_db) built out of it

    ::itcl::body RWTemplate::load_templates {templates_dir args} {

        foreach template [glob -directory $templates_dir *] {
            if {[file isdirectory $template]} {

                set template_o [RWTemplate::read_template_data $template]
                RWTemplate::read_formatters $template $template_o
                dict set templates_db [file tail $template] $template_o

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

    # -- layout
    #
    # takes the current page object and the menu database
    # and reorganizes the menus (or menu groups) in a dictionary
    # of positions -> menu groups. This clearly depends on the 
    # template page layout
    #
    # For compatibility the basic implementation returns the
    # menu db represented by a dictionary of keys -> menu groups

    ::itcl::body RWTemplate::layout {page menu_d} {
        puts "calling layout $page $menu_d"
        return $menu_d
    }

    ::itcl::body RWTemplate::select_component {position} { 
        if {[dict exists $LAYOUT $position]} { 
            return [dict get $LAYOUT $position] 
        }
    }

}

package provide RWTemplate 1.0
