# elex-webVideoTextCrawler

Converts [elex][elexSource] data to a text crawler for HTML5 Video.
It converts into a plain text file.
Alternatevly it can also convert it to a vtt file (subtitle file).

If using the vtt file, it can be used as a HTML5 video track.
With [video js][videoJs] live streaming could be supported.  And video js captions plugin roll-on mode would make it resemble tv text crowlers. 

Another option is to do some CSS Styling on the VTT track element, to animate the scroll.

(For more on HTML5 video text track see)[HTML5RocksVideo].

## Example

For the porpouse of the example, in `./HTML5VideoExample` a plain text is used, and loaded into to `marquee` tag to have animated scroll below the video.

For more on marquee tag see [here][marquee]

## How it works

Given an elex results json file`test/results.json`, `index.js` creates a plain text file. This plain text file that contains the info of the candiates last name, state and vote count. 

### Other options (vtt)

From line 29 to 54, the code to export as vtt file(subtitle tiel) is commented out. 
Uncomment that code to export as vtt. 

When exporting with vtt, to obtain the text crawler effect it's necessary to play a round with CSS tags on the vtt file. 

## How to use 

```
npm start yourJsonFileWithPath.json
```

if you want to try out the example.
```
npm start ./test/results.json
```

This generates `results.json.txt`

### Run the example

To try it in the example you can move this to the example folder

```
mv ./test/results.json.txt /HTML5VideoExample/results.json.txt
```

to run the example you need to start a server in the directory `HTML5VideoExample`. 
cd into that directory and run a server like `python -m SimpleHTTPServer 8080`. 

Navigate to [`http://localhost:8080`](http://localhost:8080) in your browser, and you should see the example. 

default example can also be viewed [here][example]

## Design 
The parsing of elext json has been abstracted into a separate component, in order to allow flexibility to implement conversion to srt of other types of jsons. 

## dependencies 
run `npm init` from root of project to install dependencies. 

Here is a list of dependencies that will be installed locally and are required by the proejct 

- [subtitles-parser][subtitles-parser ]
- [node-timecodes][node-timecodes]


<!-- 
## github page
github page done using HTML5VideoExample folder

```
git subtree push --prefix HTML5VideoExample origin gh-page
```
 -->

<!-- Links -->

[elexSource]: https://source.opennews.org/en-US/articles/introducing-elex-tool-make-election-coverage-bette/
[HTML5RocksVideo]: http://www.html5rocks.com/en/tutorials/track/basics/
[videoJs]: http://videojs.com/

<!--  -->

[subtitles-parser ]:https://www.npmjs.com/package/subtitles-parser 
[node-timecodes]: https://www.npmjs.com/package/node-timecodes

[marquee]: http://www.tutorialspoint.com/html/html_marquee_tag.htm

[example]: https://opennewslabs.github.io/elex-webVideoTextCrawler/