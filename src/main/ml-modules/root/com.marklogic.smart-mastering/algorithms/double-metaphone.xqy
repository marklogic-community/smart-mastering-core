xquery version "1.0-ml";

module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms";

import module namespace spell = "http://marklogic.com/xdmp/spell"
  at "/MarkLogic/spell.xqy";

import module namespace const = "http://marklogic.com/smart-mastering/constants"
  at "/com.marklogic.smart-mastering/constants.xqy";

declare namespace match = "http://marklogic.com/smart-mastering/matcher";

declare option xdmp:mapping "false";

(:~
 : Allow matches that are similar in string distance. This algorithm uses a dictionary generated from current content
 : in the database. The dictionary should be regenerated occasionaly as new values are inserted into the database. This
 : is done by re-running the setup-double-metaphone function. This can be done manually or by re-installing the options
 : using `matcher:save-options`.
 :
 : Note that to generate the dictionary, there must be a range index on the XML element or JSON property where the
 : values can be found.
 :
 : To add this algorithm to your match configuration, add XML or JSON like the following, assuming that you have
 : configured a property named "name". Change the weights to work with your other properties.
 :
 : <algorithms>
 :  <algorithm
 :    name="double-metaphone"
 :    function="double-metaphone"
 :    namespace="http://marklogic.com/smart-mastering/algorithms"
 :    at="/com.marklogic.smart-mastering/algorithms/double-metaphone.xqy"/>
 : </algorithms>
 : <scoring>
 :   <add property-name="last-name" weight="8"/>
 :   <expand property-name="last-name" algorithm-ref="double-metaphone">
 :     <distance-threshold>20</distance-threshold>
 :     <dictionary>/dictionaries/last-names.xml</dictionary>
 :     <collation>http://marklogic.com/collation/codepoint</collation>
 :   </expand>
 : </scoring>
 :
 : {
 :  "options": {
 :    "propertyDefs": {
 :      "property": [
 :        { "namespace": "", "localname": "PersonSurName", "name": "last-name" },
 :      ]
 :    },
 :    "algorithms": {
 :      "algorithm": [
 :        {
 :          "name": "dbl-metaphone",
 :          "namespace": "http://marklogic.com/smart-mastering/algorithms",
 :          "function": "double-metaphone",
 :          "at": "/com.marklogic.smart-mastering/algorithms/double-metaphone.xqy"
 :        }
 :      ]
 :    },
 :    "scoring": {
 :      "add": [
 :        { "propertyName": "last-name", "weight": "8" }
 :      ],
 :      "expand": [
 :        {
 :          "propertyName": "last-name",
 :          "algorithmRef": "dbl-metaphone",
 :          "weight": "8",
 :          "dictionary": "/dictionaries/last-names.xml",
 :          "distance-threshold": 20,
 :          "collation": "http://marklogic.com/collation/codepoint"
 :        }
 :      ]
 :    }
 :  }
 : }
 :
 : There are three configurable properties for double-metaphone:
 : - dictionary: the URI of a dictionary that will be created by the setup script
 : - distance-threshold: see https://docs.marklogic.com/spell:suggest for information about how the distance-threshold
 :                       affects values.
 : - collation: used to identify the range index used to populate the dictionaries
 :
 :
 : @param $expand-values  the value(s) that the original document has for this property
 : @param $expand-xml  the scoring/expand element in the match options that applies this algorithm to a property
 : @param $options-xml  the complete match options
 :
 : @return a sequence of cts:querys based on the property values in the original document
 :)
declare
  %algorithms:setup(
    "namespace=http://marklogic.com/smart-mastering/algorithms",
    "function=setup-double-metaphone"
  )
  %algorithms:input("dictionary=xs:string*", "distance-threshold=xs:integer?")
  function
  algorithms:double-metaphone(
    $expand-values,
    $expand-xml as element(match:expand),
    $options-xml as element(match:options)
  )
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

declare function algorithms:setup-double-metaphone($expand-xml, $options-xml, $options)
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
            } catch ($e) {
              xdmp:log("Caught an error while generating double-metaphone dictionary: " || xdmp:quote($e), "error")
            }
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

