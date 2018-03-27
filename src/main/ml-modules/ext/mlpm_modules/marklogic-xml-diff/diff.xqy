xquery version "1.0-ml";

module namespace diff = "http://marklogic.com/demo/xml-diff";

import module namespace mem = "http://maxdewpoint.blogspot.com/memory-operations/functional"
  at "/ext/mlpm_modules/XQuery-XML-Memory-Operations/memory-operations-functional.xqy";
import module namespace xq3 = "http://maxdewpoint.blogspot.com/xq3-ml-extensions"
  at "/ext/mlpm_modules/xq3-ml-extensions/xq3.xqy";

declare variable $memoization as map:map := map:map();

declare function diff:xml-diff($doc-orig as node(), $doc-new as node()) as node() {
  if (fn:deep-equal($doc-orig, $doc-new)) then
    $doc-new
  else
    let $doc-orig := diff:detect-removals($doc-new, $doc-orig, xs:QName("diff:addition"), fn:true())
    let $doc-new := diff:detect-removals($doc-orig, $doc-new, xs:QName("diff:removal"), fn:true())
    let $doc-orig-map as map:map := diff:create-map-of-xml($doc-orig)
    let $doc-new-map as map:map := diff:create-map-of-xml($doc-new)
    let $diffs-from-original := $doc-orig-map - $doc-new-map
    let $diffs-from-new := $doc-new-map - $doc-orig-map
    return
      diff:typeswitch-transform($doc-new, $diffs-from-original, $diffs-from-new)
};

declare function diff:create-map-of-xml($doc as node()) as map:map {
  map:new((
    for $text in ($doc//text() union xq3:innermost($doc/descendant-or-self::*[fn:string(.) eq '']) union $doc/descendant-or-self::*/@diff:addition)
    return
      if ($text instance of element()) then
        map:entry(xdmp:path($text)||"/text()", '')
      else
        map:entry(xdmp:path($text), fn:string($text))
  ))
};

declare function diff:detect-removals($doc-base as node(), $doc-new as node(), $annotation as xs:QName, $retain-content as xs:boolean) {
  let $elements-with-removed-children-map as map:map := map:new((
    for $element in $doc-base/descendant-or-self::*[*]
    let $path := xdmp:path($element)
    let $counter-part := $doc-new ! xdmp:unpath($path)
    where fn:exists($counter-part) and fn:count($element/*) gt fn:count($counter-part/*)
    return
      map:entry($path, ($element, $counter-part))
  ))
  let $extend-elements := map:keys($elements-with-removed-children-map) ! map:get($elements-with-removed-children-map, .)[2]
  let $doc-new :=
                if (map:count($elements-with-removed-children-map) gt 0) then
                   mem:execute(
                     mem:transform(
                       mem:copy($doc-new),
                       $extend-elements,
                       function($node) {
                         let $node-path := xdmp:path($node)
                         let $orig-counter-part :=  map:get($elements-with-removed-children-map, $node-path)[1]
                         let $removed-count := fn:count($orig-counter-part/*) - fn:count($node/*)
                         let $possible-removed :=
                             fn:subsequence(
                               for $orig-child at $pos in $orig-counter-part/*
                               let $orig-node-name := fn:node-name($orig-child)
                               let $max-score :=
                                   fn:max(
                                      for $new-child at $new-pos in $node/*
                                      let $orig-str-len := xs:double(fn:string-length($orig-child))
                                      let $new-str-len := xs:double(fn:string-length($new-child))
                                      where fn:not($orig-child = $new-child)
                                      return
                                        let $comparison :=
                                          diff:compare-strings($orig-child, $new-child)/node()
                                        let $same-length :=
                                          xs:double(fn:sum(
                                              $comparison[type eq "same"]/text/fn:string-length(.)
                                          ))
                                        let $score :=
                                          $same-length
                                            div
                                          fn:avg(($orig-str-len, $new-str-len))
                                        return
                                          $score
                                  )
                              let $node-name-count-diff :=
                                  fn:abs(
                                    fn:count($node/*[fn:node-name(.) eq $orig-node-name]) - 
                                    fn:count($orig-counter-part/*[fn:node-name(.) eq $orig-node-name])
                                  )
                               order by $max-score ascending, $node-name-count-diff descending
                               return
                                 element {fn:node-name($orig-child)} {
                                  attribute diff:pos {$pos},
                                  attribute {$annotation} {fn:true()},
                                  if ($retain-content) then
                                    ()
                                  else
                                    ()
                                 },
                               1,
                               $removed-count
                             )
                         return
                           element {fn:node-name($node)} {
                             $node/@*,
                             for $n at $pos in $orig-counter-part/node()
                             let $prev-element-count := fn:count($n/preceding-sibling::element())
                             let $element-position := $prev-element-count + fn:count($n/self::element())
                             let $adjusted-position := $pos - fn:count($possible-removed[@diff:pos lt $element-position])
                             let $adjustments := $possible-removed[@diff:pos = $pos]
                             return (
                               if ($n instance of element() and fn:exists($adjustments)) then
                                 $adjustments
                               else
                                 $node/node()[$adjusted-position]
                             )
                           }
                       }
                     )
                   )
                else
                  $doc-new
  return $doc-new
};

declare function diff:typeswitch-transform($doc-new as node(), $diffs-from-original as map:map, $diffs-from-new as map:map) as node()* {
  typeswitch($doc-new)
  case element() return
    element {fn:node-name($doc-new)} {
      $doc-new/@*,
      let $path := xdmp:path($doc-new)
      return (
        if (map:contains($diffs-from-original, $path || "/@diff:addition")) then (
          attribute diff:addition {fn:true()},
          $doc-new/node()
        ) else if (fn:exists($doc-new/@diff:removal)) then (
          $doc-new/node()
        ) else (
          if ($doc-new/node()) then
            for $n in $doc-new/node()
            return
              diff:typeswitch-transform($n, $diffs-from-original, $diffs-from-new)
          else
            let $path := $path || "/text()"
            where map:contains($diffs-from-new, $path)
            return (
              element diff:removal {map:get($diffs-from-original,$path)}
            )
         )
      )
    }
  case document-node() return
    document {
      for $n in $doc-new/node()
      return
        diff:typeswitch-transform($n, $diffs-from-original, $diffs-from-new)
    }
  case text() return
    let $path := xdmp:path($doc-new)
    return
    if (map:contains($diffs-from-original,$path) or map:contains($diffs-from-new,$path)) then
      if (map:contains($diffs-from-original,$path) and map:contains($diffs-from-new,$path)) then
        let $comparison := diff:compare-strings(map:get($diffs-from-original,$path), map:get($diffs-from-new,$path))
        for $group-part in $comparison/node()
        let $type := $group-part/type
        let $text := $group-part/text
        where $text ne ''
        return
          if ($type eq "removed") then
            element diff:removal {$text}
          else if ($type eq "added") then
            element diff:addition {$text}
          else
            text {$text}
      else if (map:contains($diffs-from-original,$path)) then
        element diff:removal {map:get($diffs-from-original,$path)}
      else
        element diff:addition {map:get($diffs-from-new,$path)}
    else
      $doc-new
  default return
    $doc-new

};

declare
function diff:compare-strings(
    $string1 as xs:string,
    $string2 as xs:string
)
{
  if ($string1 eq $string2) then
    array-node {
      object-node {
        "type": "same",
        "text": $string1
      }
    }
  else
    let $hash := xdmp:md5($string1 || "|::|" || $string2, "base64")
    let $backwards-hash := xdmp:md5($string2 || "|::|" || $string1, "base64")
    return
      if (map:contains($memoization, $hash)) then (
        map:get($memoization, $hash)
      ) else if (map:contains($memoization, $backwards-hash)) then (
        let $backwards-comparison := map:get($memoization, $backwards-hash)
        let $result :=
          array-node {
            for $part in $backwards-comparison/node()
            return
              object-node {
                "text": $part/text,
                "type":
                  if ($part/type eq "added") then
                    "removed"
                  else if ($part/type eq "removed") then
                    "added"
                  else
                    $part/type
              }
          }
        return (map:put($memoization, $hash, $result),$result)
      ) else
        let $parts1 := cts:tokenize($string1)
        let $parts2 := cts:tokenize($string2)
        let $result :=
          diff:group-parts(
            $parts1,
            $parts2,
            (),
            ()
          )
        return (map:put($memoization, $hash, $result),$result)
};

declare
function diff:group-parts(
    $parts1,
    $parts2,
    $current-group,
    $processed-groups
)
{
  if (fn:empty($parts1) or fn:empty($parts2)) then (
    array-node {
      $processed-groups,
      if (fn:exists($current-group)) then
        object-node {
          "type": "same",
          "text": fn:string-join($current-group, "")
        }
      else (),
      if (fn:exists($parts1)) then
        object-node {
          "type": "removed",
          "text": fn:string-join($parts1,"")
        }
      else if (fn:exists($parts2)) then
        object-node {
          "type": "added",
          "text": fn:string-join($parts2,"")
        }
      else ()
    }
  ) else if (fn:compare(fn:head($parts1), fn:head($parts2)) eq 0) then (
    diff:group-parts(
      fn:tail($parts1),
      fn:tail($parts2),
      ($current-group, fn:head($parts1)),
      $processed-groups
    )
  ) else (
    let $earliest-matches := diff:find-earliest-matches($parts1, $parts2)
    let $earliest-match1 :=
      if (fn:exists(map:get($earliest-matches,'pos1'))) then
        map:get($earliest-matches,'pos1')
      else
        fn:count($parts1) + 1
    let $removed-range := 1 to ($earliest-match1 - 1)
    let $earliest-match2 :=
      if (fn:exists(map:get($earliest-matches,'pos2'))) then
        map:get($earliest-matches,'pos2')
      else
        fn:count($parts2) + 1
    let $added-range := 1 to ($earliest-match2 - 1)
    let $same-text := fn:string-join($current-group, "")[. ne '']
    let $removed-text := fn:string-join($parts1[fn:position() = $removed-range], "")[. ne '']
    let $added-text := fn:string-join($parts2[fn:position() = $added-range], "")[. ne '']
    return
      diff:group-parts(
        fn:subsequence($parts1, $earliest-match1),
        fn:subsequence($parts2, $earliest-match2),
        (),
        (
          $processed-groups,
          if ($same-text) then
            object-node { "type": "same", "text": $same-text}
          else (),
          if ($removed-text) then
            object-node { "type": "removed", "text": $removed-text}
          else (),
          if ($added-text) then
            object-node { "type": "added", "text": $added-text}
          else ()
        )
      )
  )
};

declare function diff:find-earliest-matches($parts1 as xs:string*, $parts2 as xs:string*)
{
  (for $result in diff:find-earliest-matches-helper($parts1, $parts2)
  order by map:get($result, 'cost')
  return
    $result)[1]
};


declare function diff:find-earliest-matches-helper($parts1 as xs:string*, $parts2 as xs:string*)
{
  (
    diff:find-earliest-matches-helper('pos1', $parts1, 1, fn:count($parts1), 'pos2', $parts2, $parts2, 1, fn:count($parts2)),
    diff:find-earliest-matches-helper('pos2', $parts2, 1, fn:count($parts2), 'pos1', $parts1, $parts1, 1, fn:count($parts1))
  )
};

declare function diff:find-earliest-matches-helper(
  $parts1-label as xs:string,
  $parts1 as xs:string*,
  $parts1-cost as xs:integer,
  $parts1-length as xs:integer,
  $parts2-label as xs:string,
  $parts2 as xs:string*,
  $parts2-all as xs:string*,
  $parts2-cost as xs:integer,
  $parts2-length as xs:integer
)
{
  if ($parts1-cost gt $parts1-length) then
    ()
  else if ($parts2-cost gt $parts2-length) then
    diff:find-earliest-matches-helper($parts1-label, fn:tail($parts1), $parts1-cost + 1, $parts1-length, $parts2-label, $parts2-all, $parts2-all, 1, $parts2-length)
  else if (fn:head($parts1) eq fn:head($parts2)) then
    map:new((
      map:entry('cost', $parts2-cost + $parts1-cost),
      map:entry($parts1-label, $parts1-cost),
      map:entry($parts2-label, $parts2-cost)
    ))
  else
    diff:find-earliest-matches-helper($parts1-label, $parts1, $parts1-cost, $parts1-length, $parts2-label, fn:tail($parts2), $parts2-all, $parts2-cost + 1, $parts2-length)
};