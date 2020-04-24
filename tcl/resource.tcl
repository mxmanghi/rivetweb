# -- resource.tcl
#

namespace eval ::rivetweb {

    ::itcl::class Resource {
        public method timestamp {} { return [clock seconds] }
    }

    namespace eval Resource {
        ::itcl::class True {
            inherit Resource

            public method timestamp {} { return [clock seconds] }
        }
        
        ::itcl::class False {
            inherit Resource

            public method timestamp {} { return 0 }
        }
    }
}
package provide rwresource 1.0
