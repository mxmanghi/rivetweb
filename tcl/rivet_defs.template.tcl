#
# $Id: $
#

namespace eval ::rivetweb {
    set static_pages    [file join $site_base pages]
    set default_lang    en
    set sitemap_file    [file join $site_base site_structure.xml]

# path relative to DocumentRoot

    set local_pages	    docs

# menu customization

    set menu_html	    {div staticmenu}
    set title_html	    {div menuheader}
    set it_cont_html    {div itemcontainer}
    set item_html       {span menuitem}
    set link_class      navitem
}

