# Upgrading Smart Mastering Core

This document describes steps needed when upgrading Smart Mastering Core from one version to another. 

## v1.0.0 to vNext

### Custom JavaScript actions matches parameter

Custom JavaScript actions have a `matches` parameter. In v1.0.0, it would get a JSON array that held an XML string, 
like this:

    ["<result uri=\"/source/2/doc2.xml\" index=\"1\" score=\"70\" threshold=\"Kinda Match\" action=\"custom-action\"/>"]

The `matches` parameter now gets JSON data:

    [
      {
        "uri": "/source/2/doc2.xml",
        "score": 70,
        "threshold": "Kinda Match"
      }
    ]

