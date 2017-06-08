package com.photoeditorsdk.cordova;

import android.app.Activity;
import android.content.Intent;
import android.media.MediaScannerConnection;
import android.net.Uri;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;

import ly.img.android.PESDK;
import ly.img.android.ui.activities.CameraPreviewActivity;

public class PESDKPlugin extends CordovaPlugin {

    private CallbackContext callback = null;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        
        PESDK.init(cordova.getActivity().getApplication(), "LICENSE_ANDROID");
    }
    
    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {
        if (action.equals("present")) {
            // Extract image path
            JSONObject options = data.getJSONObject(0);
            filepath = options.getString("path");

            Activity activity = this.cordova.getActivity();
            activity.runOnUiThread(this.present(activity, filepath, callbackContext));
            return true;
        } else {
            return false;
        }
    }

    private Runnable present(final Activity mainActivity, String filepath final CallbackContext callbackContext) {
        final PESDKPlugin self = this;
        return new Runnable() {
            public void run() {
                if (getCurrentActivity() != null) {
                    SettingsList settingsList = new SettingsList();
                    settingsList
                        .getSettingsModel(EditorLoadSettings.class)
                        .setImageSourcePath(filepath, true) // Load with delete protection true!
                        .getSettingsModel(EditorSaveSettings.class)
                        .setExportDir(Directory.DCIM, "test")
                        .setExportPrefix("result_")
                        .setSavePolicy(
                            EditorSaveSettings.SavePolicy.KEEP_SOURCE_AND_CREATE_ALWAYS_OUTPUT
                        );

                    new PhotoEditorBuilder(getCurrentActivity())
                            .setSettingsList(settingsList)
                            .startActivityForResult(getCurrentActivity(), PESDK_EDITOR_RESULT);
                }
            }
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, android.content.Intent data) {
        if (requestCode == CameraActivity.PESDK_EDITOR_RESULT) {
            switch (resultCode){
                case Activity.RESULT_OK:
                    success(data);
                    break;
                case Activity.RESULT_CANCELED:
                    callback.error(""); // empty string signals cancellation
                    break;
                case CameraActivity.PERMISSION_DENIED:
                    callback.error("Permission denied.");
                    break;
                default:
                    callback.error("Media error (code " + resultCode + ")");
                    break;
            }
        }
    }

    private void success(Intent data) {
        String path = data.getStringExtra(CameraPreviewActivity.RESULT_IMAGE_PATH);

        File mMediaFolder = new File(path);

        MediaScannerConnection.scanFile(cordova.getActivity().getApplicationContext(),
                new String[]{mMediaFolder.getAbsolutePath()},
                null,
                new MediaScannerConnection.OnScanCompletedListener() {
                    public void onScanCompleted(String path, Uri uri) {
                        if (uri == null) {
                            callback.error("Media saving failed.");
                        } else {
                            try {
                                JSONObject json = new JSONObject();
                                json.put("url", Uri.fromFile(new File(path)));
                                callback.success(json);
                            } catch (Exception e) {
                                callback.error(e.getMessage());
                            }
                        }
                    }
                }
        );
    }

}
