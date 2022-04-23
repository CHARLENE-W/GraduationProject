var fs = require('fs');

//the path of new file
var newFile="./res.json";

//overwrite the object
JsonObject={}

fs.writeFile(newFile,JSON.stringify(JsonObject), { flag: 'w', encoding: 'utf-8', mode: '0666' },(err)=>{})
fs.close();