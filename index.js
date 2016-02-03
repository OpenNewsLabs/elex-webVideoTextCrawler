var fs = require("fs");
var parser = require('subtitles-parser');
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
* convert Elex json into srt data structure and write to file
*/

elexCrawler.convert(dataJson,function(resp){
	writeSRTFile(resp);
});


/**
* Write to SRT
*/
function writeSRTFile(srtDataStructure){
	var dataSrt = parser.toSrt(srtDataStructure);
	// console.log(dataSrt);

	fs.writeFile(fileName+".srt", dataSrt, "utf8", function(){
		console.log("finished writing srt file: "+fileName+".srt");
	})
}
