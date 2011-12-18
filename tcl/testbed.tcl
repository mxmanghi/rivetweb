package require tdom

set xmlfp [open pages/shaded_table.xml r]
set xml [read $xmlfp]

close $xmlfp

dom parse $xml doc
$doc documentElement root

foreach el [$root childNodes] {
    puts "-> $el [$el nodeName] [$el nodeValue] [$el text] "
}

foreach el [$root getElementsByTagName programlisting] {
    puts "[$el text]"
    puts "[$el asXML]"
}
