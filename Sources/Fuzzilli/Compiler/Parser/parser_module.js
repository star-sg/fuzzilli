const babel = require('@babel/core');
const fs = require('fs');

if (process.argv.length != 3) {
    console.error(`Usage: node ${process.argv[1]} path/to/code.js`);
    process.exit(-1);
}

let inputFilePath = process.argv[2];

function tryReadFile(path) {
    let content;
    try {
        content = fs.readFileSync(path, 'utf8').toString();
    } catch(err) {
        console.error(`Couldn't read ${path}: ${err}`);
        process.exit(-1);
    }
    return content;
}

let script = tryReadFile(inputFilePath);

babel.transform(script, {
   sourceType: "module",
}).code;
