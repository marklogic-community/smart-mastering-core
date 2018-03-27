xquery version "1.0-ml";

module namespace xq3 = "http://maxdewpoint.blogspot.com/xq3-ml-extensions";

declare option xdmp:mapping "false";

declare function xq3:sliding-window(
  $sequence as item()*,
  $only-start as xs:boolean,
  $start-condition as function(*),
  $only-end as xs:boolean,
  $end-condition as function(*),
  $return as function(*)
) {
  let $windows as map:map := map:map(),
    $sequence-size as xs:unsignedInt := fn:count($sequence)
  for $item at $pos in $sequence
  let $start as xs:boolean :=
                    ((fn:not($only-start) and 1 eq $pos) or
                    (switch (fn:function-arity($start-condition))
                    case 2 return $start-condition($item,$pos)
                    default return $start-condition($item))
                    ),
    $_ as empty-sequence() :=
                    if ($start)
                    then
                      let $window-map := map:map()
                      return (
                        map:put($window-map,'start',$item),
                        map:put($window-map,'start-pos',$pos),
                        map:put($windows,xq3:_next-key($windows),$window-map)
                      ) else ()
  for $window-key in map:keys($windows)
  let $window-map as map:map := map:get($windows,$window-key),
      $end as xs:boolean :=
                    ((fn:not($only-end) and $sequence-size eq $pos) or
                    (switch (fn:function-arity($end-condition))
                    case 4 return $end-condition($item,$pos,map:get($window-map,'start'),map:get($window-map,'start-pos'))
                    case 3 return $end-condition($item,$pos,map:get($window-map,'start'))
                    case 2 return $end-condition($item,$pos)
                    default return $end-condition($item))
                    ),
    $_ as empty-sequence() := map:put($window-map,'window',(map:get($window-map,'window'),$item))
  where $end
  return
    (
    switch (fn:function-arity($return))
    case 5 return $return(map:get($window-map,'window'),map:get($window-map,'start'),map:get($window-map,'start-pos'),$item, $pos)
    case 4 return $return(map:get($window-map,'window'),map:get($window-map,'start'),map:get($window-map,'start-pos'),$item)
    case 3 return $return(map:get($window-map,'window'),map:get($window-map,'start'),map:get($window-map,'start-pos'))
    case 2 return $return(map:get($window-map,'window'),map:get($window-map,'start'))
    default return $return(map:get($window-map,'window')),
    map:delete($windows,$window-key)
    )

};

declare function xq3:_next-key($windows as map:map) as xs:string {
  fn:string((fn:max(map:keys($windows) ! xs:unsignedInt(.)), 0)[1] + 1)
};

declare function xq3:tumbling-window(
  $sequence as item()*,
  $only-start as xs:boolean,
  $start-condition as function(*),
  $only-end as xs:boolean,
  $end-condition as function(*),
  $return as function(*)
) {
  let $map as map:map := map:map(),
    $sequence-size as xs:unsignedInt := fn:count($sequence)
  for $item at $pos in $sequence
  let $start as xs:boolean :=
                    ((fn:not($only-start) and 1 eq $pos) or
                    (switch (fn:function-arity($start-condition))
                    case 2 return $start-condition($item,$pos)
                    default return $start-condition($item))
                    ),
    $started as xs:boolean := map:count($map) gt 0,
    $_ as empty-sequence() := if ($start and fn:not($started)) then (map:put($map,'start',$item),map:put($map,'start-pos',$pos)) else (),
    $end as xs:boolean :=
                    ((fn:not($only-end) and $sequence-size eq $pos) or
                    (switch (fn:function-arity($end-condition))
                    case 4 return $end-condition($item,$pos,map:get($map,'start'),map:get($map,'start-pos'))
                    case 3 return $end-condition($item,$pos,map:get($map,'start'))
                    case 2 return $end-condition($item,$pos)
                    default return $end-condition($item))
                    ),
    $window-started as xs:boolean := $start or $started,
    $_ as empty-sequence() := if ($window-started) then map:put($map,'window',(map:get($map,'window'),$item)) else ()
  where $end and $window-started
  return
    (
    switch (fn:function-arity($return))
    case 5 return $return(map:get($map,'window'),map:get($map,'start'),map:get($map,'start-pos'),$item, $pos)
    case 4 return $return(map:get($map,'window'),map:get($map,'start'),map:get($map,'start-pos'),$item)
    case 3 return $return(map:get($map,'window'),map:get($map,'start'),map:get($map,'start-pos'))
    case 2 return $return(map:get($map,'window'),map:get($map,'start'))
    default return $return(map:get($map,'window')),
    map:clear($map)
    )

};

declare function xq3:has-children($node as node()?) as xs:boolean {
  fn:exists($node/child::node())
};

declare function xq3:innermost($nodes as node()*) as node()* {
  $nodes except $nodes/ancestor::node()
};

declare function xq3:outermost($nodes as node()*) as node()*
{
  $nodes except $nodes[ancestor::node() intersect $nodes]
};

declare function xq3:path($arg as node()?) as xs:string {
  if (fn:exists($arg) and fn:root($arg) instance of document-node())
  then
      fn:string-join(
        $arg/ancestor-or-self::node()/(
          typeswitch(.)
          case element() return
            let $ns := fn:namespace-uri(.), $name := fn:local-name(.), $qname := fn:QName($ns,$name)
            return fn:concat('Q{',$ns,'}',$name,'[',(fn:count(./preceding-sibling::node()[fn:node-name(.) eq $qname]) + 1),']')
          case attribute() return
            let $ns := fn:namespace-uri(.), $name := fn:local-name(.)
            return fn:string-join(('@',if ($ns eq "") then () else ('Q{', $ns,'}'),$name),'')
          case text() return
            fn:concat('text()[',(fn:count(./preceding-sibling::text()) + 1),']')
          case comment() return
            fn:concat('comment()[',(fn:count(./preceding-sibling::comment()) + 1),']')
          case processing-instruction() return
            let $name := fn:local-name(.)
            return fn:concat('processing-instruction(',$name,')[',(fn:count(./preceding-sibling::processing-instruction()[fn:local-name(.) eq $name]) + 1),']')
          case document-node() return
            ''
          default return ()
        ),
      "/")
  else fn:error(fn:QName("http://www.w3.org/2005/xqt-errors","err:FODC0001"),"No context document.")
};

declare function xq3:unpath($arg as xs:string, $node as node()) as node()? {
  xq3:unpath-step(fn:tokenize(fn:replace($arg,'((^|(^[^/])|(\]))/)','$2|~|'), '\|~\|')[. ne ''], $node)
};

declare function xq3:unpath-step($steps as xs:string*, $node as node()) as node()? {
  if (fn:empty($steps))
  then $node
  else
    let $cur-step := fn:head($steps)
    return (
      if (fn:matches($cur-step,'^@'))
      then
        let $qname := if (fn:contains($cur-step,":"))
                      then fn:QName(fn:replace($cur-step,'^@Q\{(.*)\}:.*','$1'),fn:substring-after($cur-step,':'))
                      else fn:QName("",fn:substring-after($cur-step,'@'))
        return $node/attribute()[fn:node-name(.) eq $qname]
      else if (fn:matches($cur-step,'^Q\{.*\}.*'))
      then
        let $qname :=  fn:QName(fn:replace($cur-step,'^Q\{(.*)\}.*','$1'),fn:replace($cur-step,'^Q\{.*\}(.*)\[[0-9]+\]$','$1')),
          $position := fn:number(fn:replace($cur-step,'^Q\{.*\}.*\[([0-9]+)\]$','$1'))
        return (xq3:unpath-step(fn:tail($steps), ($node/element()[fn:node-name(.) eq $qname])[$position]))
      else if (fn:matches($cur-step,'^comment\(\)\[[0-9]+\]$'))
      then
        let $position := fn:number(fn:replace($cur-step,'^comment\(\)\[([0-9]+)\]$','$1'))
        return $node/comment()[$position]
      else if (fn:matches($cur-step,'^text\(\)\[[0-9]+\]$'))
      then
        let $position := fn:number(fn:replace($cur-step,'^text\(\)\[([0-9]+)\]$','$1'))
        return $node/text()[$position]
      else if (fn:matches($cur-step,'^processing-instruction\(.*\)\[[0-9]+\]$'))
      then
        let $qname :=  fn:QName("",fn:replace($cur-step,'^processing-instruction\((.*)\)\[[0-9]+\]$','$1')),
            $position := fn:number(fn:replace($cur-step,'^processing-instruction\(.*\)\[([0-9]+)\]$','$1'))
        return ($node/processing-instruction()[fn:node-name(.) eq $qname])[$position]
      else fn:error(xs:QName('UNPATH'), "Invalid unpath exception", $cur-step)
      )
};
