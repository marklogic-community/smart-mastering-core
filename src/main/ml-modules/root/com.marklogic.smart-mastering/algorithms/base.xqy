xquery version "1.0-ml";

module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms";

import module namespace algorithms = "http://marklogic.com/smart-mastering/algorithms"
  at  "double-metaphone.xqy",
      "standard-reduction.xqy",
      "thesaurus.xqy";

import module namespace fun-ext = "http://marklogic.com/smart-mastering/function-extension"
  at "../function-extension/base.xqy";

declare function algorithms:default-function-lookup(
  $name as xs:string, 
  $arity as xs:int)
{
  fn:function-lookup(
    fn:QName(
      "http://marklogic.com/smart-mastering/algorithms", 
      $name
    ),
    $arity
  )
};

declare function algorithms:build-algorithms-map($algorithms-xml) 
{
  map:new((
    for $algorithm-xml in $algorithms-xml/*:algorithm
    return
      map:entry(
        $algorithm-xml/@name,
        fun-ext:function-lookup(
          fn:string($algorithm-xml/@function),
          fn:string($algorithm-xml/@namespace), 
          fn:string($algorithm-xml/@at),
          algorithms:default-function-lookup(?, 3)
        )
      )
  ))
};

declare function algorithms:setup-algorithms($options)
{
  let $setup-map := algorithms:setup-map-from-xml($options/*:algorithms)
  for $item in $options//*[@algorithm-ref]
  return
    fun-ext:execute-function(
      map:get($setup-map, fn:string($item/@algorithm-ref)), 
      map:new((
        map:entry("arg1", $item), 
        map:entry("arg2", $options)
      ))
    )
};


declare function algorithms:setup-map-from-xml($algorithms-xml)
{
  algorithms:setup-map-from-map(
    algorithms:build-algorithms-map($algorithms-xml)
  )
};


declare function algorithms:setup-map-from-map($algorithms-map)
{ 
  map:new(
    for $key in map:keys($algorithms-map)
    let $funct := map:get($algorithms-map, $key)
    return
      let $annotation := fun-ext:get-function-annotation($funct, xs:QName("algorithms:setup"))
      where fn:exists($annotation) and fn:not($annotation instance of null-node())
      return
        let $setup-function-details := 
          if ($annotation instance of xs:string*) then
            map:new(
              for $item in $annotation
              let $parts := fn:tokenize(fn:string($item), "=")
              return
                map:entry($parts[1], $parts[2])
            )
          else if ($annotation instance of object-node()) then
            xdmp:from-json($annotation)
          else
            $annotation
        let $module := (map:get($setup-function-details, "at"), xdmp:function-module($funct))[1]
        let $setup-function :=
          fun-ext:function-lookup(
            fn:string(map:get($setup-function-details, "function")),
            map:get($setup-function-details, "namespace"), 
            $module,
            algorithms:default-function-lookup(?, 3)
          )
        where fn:exists($setup-function)
        return
            map:entry(
              $key,
              xdmp:apply(
                $setup-function,
                ?,
                ?,
                $setup-function-details
              )
            )
  )
};

declare function algorithms:execute-algorithm($algorithm, $values, $ref-element, $options)
{
  fun-ext:execute-function(
    $algorithm, 
    map:new((
      map:entry("arg1", $values), 
      map:entry("arg2", $ref-element), 
      map:entry("arg3", $options)
    ))
  )
};
