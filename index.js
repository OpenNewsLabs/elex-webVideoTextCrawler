var fs = require("fs");
var parser = require('subtitles-parser');
var vttParser=require('./vtt-composer')
var timecodes = require('node-timecodes');
/**
* module to parse elex json and convert into srt subtitles-parser data structure (array of segments).
* It could be replaced with another module to convert a different type of json into srt subtitles-parser data structure (array of segments) if not working with Elex.
*/
var elexCrawler= require('./elexToTextCrawlerSegments')

var fileName = process.argv[2];
//TODO: add some validation
	// arg 2 needs to exist
	// arg 2 needs to be json file
	// arg 2 could be csv file?

/**
* Opening file
*/
var data = fs.readFileSync(fileName);
console.log("opened file")
/**
* Parsing json 
*/
var dataJson = JSON.parse(data);
console.log("parsed json")
//TODO: add support for CSV?

/**
* convert Elex json into vtt data structure and write to file
*/
// elexCrawler.convert(dataJson,function(resp){
// 	writeVTTile(resp);
// });

/**
* convert Elex json into text data structure and write to file
*/
elexCrawler.convert(dataJson,function(resp){
	writeTextFile(resp);
});


/**
* Write to VTT File
*/
// function writeVTTile(vttDataStructure){
// 	// var dataSrt = parser.toSrt(vttDataStructure);
// 	var dataVTT = vttParser.toVtt(vttDataStructure);

// 	fs.writeFile(fileName+".vtt", dataVTT, "utf8", function(){
// 		console.log("finished writing vtt file: "+fileName+".vtt");
// 	})
// }


/**
* Write to plain text file
*/
function writeTextFile(vttDataStructure){
	dataTxt="Elections Results ...    ";
	for(var i =0;i< vttDataStructure.length ; i++){
		dataTxt+=vttDataStructure[i].text+"  | ";
	}

	fs.writeFile(fileName+".txt", dataTxt, "utf8", function(){
		console.log("finished writing plain file: "+fileName+".txt");
	});
}
