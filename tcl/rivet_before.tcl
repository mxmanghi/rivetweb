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
# static -> enabling generation of 'static' (i.e. .html) pages
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

    set ::rivetweb::running_picts_path  [file join .. $::rivetweb::picts_path]
    set ::rivetweb::running_css_path    [file join .. $::rivetweb::css_path]

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
    catch {
        set running_template  [dict get $::rivetweb::templates_db $template_key template]
        set running_css       [dict get $::rivetweb::templates_db $template_key css]
    }

} else {
    set template_key rwbase
}

$::rivetweb::logger log info "template: $running_template (css: $running_css)"
set ::rivetweb::running_template  [buildTemplateName $running_template $template_key]
set ::rivetweb::running_css       [makeCssPath $running_css $template_key]
set ::rivetweb::template_key      $template_key

# setting this parameter redirs to the 'static' form of the website.

if {[var exists staticroot]} {
    header redir index.html
}

# puts "<pre><b>static_links: $::rivetweb::static_links</b></pre>"
# we rely on the 'sitemap' directory mtime to see if some of its files
# have changed and a new tree of links has to be recreated

#if {[$::rivetweb::menusource has_updates]} {
#
#    $::rivetweb::logger log notice "(re-)loading sitemap"
#    $::rivetweb::sitemap recreate
#
#    $::rivetweb::menusource loadsitemap $::rivetweb::sitemap
#}

# we determine the language for this request (keep in mind we are running
# within the ::rivetweb namespace.

if {[var exists lang]} {
    set language [var get lang]
} else {
    set language $::rivetweb::default_lang
}

# Experimental: with early versions of Rivetweb if variable 'reset' 
# was set then the in memory database was reset. To be tested in
# this version

if {[var exists reset]} {

    set ::rivetweb::page_content	$::rivetweb::index

### set pagine($::rivetweb::index)	[::rivetweb::buildPage index]

    $::rivetweb::rwebdb erase
    $::rivetweb::rwebdb fetch $::rivetweb::index 

### array unset pagine
} 

#
# the central point is exactly here: we determine which page we have to display
#

if {[var exists show]} {
    set pagina [var get show]
    $::rivetweb::logger log info "'$pagina' requested"

# if we are using cached content and requested page is cached we simply
# store in ::rivetweb::page_content

    set ::rivetweb::page_content $pagina
    if {[$::rivetweb::rwebdb check $pagina]} { 
        $::rivetweb::rwebdb dispose $pagina 
    }

    set ::rivetweb::current_pmodel [$::rivetweb::rwebdb fetch $pagina]

    $::rivetweb::logger log info "page_content: $::rivetweb::page_content"

} else {

# Rivetweb assumes the default page is defined in the ::rivetweb::index variable

    set ::rivetweb::page_content $::rivetweb::index
    set ::rivetweb::current_pmodel \
                [$::rivetweb::rwebdb fetch $::rivetweb::index]
}

# vi:shiftwidth=4:softtabstop=4:
