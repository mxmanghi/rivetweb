#!/usr/bin/tclsh
#
# $Id: nuova_pagina.tcl 2092 2011-12-14 11:41:36Z massimo.manghi $
#
# 11-Jun-2010: La pagina viene creata con il menu 'banner' in posizione 'top'
#
#

package require tdom

set ::stdin_signal  0
set stato       file_input

set site_base       [pwd]
set script_dir      [file dirname [info script]]
set defs_location   [file join [pwd] rivet_defs.tcl]

puts "reading definitions from $defs_location"
source $defs_location

array set file_descriptor {}

proc prompt {termch} {
    switch $::stato {
        file_input {
            set prompt_text "nome file"
        }
        title_input {
            set prompt_text "titolo"
        }
        author_input {
            catch {
                set autore_login [exec whoami]
            }
            set prompt_text "autore \[$autore_login\]:"
        }
        default {
            incr ::stdin_signal
            return
        }
    }

    puts -nonewline $termch "$prompt_text: "

    flush $termch
}

proc parse_line {linea} {
    switch $::stato {
        file_input {
       
    # sostituiamo gli spazi con '_'
            regsub -all {\s+} [string trim $linea] "_" nome_file

            set proposed_name [file join $::rivetweb::static_pages  ${nome_file}.xml] 
            set proposed_name [string tolower $proposed_name]
            puts "nome proposto -> [file join $::rivetweb::static_pages $proposed_name]"
            if {[file exists $proposed_name]} {
                puts "Errore, file esistente"
            } else {
                set ::file_descriptor(name)     $proposed_name
                set ::file_descriptor(id)   $nome_file
                set ::stato             title_input
            }
        }
        title_input {
            set ::file_descriptor(title)    $linea
            set ::stato author_input
        }
        author_input {
            set ::file_descriptor(author)   $linea
            set ::stato         final_state
        }
    }
}

proc leggi_linea {ch} {
    if {![eof $ch]} {
    if {[gets stdin linea] > 0} {
        puts " <<< -- $linea"
        parse_line $linea
        prompt stdout
    } else {
        if {$::stato == "final_state"} {
            incr ::stdin_signal
        } elseif {$::stato == "author_input"} {
            parse_line [exec whoami]
            incr ::stdin_signal
        } else {
            prompt stdout
        }
    }
#   if {$::stato == "final_state"} {
#       incr ::stdin_signal
#   } 
    } else {
        incr ::stdin_signal
    }
}

proc termio_setup {} {
    fileevent stdin readable [list leggi_linea stdin]
    prompt stdout
}

termio_setup

vwait ::stdin_signal

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
set text_o  [$pagina_dom createTextNode "\$Date: \$"]
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

set content_o   [$pagina_dom createElement content]
set title_o [$pagina_dom createElement title]
set text_o  [$pagina_dom createTextNode $file_descriptor(title)]
$title_o    appendChild $text_o
$content_o  appendChild $title_o

set headline_o  [$pagina_dom createElement headline]
set text_o  [$pagina_dom createTextNode $file_descriptor(title)]
$headline_o appendChild $text_o
$content_o  appendChild $headline_o

set pagetext_o  [$pagina_dom createElement pagetext]
set comment_o   [$pagina_dom createComment "Qui va inserito il testo XHTML della pagina"]
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
    puts "Errore: nella creazione di $file_descriptor(name) \n$e"
    exit
}

$page_dom asXML -indent 4 -channel $xmlfp
close $xmlfp

puts "La pagina $file_descriptor(name) ($file_descriptor(title)) è stata creata"

if {[catch {
    exec svn add $file_descriptor(name)
    exec svn propset svn:keywords "Id Author Date" $file_descriptor(name)
} e]} {
    puts "Errore: $e"
    puts "probabilmente questa non è una working copy di svn"
}

exit
