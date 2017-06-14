package com.photoeditorsdk.cordova;

import android.app.Activity;
import android.os.Bundle;

import ly.img.android.sdk.models.constant.Directory;
import ly.img.android.sdk.models.state.EditorLoadSettings;
import ly.img.android.sdk.models.state.EditorSaveSettings;
import ly.img.android.sdk.models.state.manager.SettingsList;
import ly.img.android.ui.activities.CameraPreviewBuilder;
import ly.img.android.ui.utilities.PermissionRequest;

/**
 * Created by maltebaumann on 06/14/17.
 */

public class CameraActivity extends Activity implements PermissionRequest.Response {

    public static final String FOLDER = "PESDK";
    public static final int CAMERA_PREVIEW_RESULT = 1;
    public static final int PERMISSION_DENIED = 1;

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        SettingsList settingsList = new SettingsList();
            settingsList.getSettingsModel(EditorLoadSettings.class)
                .getSettingsModel(EditorSaveSettings.class)
                .setExportDir(Directory.DCIM, FOLDER)
                .setExportPrefix("result_")
                .setSavePolicy(
                        EditorSaveSettings.SavePolicy.KEEP_SOURCE_AND_CREATE_ALWAYS_OUTPUT
                );

            new CameraPreviewBuilder(this)
                .setSettingsList(settingsList)
                .startActivityForResult(this, CAMERA_PREVIEW_RESULT);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, android.content.Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == CAMERA_PREVIEW_RESULT) {
            setResult(resultCode, data);
            finish();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        PermissionRequest.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    public void permissionGranted() {
    }

    public void permissionDenied() {
        setResult(PERMISSION_DENIED);
        finish();
    }
}
