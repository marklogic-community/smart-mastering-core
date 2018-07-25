xquery version "1.0-ml";

module namespace tel = "http://marklogic.com/smart-mastering/telemetry";

declare option xdmp:mapping "false";

declare variable $incremented := fn:false();
declare variable $usage-count := "smartmastering.usage.count";

(:~
 : Increment the usage count for telemetry
 :)
declare function tel:increment()
{
  if (fn:not($incremented)) then (
    xdmp:feature-metric-increment(xdmp:feature-metric-register($usage-count)),
    xdmp:set($incremented, fn:true())
  )
  else ()
};

declare function tel:get-usage-count() as xs:int
{
  (xdmp:feature-metric-status()/*:feature-metrics/*:features/*:feature[@name=$usage-count]/data(), 0)[1]
};
