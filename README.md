# elex-webVideoTextCrawler

Converts [elex][elexSource] data to text crawler for HTML5 Video.
It converts into a plain text file (and/or vtt file (subtitle file) ).

If using the vtt file this can be then to be used as a HTML5 video track.
With [video js][videoJs] live streaming could be supported.  And video js captions plugin roll-on mode would make it resemble tv text crowlers. 

another option is do some CSS Styling on the VTT track element, to animate the scroll.

(For more on HTML5 video text track see)[HTML5RocksVideo].

## Example

For the porpouse of the example, in `./HTML5VideoExample` a plain text is used, and loaded into to `marquee` tag to have animated scroll below the video.

more on marquee tag [here][marquee]

## How it works

Given an elex results json file, `index.js`, creates a  plain text file. This plain text file contains the info of the candiates and


### Other options

## to use 

```
npm start yourJsonFileWithPath.json
```

if you want to try out the example.
```
npm start ./test/results.json
```

This generates `results.json.txt`

To try the example you can move this to the example folder

```
mv ./test/results.json.txt /HTML5VideoExample/results.json.txt
```




## Design 
The parsing of elext json has been abstracted into a separate component, in order to allowe flexibility to implement conversion to srt of other types of jsons. 

## dependencies 
run `npm init` from root of project to install dependencies. 

Here is a list of dependencies that will be installed locally and are required by the proejct 

- [subtitles-parser][subtitles-parser ]
- [node-timecodes][node-timecodes]


<!-- Links -->

[elexSource]: https://source.opennews.org/en-US/articles/introducing-elex-tool-make-election-coverage-bette/
[HTML5RocksVideo]: http://www.html5rocks.com/en/tutorials/track/basics/
[videoJs]: http://videojs.com/

<!--  -->

[subtitles-parser ]:https://www.npmjs.com/package/subtitles-parser 
[node-timecodes]: https://www.npmjs.com/package/node-timecodes

[marquee]: http://www.tutorialspoint.com/html/html_marquee_tag.htm