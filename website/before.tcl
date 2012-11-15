# -- before.tcl
#
# website specific request processing before template/script
# evaluation
#

source [file join $::rivetweb::scripts before.tcl]

### custom request preprocessing has appear here below

set page_title [$::rivetweb::current_pmodel title $::rivetweb::language]

