
namespace eval ::rivetweb {

    ::itcl::class Templates {

        private variable database [dict create]

        public method set {key field value} {

            if {[dict exists $database key] == 0} {
                dict set database $key {

            }


            dict set database $key $field $value
        }

        public method get {key field} {

            


        }
    }

}
