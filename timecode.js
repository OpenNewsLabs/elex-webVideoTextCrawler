/** 
* Node ultimate timecode library
*/


module.exports = {
  parse: function(dataJson,cb) {
    return convert(dataJson,cb);
  }
}