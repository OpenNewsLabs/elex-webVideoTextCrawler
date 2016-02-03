/**
* Parses Elex json into array of segments, that follow specs of srt parser/composer
[{
    id: '1',
    startTime: 2000,
    endTime: 6000,
    text:  CandidateLastName State numberOfVotes
},
{
    id: '2',
    startTime: 28967,
    endTime: 5430958,
    text:  CandidateLastName State numberOfVotes
}]
*/

var timeInterval = 10; // in seconds
var startTime =0;
var endTime;

function convert(dataJson,cb){
	
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

	if(cb){cb(srtDataStructure)}
	return srtDataStructure;
}



module.exports = {
  convert: function(dataJson,cb) {
    return convert(dataJson,cb);
  }
}




// module.exports = {
// 		convertToOgg : function(src, outputName, callback){
// 		return convertToOgg(src, outputName, callback);
// 	}//,
// };

