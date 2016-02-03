# elex-webVideoTextCrawler

Converts [elex][elexSource] data to srt file (subtitle file).

This is then to be used as a HTML5 video track.
With video js live streaming could be supported.  And video js captions plugin roll-on mode would make it resemble tv text crowlers. 

(For more on HTML5 video text track see)[HTML5RocksVideo].

## to use 

```
npm start yourJsonFile.json
```

if you want to try out the example.
```
npm start ./test/results.json
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

<!--  -->

[subtitles-parser ]:https://www.npmjs.com/package/subtitles-parser 
[node-timecodes]: https://www.npmjs.com/package/node-timecodes