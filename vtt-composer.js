/*
* Basic json to vtt conversion
*/
var timecodes = require('node-timecodes');

function convert(vttDataStructure,cb){
	var vttString = "WEBVTT\n\n"
	for(var i = 0; i< vttDataStructure.length; i++){

		vttString+=vttDataStructure[i].id+"\n"+fromSecondsWithDot(vttDataStructure[i].startTime)+" --> "+fromSecondsWithDot(vttDataStructure[i].endTime)+"\n"+vttDataStructure[i].text+"\n\n"
	}
	if(cb){cb(vttString)}
	return vttString;
}


 function fromSecondsWithDot(val) {
        var measures = [ 3600000, 60000, 1000 ]; 
        var time = [];

        for (var i in measures) {
            var res = (val / measures[i] >> 0).toString();
            
            if (res.length < 2) res = '0' + res;
            val %= measures[i];
            time.push(res);
        }

        var ms = val.toString();
        if (ms.length < 3) {
            for (i = 0; i <= 3 - ms.length; i++) ms = '0' + ms;
        }

        return time.join(':') + '.' + ms;
    };


module.exports = {
  toVtt: function(dataJson,cb) {
    return convert(dataJson,cb);
  }
}