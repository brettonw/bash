#! /usr/bin/env node

var _fs = require ("fs");
var _path = require ("path");


var dotClean = function (path) {
    try {
        _fs.readdirSync (path).sort ().forEach (function (leaf) {
            //process.stderr.write ("Test: " + leaf + "\n");
            var leafPath = _path.join (path, leaf);
            if ((leaf.indexOf ("DS_Store") > -1) || (leaf.indexOf ("._") == 0)) {
                process.stderr.write ("  Remove: " + leafPath + "\n");
                try {
                    _fs.unlinkSync(leafPath);
                }
                catch (error) {
                    //process.stderr.write (error);
                }
            } else if (_fs.statSync (leafPath).isDirectory ()) {
                dotClean (leafPath);
            }
        });
    }
    catch (err) {
        process.stderr.write ("ERROR: Skipping " + path + "\n" + err.message + "\n");
    }
}

dotClean (process.argv[2]);
