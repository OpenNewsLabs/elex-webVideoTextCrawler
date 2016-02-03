require 'ruby2js'
# ruby open file
fileR = File.open("timecode.rb", "r+")
p fileR.read
# do conversion
jsConversion =Ruby2JS.convert(fileR.read)

File.open("timecode.js", 'w') { |file| file.write(Ruby2JS.convert(fileR.read)) }
