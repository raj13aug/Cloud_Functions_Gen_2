
const functions = require('@google-cloud/functions-framework');
 
functions.cloudEvent('fileStorageAlert', (cloudevent) => {
  console.log("cloud storage event");
  console.log(cloudevent);
});