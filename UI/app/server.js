var fs = require("fs");
const shell = require('shelljs');
const express = require('express');
const bodyParser = require('body-parser');
const formidable = require('formidable');


const app = express();
const delete_file = function(fileName) {
   fs.unlink(fileName, function (err) {
      if (err) console.log(err);
      console.log(`${fileName} successfully deleted!`);
   })
}

app.use(express.static('public'));
app.use(bodyParser.urlencoded({ extended: false }));

app.get('/', function (req, res) {
   res.sendFile( `${__dirname}/index.html`);
})

app.post('/video_upload', function (req, res) {
   
   var form = new formidable.IncomingForm();
   form.parse(req, function (err, fields, files) {
      var oldpath = files.video.path;
      var newpath = __dirname + "/" + files.video.name;
      delete_file(newpath)

      fs.readFile(oldpath, function (err, data) {
         if (err) console.log(err);
         fs.writeFile(newpath, data, function (err) {
            if (err) console.log(err);
            shell.exec(`${__dirname}/scripts/analyzeVideo.sh ${newpath}`);
            
            var transcript = fs.readFileSync(`${__dirname}/scripts/results/transcripts.txt`);
            res.write('<div style="text-align: center" width="10">')
            res.write('<img src="images/logo.jpg" alt="logo" style="width:500px;height:300px">')
            res.write('</div>')
            
            res.write('<h1>Video Transcript</h1>')
            res.write(transcript.toString());

            res.write('<h1>Visual Tags</h1>')
            var counter = 1
            while(fs.existsSync(`${__dirname}/scripts/results/${counter}.tags`)) {
               res.write(`<h2>Second ${counter}</h2>`)
               res.write('<ul>')
               fs.readFileSync(`${__dirname}/scripts/results/${counter}.tags`).toString().split("\n").forEach(function(line, index, arr) {
                  if (index === arr.length - 1 && line === "") { return; }
                  res.write(`<li>${line}</li>`);
               });
               res.write('</ul>')
               counter++;
            }            

            res.end();
         });

         // Delete the file
         delete_file(oldpath)
     });
   });
})

var server = app.listen(8081, function () {
   var host = server.address().address
   var port = server.address().port
   
   console.log(`Example app listening at http://${host}:${port}`)
})
