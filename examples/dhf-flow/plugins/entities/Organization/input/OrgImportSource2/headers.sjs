/*
 * Create Headers Plugin
 *
 * @param id       - the identifier returned by the collector
 * @param content  - the output of your content plugin
 * @param options  - an object containing options. Options are sent from Java
 *
 * @return - an object of headers
 */
function createHeaders(id, content, options) {
  return {
    id: sem.uuidString(),
    sources: {
      source: {
        name: id.replace("/([^/]+)/.+", "$1"),
        importId: options.importId,
        user: xdmp.getCurrentUser(),
        dateTime: fn.currentDateTime()
      }
    }
  };
}

module.exports = {
  createHeaders: createHeaders
};

