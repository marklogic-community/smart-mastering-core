'use strict'

function customAction(uri, matches, mergeOptions) {
  let matchUris = [];
  for (let i = 0; i < matches.length; i++) {
    matchUris.push(matches[i].xpath('@uri'));
  }
  xdmp.documentInsert(
    "/sjs-action-output.json",
    {
      uri: uri,
      matches: matchUris,
      options: mergeOptions
    }
  );
}

exports.customAction = customAction;
