/**
* Parses Elex json into array of segments, that follow specs of srt parser node module
* ie 
[ ...
  { id: 1798,
    startTime: 8985000,
    endTime: 8990000,
    text: 'Santorum Iowa 3' },
  { id: 1799,
    startTime: 8990000,
    endTime: 8995000,
    text: 'Gilmore Iowa 0' } ]

*/

/**
* if using vtt, this sets subtitle time Interval in between text subtitles entries.
*/
var timeInterval = 5000; // in milli seconds
var startTime =0;
var endTime;

/**
* Converts json from elect into vttData structure. 
*/
function convert(dataJson,cb){

	var vttDataStructure = []

	for(var i = 0; i<dataJson.length; i++ ){
			var segment = {};
			segment.id = i+1;
			segment.startTime = startTime;
			startTime+= timeInterval;
			endTime = startTime;
			segment.endTime = endTime;
			
			if(dataJson[i].last!= null && dataJson[i].last!= undefined && dataJson[i].last != "Other" && dataJson[i].last != "Uncommitted"){				
					segment.text  = dataJson[i].last+" "+ dataJson[i].statename+" "+dataJson[i].votecount;
				vttDataStructure.push(segment);	
			}	
	}

	console.log(vttDataStructure)
	if(cb){cb(vttDataStructure)}
	return vttDataStructure;
}



module.exports = {
  convert: function(dataJson,cb) {
    return convert(dataJson,cb);
  }
}
