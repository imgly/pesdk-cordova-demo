package com.photoeditorsdk.cordova;

import android.app.Activity;
import android.content.Intent;
import android.media.MediaScannerConnection;
import android.net.Uri;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;

import ly.img.android.PESDK;
import ly.img.android.pesdk.assets.filter.basic.FilterPackBasic;
import ly.img.android.pesdk.assets.font.basic.FontPackBasic;
import ly.img.android.pesdk.assets.frame.basic.FramePackBasic;
import ly.img.android.pesdk.assets.overlay.basic.OverlayPackBasic;
import ly.img.android.pesdk.assets.sticker.emoticons.StickerPackEmoticons;
import ly.img.android.pesdk.assets.sticker.shapes.StickerPackShapes;
import ly.img.android.pesdk.backend.model.constant.Directory;
import ly.img.android.pesdk.backend.model.state.CameraSettings;
import ly.img.android.pesdk.backend.model.state.EditorLoadSettings;
import ly.img.android.pesdk.backend.model.state.EditorSaveSettings;
import ly.img.android.pesdk.backend.model.state.manager.SettingsList;
import ly.img.android.pesdk.ui.activity.ImgLyIntent;
import ly.img.android.pesdk.ui.activity.PhotoEditorBuilder;
import ly.img.android.pesdk.ui.model.state.UiConfigFilter;
import ly.img.android.pesdk.ui.model.state.UiConfigFrame;
import ly.img.android.pesdk.ui.model.state.UiConfigOverlay;
import ly.img.android.pesdk.ui.model.state.UiConfigSticker;
import ly.img.android.pesdk.ui.model.state.UiConfigText;

public class PESDKPlugin extends CordovaPlugin {

    public static final int PESDK_EDITOR_RESULT = 1;
    private CallbackContext callback = null;

    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {
        if (action.equals("present")) {
            // Extract image path
            JSONObject options = data.getJSONObject(0);
            String filepath = options.optString("path", "");

            Activity activity = this.cordova.getActivity();
            activity.runOnUiThread(this.present(activity, filepath, callbackContext));
            return true;
        } else {
            return false;
        }
    }

    private Runnable present(final Activity mainActivity, final String filepath, final CallbackContext callbackContext) {
        callback = callbackContext;
        final PESDKPlugin self = this;
        return new Runnable() {
            public void run() {
                if (mainActivity != null && filepath.length() > 0) {
                    SettingsList settingsList = createPesdkSettingsList();
                    settingsList
                        .getSettingsModel(EditorLoadSettings.class)
                        .setImageSourcePath(filepath.replace("file://", ""), true) // Load with delete protection true!
                        .getSettingsModel(EditorSaveSettings.class)
                        .setExportDir(Directory.DCIM, "test")
                        .setExportPrefix("result_")
                        .setSavePolicy(
                            EditorSaveSettings.SavePolicy.KEEP_SOURCE_AND_CREATE_ALWAYS_OUTPUT
                        );

                    cordova.setActivityResultCallback(self);
                    new PhotoEditorBuilder(mainActivity)
                            .setSettingsList(settingsList)
                            .startActivityForResult(mainActivity, PESDK_EDITOR_RESULT);
                } else {
                    // Just open the camera
                    Intent intent = new Intent(mainActivity, CameraActivity.class);
                    callback = callbackContext;
                    cordova.startActivityForResult(self, intent, PESDK_EDITOR_RESULT);
                }
            }
        };
    }

    private SettingsList createPesdkSettingsList() {
        SettingsList settingsList = new SettingsList();
        settingsList.getSettingsModel(UiConfigFilter.class).setFilterList(
                FilterPackBasic.getFilterPack()
        );
        settingsList.getSettingsModel(UiConfigText.class).setFontList(
                FontPackBasic.getFontPack()
        );
        settingsList.getSettingsModel(UiConfigFrame.class).setFrameList(
                FramePackBasic.getFramePack()
        );
        settingsList.getSettingsModel(UiConfigOverlay.class).setOverlayList(
                OverlayPackBasic.getOverlayPack()
        );
        settingsList.getSettingsModel(UiConfigSticker.class).setStickerLists(
                StickerPackEmoticons.getStickerCategory(),
                StickerPackShapes.getStickerCategory()
        );

        settingsList.getSettingsModel(CameraSettings.class)
                .setExportDir(Directory.DCIM, "SomeFolderName")
                .setExportPrefix("camera_");
        settingsList.getSettingsModel(EditorSaveSettings.class)
                .setExportDir(Directory.DCIM, "SomeFolderName")
                .setExportPrefix("result_")
                .setSavePolicy(EditorSaveSettings.SavePolicy.RETURN_ALWAYS_ONLY_OUTPUT);

        return settingsList;
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, android.content.Intent data) {
        if (requestCode == PESDK_EDITOR_RESULT) {
            switch (resultCode){
                case Activity.RESULT_OK:
                    success(data);
                    break;
                case Activity.RESULT_CANCELED:
                    callback.error(""); // empty string signals cancellation
                    break;
                default:
                    callback.error("Media error (code " + resultCode + ")");
                    break;
            }
        }
    }

    private void success(Intent data) {
        String path = data.getStringExtra(ImgLyIntent.RESULT_IMAGE_PATH);

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
