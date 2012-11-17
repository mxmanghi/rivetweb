#!/usr/bin/tclsh
#
#
#

set rweb_root [file normalize [file join [file dirname [info script]] ..]]

lappend auto_path $rweb_root 

puts "setting auto_path as $auto_path"

package require rwterm
package require rivetweb
package require tdom

set ::stdin_signal  0
set stato           file_input

#source [file join $::rivetweb::scripts rivetweb_ns.tcl]
::rivetweb::setup $rweb_root [pwd]
::rivetweb::init $::rivetweb::datasource $::rivetweb::menusource

# site_defs.tcl overrides default

set defs_location [file join $::rivetweb::site_base site_defs.tcl]
eval lappend auto_path $::rivetweb::rivetlib

puts "reading definitions from $defs_location"
source $defs_location

array set file_descriptor {}

proc parse_line {linea} {

    switch $::stato {
        file_input {
    
# we replace spaces with underscores   
    
            regsub -all {\s+} [string trim $linea] "_" nome_file

            set nome_file           [string tolower $nome_file]
            set proposed_name       [file join  $::rivetweb::site_base      \
                                                $::rivetweb::static_pages   \
                                                ${nome_file}.xml]
 
            puts "proposed name -> [file join $::rivetweb::static_pages $proposed_name]"
            if {[file exists $proposed_name]} {
                puts "Error, file not existing"
            } else {
                set ::file_descriptor(name) $proposed_name
                set ::file_descriptor(id)   $nome_file
                set ::stato                 title_input
            }
        }
        title_input {
            set ::file_descriptor(title)    $linea
            set ::stato                     author_input
        }
        author_input {
            set ::file_descriptor(author)   $linea
            set ::stato                     final_state
        }
    }

}

proc leggi_dati {ch} {

    while {1} {

        switch $::stato {
            file_input {
                set linea [::rwterm::read_input_line $ch "Filename: "]
            }
            title_input {
                set linea [::rwterm::read_input_line $ch "Page Title: "]
            }
            author_input {
                set linea [::rwterm::read_input_line $ch "Author: "]
            }
        }
        
        if {[eof $ch]} {
            puts "\nexiting..."
            exit
        }        

        if {$::stato == "final_state"} { 
            ::rwterm::deregister_input_handler $ch
            incr ::stdin_signal 
            puts "done.."
            return
        }

        parse_line $linea
    }
}

leggi_dati stdin 

parray file_descriptor

# creiamo la struttura DOM del file.:
#
# * page (con attributo id)
#   - ident 
#   - author
#   - date
#   - title
#   - headline
#   - menu
#   - content
#   + title
#   + headline
#   + pagetext
#

set pagina_dom  [dom createDocument page]
set root_el [$pagina_dom documentElement]

$root_el setAttribute id $file_descriptor(id)

set ident_o [$pagina_dom createElement ident]
set text_o  [$pagina_dom createTextNode "\$Id: \$"]
$ident_o    appendChild $text_o

set author_o [$pagina_dom createElement author]
set text_o   [$pagina_dom createTextNode "\$Author: $file_descriptor(author) \$"]
$author_o   appendChild $text_o

set date_o  [$pagina_dom createElement date]
set text_o  [$pagina_dom createTextNode \
                "\$Date: [clock format [clock seconds] -format \"%Y-%m-%d %H:%M:%S\"] \$"]
$date_o     appendChild $text_o

set titleg_o [$pagina_dom createElement title]
set text_o  [$pagina_dom createTextNode $file_descriptor(title)]
$titleg_o   appendChild $text_o

set headlineg_o [$pagina_dom createElement headline]
set text_o  [$pagina_dom createTextNode $file_descriptor(title)]
$headlineg_o    appendChild $text_o

set banner_o [$pagina_dom createElement menu]
$banner_o    setAttribute position top
set text_o   [$pagina_dom createTextNode banner]
$banner_o    appendChild $text_o

set menu_o  [$pagina_dom createElement menu]
$menu_o     setAttribute position left
set text_o  [$pagina_dom createTextNode main]
$menu_o     appendChild $text_o

set content_o [$pagina_dom createElement content]
set title_o [$pagina_dom createElement title]
set text_o  [$pagina_dom createTextNode $file_descriptor(title)]
$title_o    appendChild $text_o
$content_o  appendChild $title_o

set headline_o  [$pagina_dom createElement headline]
set text_o  [$pagina_dom createTextNode $file_descriptor(title)]
$headline_o appendChild $text_o
$content_o  appendChild $headline_o

set pagetext_o  [$pagina_dom createElement pagetext]
set comment_o   [$pagina_dom createComment "The XHTML content goes here"]
$pagetext_o appendChild $comment_o
$content_o  appendChild $pagetext_o

#

foreach e [list $ident_o  \
                $author_o \
                $date_o   \
                $titleg_o \
                $headlineg_o \
                $banner_o \
                $menu_o   \
                $content_o] {
    $root_el appendChild $e
}

set page_dom $root_el

# procediamo alla creazione della pagina.

if {[catch {set xmlfp [open $file_descriptor(name) w+]} e]} {
    puts "Error creating $file_descriptor(name) \n$e"
    exit
}

$page_dom asXML -indent 4 -channel $xmlfp
close $xmlfp

puts "Page $file_descriptor(name) ($file_descriptor(title)) has been created"

#if {[catch {
#    exec svn add $file_descriptor(name)
#    exec svn propset svn:keywords "Id Author Date" $file_descriptor(name)
#} e]} {
#    puts "Errore: $e"
#    puts "probabilmente questa non è una working copy di svn"
#}

exit
