#
# -- rivet_before.tcl
# 
# This is where at every request most of the work is done to prepare a page. 
# rivet_before sets some Rivetweb status variables depending on the value
# of some typically urlencoded parameters
#
#

# let's assign the controlling variables with the corresponding parameters 
# definitions.
#
# static   -> enabling generation of 'static' (i.e. .html) pages
# homepage -> the home is treated in a slightly different way, so we have
#             to signal it with this flag
# 

set ::rivetweb::static_links [var exists static]
set ::rivetweb::is_homepage  [var exists homepage]
    
# when Rivetweb is pretending to be a static site, pages fake their location 
# to be in the a subdirectory of the site root (default: 'static'), so 
# 'running_picts_path' and running_css_path have to be set accordingly

set ::rivetweb::running_picts_path  $::rivetweb::picts_path
set ::rivetweb::running_css_path    $::rivetweb::css_path
if {$::rivetweb::static_links && !$::rivetweb::is_homepage} {

    set ::rivetweb::running_picts_path  [file join $::rivetweb::site_base $::rivetweb::picts_path]
    set ::rivetweb::running_css_path    [file join $::rivetweb::site_base $::rivetweb::css_path]

}

# let's determine which template we are using. We set a couple of default
# values for them

set running_template base.rvt
set running_css      base.css 

if {[var exists template]} {

    set template_key [var get template]
    catch {
        set running_template  [dict get $::rivetweb::templates_db $template_key template]
        set running_css       [dict get $::rivetweb::templates_db $template_key css]
    }

} elseif {[string compare $::rivetweb::default_template ""] != 0} {

    set template_key $::rivetweb::default_template
    if {[catch {
        set running_template  [dict get $::rivetweb::templates_db $template_key template]
        set running_css       [dict get $::rivetweb::templates_db $template_key css]
    } e]} { puts "errore: $e" }

} else {
    set template_key rwbase
}

$::rivetweb::logger log info "selected template: $running_template (css: $running_css)"
set ::rivetweb::running_template  [template_path $running_template $template_key]
set ::rivetweb::running_css       [makeCssPath $running_css $template_key]
set ::rivetweb::template_key      $template_key

# setting this parameter redirs to the 'static' form of the website.

if {[var exists staticroot]} {
    header redir index.html
}

# we determine the language for this request (keep in mind we are running
# within the ::rivetweb namespace.

if {[var exists lang]} {
    set language [var get lang]
} else {
    set language $::rivetweb::default_lang
}

#
# the central point is exactly here: we determine which page we have to display
#

set argqs [dict create {*}[var_qs all]] 

foreach ds $::rivetweb::datasources {

    set ::rivetweb::datasource $ds
    $ds willHandle $argqs page_key 

}

if {$page_key ne "index"} {
    $::rivetweb::logger log info "processing request for '$page_key'"

# if we are using cached content and requested page is cached we simply
# store in ::rivetweb::page_content

    set ::rivetweb::page_content $page_key
    set ::rivetweb::current_pmodel [$::rivetweb::rwebdb fetch $page_key]

#   if {[$::rivetweb::rwebdb is_stale $page_key]} { 
#       $::rivetweb::logger log info "page $page_key stale: fetching from ds"
#       set ::rivetweb::current_pmodel [$::rivetweb::rwebdb fetch $page_key]
#   }

    $::rivetweb::logger log info "page_content: $::rivetweb::page_content"

} else {

# Rivetweb assumes the default page is defined in the ::rivetweb::index variable

    set ::rivetweb::page_content    $::rivetweb::index
    set ::rivetweb::current_pmodel [$::rivetweb::rwebdb fetch $::rivetweb::index]
}

# vi:shiftwidth=4:softtabstop=4:
