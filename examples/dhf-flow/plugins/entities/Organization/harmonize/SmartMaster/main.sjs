// dhf.sjs exposes helper functions to make your life easier
// See documentation at:
// https://github.com/marklogic/marklogic-data-hub/wiki/dhf-lib
const dhf = require('/data-hub/4/dhf.sjs');

const writerPlugin = require('./writer.sjs');

/*
 * Plugin Entry point
 *
 * @param id          - the identifier returned by the collector
 * @param options     - a map containing options. Options are sent from Java
 *
 */
function main(id, options) {
  xdmp.log('org main');
  let envelope = {};
  // writers must be invoked this way.
  // see: https://github.com/marklogic/marklogic-data-hub/wiki/dhf-lib#run-writer
  dhf.runWriter(writerPlugin, id, envelope, options);
}

module.exports = {
  main: main
};
