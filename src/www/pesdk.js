var PESDK = {
  present: function(success, failure, options) {
    console.log("Present:");
    console.log(options);
    cordova.exec(success, failure, "PESDK", "present", [options]);
  }
};
module.exports = PESDK;
