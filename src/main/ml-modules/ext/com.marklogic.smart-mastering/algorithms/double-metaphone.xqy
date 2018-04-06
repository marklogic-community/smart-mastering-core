xquery version "1.0-ml";

module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms";

import module namespace spell = "http://marklogic.com/xdmp/spell"
  at "/MarkLogic/spell.xqy";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/ext/com.marklogic.smart-mastering/constants.xqy";

declare option xdmp:mapping "false";

declare
  %algorithms:setup(
    "namespace=http://marklogic.com/smart-mastering/algorithms",
    "function=setup-double-metaphone"
  )
  %algorithms:input("dictionary=xs:string*", "distance-threshold=xs:integer?")
  function
  algorithms:double-metaphone($expand-values, $expand-xml, $options-xml)
{
  let $property-name := $expand-xml/@property-name
  let $property-def := $options-xml/*:property-defs/*:property[@name = $property-name]
  let $qname := fn:QName($property-def/@namespace, $property-def/@localname)
  let $dictionary := $expand-xml/*:dictionary
  let $spell-options :=
    element spell:options {
      element spell:distance-threshold {
        (
          $expand-xml/*:distance-threshold[. castable as xs:integer]/fn:string(.),
          100
        )[1]
      }
    }
  where fn:exists($dictionary)
  return
    let $expanded-values :=
      for $value in $expand-values
      return
        spell:suggest($dictionary, $value, $spell-options)[fn:not(fn:lower-case(.) = fn:lower-case($value))]
    where fn:exists($expanded-values)
    return
      cts:element-value-query(
        $qname,
        $expanded-values,
        "case-insensitive",
        $expand-xml/@weight
      )
};

declare function
  algorithms:setup-double-metaphone($expand-xml, $options-xml, $options)
{
  let $property-name := $expand-xml/@property-name
  let $property-def := $options-xml/*:property-defs/*:property[@name = $property-name]
  let $qname := fn:QName($property-def/@namespace, $property-def/@localname)
  for $dictionary in $expand-xml/*:dictionary ! fn:string(.)
  where fn:not(fn:doc-available($dictionary))
  return
    xdmp:spawn-function(
      function() {
        fn:function-lookup(xs:QName("xdmp:document-insert"), 4)(
          $dictionary,
          spell:make-dictionary(
            try {
              cts:values(
                cts:element-reference(
                  $qname,
                  "collation=" ||
                    (
                      map:get($options,"collation"),
                      fn:default-collation()
                    )[fn:normalize-space(.)][1]
                )
              )
            } catch * {()}
          ),
          (xdmp:permission($const:MDM-ADMIN, "update"), xdmp:permission($const:MDM-USER, "read")),
          ($const:OPTIONS-COLL, $const:DICTIONARY-COLL)
        )
      },
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>
    )
};

