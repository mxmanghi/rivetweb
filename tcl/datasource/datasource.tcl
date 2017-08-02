#
# -- root class for datasources
#
#
# abstract class defining the common interface for all datasources
#
#

package require UrlHandler

namespace eval ::rwdatas {
    ::itcl::class Datasource {
        inherit UrlHandler
        public proc   set_alias {alias aliasdef}
        public proc   get_alias {alias aliasdef}
    }

    ::itcl::body Datasource::set_alias {alias aliasdef} {
        UrlHandler::set_alias $alias $aliasdef
    }

    ::itcl::body Datasource::get_alias {alias aliasdef} {
        upvar $aliasdef alias_definition

        return [UrlHandler::get_alias $alias $alias_definition]
    }
}

package provide Datasource 1.0

