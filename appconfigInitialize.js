var timeout = 10000; 
var initializedSuccess = false;
var appconfig = require('nconf-appconfig');

//App Configuration uses entity id to evaluate the properties. Format the key with entity id to pass to App Configuration SDK
function formatKey(inputKey, inputEntityId) {
	key = {"key":inputKey,"entityid":inputEntityId}
	return key;
}

//Based on the network initialization may take few seconds.  Use promise to wait for the initialization before getting the properties
function isInitialized() {
    var start = Date.now();
    return new Promise(waitForInitialization);
 
    function waitForInitialization(resolve, reject) {
        if (appconfig.isInitialized()) {
            resolve(initializedSuccess);
        }
        else if (timeout && (Date.now() - start) >= timeout)
            reject(new Error("timeout"));
        else
            setTimeout(waitForInitialization.bind(this, resolve, reject), 30);
    }
}

//Initialize nconf-appconfig
nconf.use('appconfig', { region: process.env.REGION, guid: process.env.GUID, apikey: process.env.APIKEY, collectionId: process.env.COLLECTION_ID, environmentId: process.env.ENVIRONMENT_ID, debug: false });

module.exports = {
    isInitialized, formatKey
}