var fs = require("fs");
var parser = require('subtitles-parser');
var timecodes = require('node-timecodes');
var timeInterval = 10; // in seconds
var startTime =0;
var endTime;

var fileName = process.argv[2];
//add some validation
	// arg 2 needs to exist
	//needs to be json file

console.log("opening " + fileName);
// console.log()



var data = fs.readFileSync(fileName);

var dataJson = JSON.parse(data);


/**
* srt data structure 
*/
var srtDataStructure = []
for(var i = 0; i<dataJson.length; i++ ){
	
		var segment = {};
		segment.id = i+1;
		segment.startTime = startTime;
		startTime+= timeInterval;
		endTime = startTime;
		segment.endTime = endTime;


	
		if(dataJson[i].last!= null && dataJson[i].last!= undefined && dataJson[i].last != "Other" ){
			
				segment.text  = dataJson[i].last+" "+ dataJson[i].statename+" "+dataJson[i].votecount;
			srtDataStructure.push(segment);	
		}
		// console.log(dataJson[i].first);
		// console.log(dataJson[i].last);
		// console.log(dataJson[i].statename);
		// console.log("Party: " + dataJson[i].party);
		// console.log("Votes: "+ dataJson[i].votecount);
		
	
	
}

console.log(srtDataStructure);

/**
* Write to SRT
*/
var dataSrt = parser.toSrt(srtDataStructure);
console.log(dataSrt);

fs.writeFile(fileName+".srt", dataSrt, "utf8", function(){
	console.log("finished exporting");
})