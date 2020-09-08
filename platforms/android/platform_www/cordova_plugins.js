cordova.define('cordova/plugin_list', function(require, exports, module) {
  module.exports = [
    {
      "id": "cordova-plugin-android-permissions.Permissions",
      "file": "plugins/cordova-plugin-android-permissions/www/permissions.js",
      "pluginId": "cordova-plugin-android-permissions",
      "clobbers": [
        "cordova.plugins.permissions"
      ]
    },
    {
      "id": "cordova-plugin-photoeditorsdk.PESDK",
      "file": "plugins/cordova-plugin-photoeditorsdk/www/photoeditorsdk.js",
      "pluginId": "cordova-plugin-photoeditorsdk",
      "clobbers": [
        "PESDK"
      ]
    }
  ];
  module.exports.metadata = {
    "cordova-plugin-android-permissions": "1.0.2",
    "cordova-plugin-whitelist": "1.3.4",
    "cordova-plugin-photoeditorsdk": "1.0.0"
  };
});