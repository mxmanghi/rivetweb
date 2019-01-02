# -- resource.tcl
#

namespace eval ::rivetweb {

    ::itcl::class Resource {
        public method timestamp {} { return [clock seconds] }
    }
    
}
package provide rwresource 1.0
