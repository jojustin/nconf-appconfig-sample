require('dotenv').config();
const express = require('express');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const path = require('path');
var bunyan = require('bunyan');
var EventEmitter = require('events');
var request = require('request');
var nconf = require('nconf');
var appconfigInit = require('./appconfigInitialize'); 


const app = express();
// view engine setup
app.set('views', path.join(__dirname, 'public'));
app.engine('html', require('ejs').renderFile);

app.set('view engine', 'html');
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
var predictAgeUrl;
var entityId = "dummyuser";

appconfigInit.isInitialized().then(function(){
	console.log("IBM Cloud App Configuration is initialized")
	//load global properties
	//Use nconf.get to retrieve the property defined in IBM Cloud App Configuration
	predictAgeProtocol = nconf.get(appconfigInit.formatKey('predict-age-protocol',entityId))
	predictAgeHost = nconf.get(appconfigInit.formatKey('predict-age-host',entityId))
	predictAgeQuery = nconf.get(appconfigInit.formatKey('predict-age-query',entityId))
	predictAgeUrl = predictAgeProtocol+"://"+predictAgeHost+"/?"+predictAgeQuery+"=";
	console.log("predictAgeUrl is " + predictAgeUrl);
});


app.get('/', (req, res) => {
	var age;
	res.render('index.html', {age});
});

app.post('/', (req, res) => {

	var age, name;
	if(req.body.name) {
		name = req.body.name
		url = predictAgeUrl + req.body.name
		request(url, function (error, response, body) {
			if (!error && response.statusCode === 200) {
				age = JSON.parse(body).age
				res.render('index.html', {name, age});
			}
		})
	}
});

app.listen(3000, () => {
	  console.log("server is running" );
	});

