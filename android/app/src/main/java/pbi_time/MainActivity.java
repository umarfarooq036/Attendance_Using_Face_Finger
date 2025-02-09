////package pbi_time;
////
////
////import androidx.annotation.NonNull;
////
////import io.flutter.embedding.android.FlutterActivity;
////import io.flutter.embedding.engine.FlutterEngine;
////import io.flutter.plugin.common.MethodChannel;
////
////import android.Manifest;
////import android.app.PendingIntent;
////import android.content.BroadcastReceiver;
////import android.content.Context;
////import android.content.Intent;
////import android.content.IntentFilter;
////import android.content.pm.PackageManager;
////import android.graphics.Bitmap;
////import android.hardware.usb.UsbDevice;
////import android.hardware.usb.UsbManager;
////import android.os.Build;
////import android.os.Bundle;
////import android.util.Base64;
////import android.util.Log;
////import android.widget.Toast;
////
////import java.io.ByteArrayOutputStream;
////
////import com.zkteco.android.biometric.FingerprintExceptionListener;
////import com.zkteco.android.biometric.core.device.ParameterHelper;
////import com.zkteco.android.biometric.core.device.TransportType;
////import com.zkteco.android.biometric.core.utils.ToolUtils;
////import com.zkteco.android.biometric.module.fingerprintreader.FingerprintCaptureListener;
////import com.zkteco.android.biometric.module.fingerprintreader.FingerprintSensor;
////import com.zkteco.android.biometric.module.fingerprintreader.FingprintFactory;
////import com.zkteco.android.biometric.module.fingerprintreader.ZKFingerService;
////import com.zkteco.android.biometric.module.fingerprintreader.exception.FingerprintException;
////
////import java.util.HashMap;
////import java.util.Map;
////
////public class MainActivity extends FlutterActivity {
////
////    private static final String CHANNEL = "zkfingerprint_channel";
////    private static final String TAG = "MainActivity";
////    private static final String USB_PERMISSION_ACTION = "com.example.channel_practice.USB_PERMISSION";
////
////    private static final int ZKTECO_VID = 0x1b55;
////    private static final int ZK9500_PID = 0x0124;
////    private final static int ENROLL_COUNT = 3;
////    private FingerprintSensor fingerprintSensor;
////    private boolean bStarted = false;
////    private int deviceIndex = 0;
////    private boolean isReseted = false;
////    private final FingerprintExceptionListener fingerprintExceptionListener = () -> {
//////        Log.e(TAG, "Fingerprint device exception");
////        if (!isReseted) {
////            try {
////                fingerprintSensor.openAndReboot(deviceIndex);
////            } catch (FingerprintException e) {
////                e.printStackTrace();
////            }
////            isReseted = true;
////        }
////    };
////    private String strUid = null;
////    private int enroll_index = 0;
////    private byte[][] regtemparray = new byte[3][2048];
////    private boolean bRegister = false;
////    private DBManager dbManager;
////    private final FingerprintCaptureListener fingerprintCaptureListener = new FingerprintCaptureListener() {
////        @Override
////        public void captureOK(byte[] fpImage) {
////            // Convert the fingerprint image to a bitma
////            final Bitmap bitmap = ToolUtils.renderCroppedGreyScaleBitmap(fpImage, fingerprintSensor.getImageWidth(), fingerprintSensor.getImageHeight());
////
////            // Run the Flutter method call on the main thread
////            runOnUiThread(() -> {
////                try {
////                    // Convert the bitmap to a byte array to send to Flutter
////                    ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
////                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
////                    byte[] byteArray = byteArrayOutputStream.toByteArray();
////
////                    // Invoke the Flutter method to send the image data
////                    new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
////                            .invokeMethod("updateImage", byteArray);
////                } catch (Exception e) {
//////                    Log.e(TAG, "Failed to send image to Flutter", e);
////                }
////            });
////        }
////
////
////        @Override
////        public void captureError(FingerprintException e) {
//////            Log.e(TAG, "Capture error: " + e.getMessage());
////        }
////
////        @Override
////        public void extractOK(byte[] fpTemplate) {
////            if (bRegister) {
////                doRegister(fpTemplate);
////            } else {
////                doIdentify(fpTemplate);
////            }
////        }
////
////        @Override
////        public void extractError(int errorCode) {
//////            Log.e(TAG, "Extract error code: " + errorCode);
////        }
////    };
////    private final BroadcastReceiver usbPermissionReceiver = new BroadcastReceiver() {
////        @Override
////        public void onReceive(Context context, Intent intent) {
////            if (USB_PERMISSION_ACTION.equals(intent.getAction())) {
////                synchronized (this) {
////                    UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
////                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
////                        if (device != null) {
////                            openDevice();
////                        }
////                    } else {
////                        showToast("USB Permission Denied");
////                    }
////                }
////            }
////        }
////    };
////    private UsbDevice usbDevice;
////    private MethodChannel methodChannel;
////
////    @Override
////    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
////        super.configureFlutterEngine(flutterEngine);
////
////        dbManager = new DBManager(this, "zkfinger10.db");
////        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
////
////        methodChannel.setMethodCallHandler((call, result) -> {
////            switch (call.method) {
////                case "startCapture":
////                    startCapture();
////                    result.success("Capture started");
////                    break;
////                case "stopCapture":
////                    stopCapture();
////                    result.success("Capture stopped");
////                    break;
////                case "registerUser":
////                    String userId = call.argument("userId");
////                    result.success(registerUser(userId));
////                    break;
////                case "identifyUser":
////                    result.success(identifyUser());
////                    break;
////                case "deleteUser":
////                    String deleteUserId = call.argument("userId");
////                    result.success(deleteUser(deleteUserId));
////                    break;
////                case "clearAllUsers":
////                    result.success(clearAllUsers());
////                    break;
////                case "getStoredTemplates":
////                    Map<String, String> storedTemplates = dbManager.queryUserList();
////                    result.success(storedTemplates);
////                    break;
////                default:
////                    result.notImplemented();
////                    break;
////            }
////        });
////    }
////
////    @Override
////    protected void onCreate(Bundle savedInstanceState) {
////        super.onCreate(savedInstanceState);
////        checkStoragePermission();
////
////        IntentFilter filter = new IntentFilter(USB_PERMISSION_ACTION);
////        registerReceiver(usbPermissionReceiver, filter);
////    }
////
////    private void startCapture() {
////        if (bStarted) {
////            showToast("Capture already started");
////            return;
////        }
////        if (!enumSensor()) {
////            showToast("Device not found!");
////            return;
////        }
////
////        UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
////        if (usbManager.hasPermission(usbDevice)) {
////            openDevice();
////        } else {
////            PendingIntent permissionIntent = PendingIntent.getBroadcast(this, 0, new Intent(USB_PERMISSION_ACTION), PendingIntent.FLAG_IMMUTABLE);
////            usbManager.requestPermission(usbDevice, permissionIntent);
////        }
////    }
////
////    private void stopCapture() {
////        if (!bStarted) {
////            showToast("Device not connected!");
////            return;
////        }
////        closeDevice();
////        showToast("Device closed!");
////    }
////
////    private String registerUser(String userId) {
////        if (!bStarted) return "Start capture first";
////        strUid = userId;
////        if (strUid == null || strUid.isEmpty()) return "Invalid User ID";
////
////        if (dbManager.isUserExist(strUid)) {
////            return "User already registered";
////        }
////        bRegister = true;
////        enroll_index = 0;
////        return "Please press your finger 3 times.";
////    }
////
////    private String identifyUser() {
////        if (!bStarted) return "Start capture first";
////        bRegister = false;
////        enroll_index = 0;
////        return "Identification started";
////    }
////
////    private String deleteUser(String userId) {
////        if (!bStarted) return "Start capture first";
////        strUid = userId;
////        if (strUid == null || strUid.isEmpty()) return "Invalid User ID";
////
////        if (!dbManager.isUserExist(strUid)) {
////            return "User not registered";
////        }
////
////        dbManager.deleteUser(strUid);
////        ZKFingerService.del(strUid);
////        return "User deleted successfully";
////    }
////
////    private String clearAllUsers() {
////        if (!bStarted) return "Start capture first";
////        dbManager.clear();
////        ZKFingerService.clear();
////        return "All users cleared";
////    }
////
////    private void openDevice() {
////        createFingerprintSensor();
////        bRegister = false;
////        enroll_index = 0;
////        isReseted = false;
////        try {
////            fingerprintSensor.open(deviceIndex);
////            loadAllTemplatesFromDB();
////            fingerprintSensor.setFingerprintCaptureListener(deviceIndex, fingerprintCaptureListener);
////            fingerprintSensor.SetFingerprintExceptionListener(fingerprintExceptionListener);
////            fingerprintSensor.startCapture(deviceIndex);
////            bStarted = true;
////            showToast("Device connected successfully");
////        } catch (FingerprintException e) {
////            e.printStackTrace();
////            showToast("Device connection failed");
////        }
////    }
////
////    private void closeDevice() {
////        if (bStarted) {
////            try {
////                fingerprintSensor.stopCapture(deviceIndex);
////                fingerprintSensor.close(deviceIndex);
////            } catch (FingerprintException e) {
////                e.printStackTrace();
////            }
////            bStarted = false;
////        }
////    }
////
////    private void createFingerprintSensor() {
////        if (fingerprintSensor != null) {
////            FingprintFactory.destroy(fingerprintSensor);
////            fingerprintSensor = null;
////        }
////        Map<String, Object> params = new HashMap<>();
////        params.put(ParameterHelper.PARAM_KEY_VID, ZKTECO_VID);
////        params.put(ParameterHelper.PARAM_KEY_PID, ZK9500_PID);
////        fingerprintSensor = FingprintFactory.createFingerprintSensor(getApplicationContext(), TransportType.USB, params);
////    }
////
////    private boolean enumSensor() {
////        UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
////        for (UsbDevice device : usbManager.getDeviceList().values()) {
////            if (device.getVendorId() == ZKTECO_VID && device.getProductId() == ZK9500_PID) {
////                usbDevice = device;
////                return true;
////            }
////        }
////        return false;
////    }
////
////    private void doRegister(byte[] template) {
////        byte[] bufids = new byte[256];
////        int ret = ZKFingerService.identify(template, bufids, 70, 1);
////        if (ret > 0) {
////            String strRes[] = new String(bufids).split("\t");
////            showToast("Finger already enrolled by " + strRes[0] + ", canceling enrollment");
////            bRegister = false;
////            enroll_index = 0;
////            return;
////        }
////        if (enroll_index > 0 && (ret = ZKFingerService.verify(regtemparray[enroll_index - 1], template)) <= 0) {
////            showToast("Please press the same finger 3 times for enrollment, canceling enrollment");
////            bRegister = false;
////            enroll_index = 0;
////            return;
////        }
////        System.arraycopy(template, 0, regtemparray[enroll_index], 0, template.length);
////        enroll_index++;
////        if (enroll_index == ENROLL_COUNT) {
////            bRegister = false;
////            enroll_index = 0;
////            byte[] regTemp = new byte[2048];
////            if ((ret = ZKFingerService.merge(regtemparray[0], regtemparray[1], regtemparray[2], regTemp)) > 0) {
////                Log.d(TAG , "This is RET" + ret);
////
////                // Send merged template to Flutter
////                sendTemplateToFlutter(regTemp, "enrollment");
////
////                ret = ZKFingerService.save(regTemp, strUid);
////
////                if (ret == 0) {
////                    String strFeature = Base64.encodeToString(regTemp, 0, ret, Base64.NO_WRAP);
////                    Log.d(TAG, "Inserting into DB: " + strFeature);
////
////                    showToast("StrFeature: ");
////                    dbManager.insertUser(strUid, strFeature);
////                    showToast("Enrollment successful");
////                } else {
////                    showToast("Enrollment failed, error code: " + ret);
////                }
////            } else {
////                showToast("Enrollment failed during template merge");
////            }
////        } else {
////            showToast("You need to press your finger " + (ENROLL_COUNT - enroll_index) + " more times");
////        }
////    }
////
////    private void doIdentify(byte[] template) {
////        byte[] bufids = new byte[256];
////        int ret = ZKFingerService.identify(template, bufids, 70, 1);
////        // Send identification template to Flutter
////        sendTemplateToFlutter(template, "identification");
////        if (ret > 0) {
////            String strRes[] = new String(bufids).split("\t");
////            Log.d(TAG , "BufferIds Identification: "+ new String(bufids));
////            showToast("Identification successful, User ID: " + strRes[0].trim() + ", Score: " + strRes[1].trim());
////        } else {
////            showToast("Identification failed, error code: " + ret);
////        }
////    }
////
////    private void checkStoragePermission() {
////        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
////            if (checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED ||
////                    checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
////                requestPermissions(new String[]{
////                        Manifest.permission.WRITE_EXTERNAL_STORAGE,
////                        Manifest.permission.READ_EXTERNAL_STORAGE
////                }, 1);
////            }
////        }
////    }
////
////    private void loadAllTemplatesFromDB() {
////        if (dbManager.opendb() && dbManager.getCount() > 0) {
////            Map<String, String> userMap = dbManager.queryUserList();
////            for (Map.Entry<String, String> entry : userMap.entrySet()) {
////                String userId = entry.getKey();
////                String templateStr = entry.getValue();
////                byte[] template = Base64.decode(templateStr, Base64.NO_WRAP);
////                ZKFingerService.save(template, userId);
////            }
////        }
////    }
////
////    private void showToast(String message) {
////        runOnUiThread(() -> Toast.makeText(MainActivity.this, message, Toast.LENGTH_SHORT).show());
////    }
////
////    @Override
////    protected void onDestroy() {
////        super.onDestroy();
////        if (bStarted) {
////            closeDevice();
////        }
////        if (dbManager != null) {
////            dbManager.closeDB();
////        }
////        unregisterReceiver(usbPermissionReceiver);
////    }
////
////
////
////// Add these methods to your MainActivity class
////
////private void sendTemplateToFlutter(byte[] template, String type) {
////    runOnUiThread(() -> {
////        try {
////            // Convert template to Base64 string
////            String base64Template = Base64.encodeToString(template, Base64.NO_WRAP);
////
////            // Create a map to send more detailed information
////            Map<String, Object> templateData = new HashMap<>();
////            templateData.put("type", type);  // e.g., "enrollment", "identification"
////            templateData.put("base64", base64Template);
////            templateData.put("length", template.length);
////
////            // Invoke Flutter method to receive template data
////            new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
////                    .invokeMethod("updateTemplate", templateData);
////        } catch (Exception e) {
////            Log.e(TAG, "Failed to send template to Flutter", e);
////        }
////    });
////}
////}
////
/////*
////private void setResult(String result)       //this is the main function that will be used to
////// send the toast back to the flutter functions via MethodChannel of flutter
////// (now we will invoke the flutter method from java opposite got it?)
////{
////    final String mStrText = result;
////    runOnUiThread(new Runnable() {
////        @Override
////        public void run() {
////            textView.setText(mStrText);
////        }
////    });
////}
////
//// */
//
//
//package pbi_time;
//
//import androidx.annotation.NonNull;
//import io.flutter.embedding.android.FlutterActivity;
//import io.flutter.embedding.android.FlutterFragmentActivity;
//import io.flutter.embedding.engine.FlutterEngine;
//import io.flutter.plugin.common.MethodChannel;
//import pbi_time.models.CanAddFingerModel;
//import retrofit2.Call;
//import retrofit2.Callback;
//import retrofit2.Response;
//
//import android.Manifest;
//import android.app.PendingIntent;
//import android.content.BroadcastReceiver;
//import android.content.Context;
//import android.content.Intent;
//import android.content.IntentFilter;
//import android.content.pm.PackageManager;
//import android.graphics.Bitmap;
//import android.hardware.usb.UsbDevice;
//import android.hardware.usb.UsbManager;
//import android.os.Build;
//import android.os.Bundle;
//import android.util.Base64;
//import android.util.Log;
//import android.widget.Toast;
//
//import com.google.android.gms.tasks.Task;
//import com.google.firebase.FirebaseApp;
//
//import java.io.ByteArrayOutputStream;
//import java.util.HashMap;
//import java.util.List;
//import java.util.Map;
//
//// Import ZKTeco classes (same as before)
//import com.zkteco.android.biometric.FingerprintExceptionListener;
//import com.zkteco.android.biometric.core.device.ParameterHelper;
//import com.zkteco.android.biometric.core.device.TransportType;
//import com.zkteco.android.biometric.core.utils.ToolUtils;
//import com.zkteco.android.biometric.module.fingerprintreader.FingerprintCaptureListener;
//import com.zkteco.android.biometric.module.fingerprintreader.FingerprintSensor;
//import com.zkteco.android.biometric.module.fingerprintreader.FingprintFactory;
//import com.zkteco.android.biometric.module.fingerprintreader.ZKFingerService;
//import com.zkteco.android.biometric.module.fingerprintreader.exception.FingerprintException;
//
//public class MainActivity extends FlutterFragmentActivity {
//    // ... (keep all the constant declarations and private fields the same)
//    private static final String CHANNEL = "zkfingerprint_channel";
//    private static final String TAG = "MainActivity";
//    private static final String USB_PERMISSION_ACTION = "com.example.channel_practice.USB_PERMISSION";
//
//    private static final int ZKTECO_VID = 0x1b55;
//    private static final int ZK9500_PID = 0x0124;
//    private final static int ENROLL_COUNT = 3;
//    private FingerprintSensor fingerprintSensor;
//    private boolean bStarted = false;
//    private int deviceIndex = 0;
//    private boolean isReseted = false;
//    private final FingerprintExceptionListener fingerprintExceptionListener = () -> {
////        Log.e(TAG, "Fingerprint device exception");
//        if (!isReseted) {
//            try {
//                fingerprintSensor.openAndReboot(deviceIndex);
//            } catch (FingerprintException e) {
//                e.printStackTrace();
//            }
//            isReseted = true;
//        }
//    };
//    private String strUid = null;
//    private int enroll_index = 0;
//    private byte[][] regtemparray = new byte[3][2048];
//    private boolean bRegister = false;
//    private DBManager dbManager;
//    private final FingerprintCaptureListener fingerprintCaptureListener = new FingerprintCaptureListener() {
//        @Override
//        public void captureOK(byte[] fpImage) {
//            // Convert the fingerprint image to a bitmap
//            final Bitmap bitmap = ToolUtils.renderCroppedGreyScaleBitmap(fpImage, fingerprintSensor.getImageWidth(), fingerprintSensor.getImageHeight());
//
//            // Run the Flutter method call on the main thread
//            runOnUiThread(() -> {
//                try {
//                    // Convert the bitmap to a byte array to send to Flutter
//                    ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
//                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
//                    byte[] byteArray = byteArrayOutputStream.toByteArray();
//
//                    // Invoke the Flutter method to send the image data
//                    new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
//                            .invokeMethod("updateImage", byteArray);
//                } catch (Exception e) {
////                    Log.e(TAG, "Failed to send image to Flutter", e);
//                }
//            });
//        }
//
//
//        @Override
//        public void captureError(FingerprintException e) {
////            Log.e(TAG, "Capture error: " + e.getMessage());
//        }
//
//        @Override
//        public void extractOK(byte[] fpTemplate) {
//            if (bRegister) {
//                doRegister(fpTemplate);
//            } else {
//                doIdentify(fpTemplate);
//            }
//        }
//
//        @Override
//        public void extractError(int errorCode) {
////            Log.e(TAG, "Extract error code: " + errorCode);
//        }
//    };
//    private final BroadcastReceiver usbPermissionReceiver = new BroadcastReceiver() {
//        @Override
//        public void onReceive(Context context, Intent intent) {
//            if (USB_PERMISSION_ACTION.equals(intent.getAction())) {
//                synchronized (this) {
//                    UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
//                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
//                        if (device != null) {
//                            openDevice();
//                        }
//                    } else {
//                        showToast("USB Permission Denied");
//                    }
//                }
//            }
//        }
//    };
//    private UsbDevice usbDevice;
//    private MethodChannel methodChannel;
//
//    @Override
//    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
//        super.configureFlutterEngine(flutterEngine);
//
//        // Initialize Firebase
//        FirebaseApp.initializeApp(this);
//
//        // Initialize DBManager with Firebase
//        dbManager = new DBManager(this);
//        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
//
//        methodChannel.setMethodCallHandler((call, result) -> {
//            switch (call.method) {
//                case "startCapture":
//                    startCapture();
//                    result.success("Capture started");
//                    break;
//                case "stopCapture":
//                    stopCapture();
//                    result.success("Capture stopped");
//                    break;
//                case "registerUser":
//                    String userId = call.argument("userId");
//                    registerUserAsync(userId, result);
//                    break;
//                case "identifyUser":
//                    identifyUserAsync(result);
//                    break;
//                case "deleteUser":
//                    String deleteUserId = call.argument("userId");
//                    deleteUserAsync(deleteUserId, result);
//                    break;
//                case "clearAllUsers":
//                    clearAllUsersAsync(result);
//                    break;
//                case "getStoredTemplates":
//                    getStoredTemplatesAsync(result);
//                    break;
//                default:
//                    result.notImplemented();
//                    break;
//            }
//        });
//    }
//
//    // Modified methods to handle async Firebase operations
//
//    private void registerUserAsync(String userId, MethodChannel.Result result) {
//        if (!bStarted) {
//            result.success("Start capture first");
//            return;
//        }
//
//        strUid = userId;
//        if (strUid == null || strUid.isEmpty()) {
//            result.success("Invalid User ID");
//            return;
//        }
//
//        // Use the API interface method, not dbManager
//        dbManager.canAddFinger(strUid ,new Callback<CanAddFingerModel<Boolean>>() {
//            @Override
//            public void onResponse(@NonNull Call<CanAddFingerModel<Boolean>> call, @NonNull Response<CanAddFingerModel<Boolean>> response) {
//                if (response.isSuccessful() && response.body() != null) {
//
//                    try {
//                        String rawJson = response.raw().toString();
//                        android.util.Log.d("RAW_RESPONSE", rawJson);
//                    }
//                    catch (Exception e)
//                    {
//
//                    }
//
//
//                    CanAddFingerModel<Boolean> apiResponse = response.body();
//
//                    if (apiResponse.isSuccess()) {
//                        boolean exists = apiResponse.getContent();  // Get the content value (true or false)
//
//                        if (exists) {
//                            result.success("User already registered");
//                        } else {
//                            bRegister = true;
//                            enroll_index = 0;
//                            result.success("Please press your finger 3 times.");
//                        }
//                    } else {
//                        result.error("API_ERROR", "Failed to check if user exists: " + apiResponse.getErrorMessage(), null);
//                    }
//                } else {
//                    result.error("API_ERROR", "Error: " + response.message(), null);
//                }
//            }
//
//            @Override
//            public void onFailure(Call<CanAddFingerModel<Boolean>> call, Throwable t) {
//                result.error("NETWORK_ERROR", "Error: " + t.getMessage(), null);
//            }
//
//        });
//    }
//
//
//    private void identifyUserAsync(MethodChannel.Result result) {
//        if (!bStarted) {
//            result.success("Start capture first");
//            return;
//        }
//
//        bRegister = false; // Ensure that registration mode is off for identification
//        enroll_index = 0;  // Reset enrollment index for a fresh identification process
//
////        dbManager.queryUserList()
////                .addOnSuccessListener(userList -> {
////                    if (userList == null || userList.isEmpty()) {
////                        result.success("No registered users found");
////                    } else {
////                        result.success("Identification started. Please press your finger.");
////                    }
////                })
////                .addOnFailureListener(e -> {
////                    result.error("DB_ERROR", e.getMessage(), null);
////                });
//
//        dbManager.getUserList(new Callback<HashMap<String, Object>>() {
//            @Override
//            public void onResponse(@NonNull Call<HashMap<String, Object>> call, @NonNull Response<HashMap<String, Object>> response) {
//                if (response.isSuccessful() && response.body() != null) {
//                    HashMap<String, Object> userList = response.body();
//
//                    if (userList == null || userList.isEmpty()) {
//                        result.success("No registered users found");
//                    } else {
//                        result.success("Identification started. Please press your finger.");
//                    }
//                } else {
//                    result.error("API_ERROR", "Failed to retrieve users: " + response.message(), null);
//                }
//            }
//
//            @Override
//            public void onFailure(Call<HashMap<String, Object>> call, Throwable t) {
//                result.error("API_ERROR", "Error while fetching user list: " + t.getMessage(), null);
//            }
//        });
//
//
//    }
//
//
//    private void deleteUserAsync(String userId, MethodChannel.Result result) {
//        if (!bStarted) {
//            result.success("Start capture first");
//            return;
//        }
//
//        strUid = userId;
//        if (strUid == null || strUid.isEmpty()) {
//            result.success("Invalid User ID");
//            return;
//        }
//
//
//
////        these are not implemented for now!
//
//
////        dbManager.deleteUser(strUid)
////                .addOnSuccessListener(aVoid -> {
////                    ZKFingerService.del(strUid);
////                    result.success("User deleted successfully");
////                })
////                .addOnFailureListener(e -> {
////                    result.error("DELETE_ERROR", e.getMessage(), null);
////                });
//    }
//
//    private void clearAllUsersAsync(MethodChannel.Result result) {
//        if (!bStarted) {
//            result.success("Start capture first");
//            return;
//        }
//
////        dbManager.clear()
////                .addOnSuccessListener(aVoid -> {
////                    ZKFingerService.clear();
////                    result.success("All users cleared");
////                })
////                .addOnFailureListener(e -> {
////                    result.error("CLEAR_ERROR", e.getMessage(), null);
////                });
//    }
//
//    private void getStoredTemplatesAsync(MethodChannel.Result result) {
////        dbManager.queryUserList()
////                .addOnSuccessListener(templates -> {
////                    result.success(templates);
////                })
////                .addOnFailureListener(e -> {
////                    result.error("QUERY_ERROR", e.getMessage(), null);
////                });
//    }
//
//
//
//    private void openDevice() {
//        createFingerprintSensor();
//        bRegister = false;
//        enroll_index = 0;
//        isReseted = false;
//        try {
//            fingerprintSensor.open(deviceIndex);
//            loadAllTemplatesFromDB();
//            fingerprintSensor.setFingerprintCaptureListener(deviceIndex, fingerprintCaptureListener);
//            fingerprintSensor.SetFingerprintExceptionListener(fingerprintExceptionListener);
//            fingerprintSensor.startCapture(deviceIndex);
//            bStarted = true;
//            showToast("Device connected successfully");
//        } catch (FingerprintException e) {
//            e.printStackTrace();
//            showToast("Device connection failed");
//        }
//    }
//
//    private void closeDevice() {
//        if (bStarted) {
//            try {
//                fingerprintSensor.stopCapture(deviceIndex);
//                fingerprintSensor.close(deviceIndex);
//            } catch (FingerprintException e) {
//                e.printStackTrace();
//            }
//            bStarted = false;
//        }
//    }
//
//    private void createFingerprintSensor() {
//        if (fingerprintSensor != null) {
//            FingprintFactory.destroy(fingerprintSensor);
//            fingerprintSensor = null;
//        }
//        Map<String, Object> params = new HashMap<>();
//        params.put(ParameterHelper.PARAM_KEY_VID, ZKTECO_VID);
//        params.put(ParameterHelper.PARAM_KEY_PID, ZK9500_PID);
//        fingerprintSensor = FingprintFactory.createFingerprintSensor(getApplicationContext(), TransportType.USB, params);
//    }
//
//    private boolean enumSensor() {
//        UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
//        for (UsbDevice device : usbManager.getDeviceList().values()) {
//            if (device.getVendorId() == ZKTECO_VID && device.getProductId() == ZK9500_PID) {
//                usbDevice = device;
//                return true;
//            }
//        }
//        return false;
//    }
//
//    // Modified doRegister method to handle Firebase operations
////    private void doRegister(byte[] template) {
////        byte[] bufids = new byte[256];
////        int ret = ZKFingerService.identify(template, bufids, 70, 1);
////        if (ret > 0) {
////            String[] strRes = new String(bufids).split("\t");
////            showToast("Finger already enrolled by " + strRes[0] + ", canceling enrollment");
////            bRegister = false;
////            enroll_index = 0;
////            return;
////        }
////
////        if (enroll_index > 0 && (ret = ZKFingerService.verify(regtemparray[enroll_index - 1], template)) <= 0) {
////            showToast("Please press the same finger 3 times for enrollment, canceling enrollment");
////            bRegister = false;
////            enroll_index = 0;
////            return;
////        }
////
////        System.arraycopy(template, 0, regtemparray[enroll_index], 0, template.length);
////        enroll_index++;
////
////        if (enroll_index == ENROLL_COUNT) {
////            bRegister = false;
////            enroll_index = 0;
////            byte[] regTemp = new byte[2048];
////            if ((ret = ZKFingerService.merge(regtemparray[0], regtemparray[1], regtemparray[2], regTemp)) > 0) {
////                int retVal = 0;
////                sendTemplateToFlutter(regTemp, "enrollment");
////                retVal = ZKFingerService.save(regTemp, strUid);
////                if (retVal == 0) {
////                    String strFeature = Base64.encodeToString(regTemp, 0, ret, Base64.NO_WRAP);
////
////                    dbManager.insertUser(strUid, strFeature)
////                            .addOnSuccessListener(aVoid -> {
////                                showToast("Enrollment successful");
////                            })
////                            .addOnFailureListener(e -> {
////                                showToast("Failed to save to database: " + e.getMessage());
////                            });
////                } else {
////                    showToast("Enrollment failed, error code: " + ret);
////                }
////            } else {
////                showToast("Enrollment failed during template merge");
////            }
////        } else {
////            showToast("You need to press your finger " + (ENROLL_COUNT - enroll_index) + " more times");
////        }
////    }
//
//    private void doRegister(byte[] template) {
//        byte[] bufids = new byte[256];
//        int ret = ZKFingerService.identify(template, bufids, 70, 1);
//
//        // Check if the finger is already enrolled
//        if (ret > 0) {
//            String[] strRes = new String(bufids).split("\t");
//            showToast("Finger already enrolled by " + strRes[0] + ", canceling enrollment");
//            bRegister = false;
//            enroll_index = 0;
//            return;
//        }
//
//        // Verify if the same finger is being pressed multiple times for enrollment
//        if (enroll_index > 0 && (ret = ZKFingerService.verify(regtemparray[enroll_index - 1], template)) <= 0) {
//            showToast("Please press the same finger 3 times for enrollment, canceling enrollment");
//            bRegister = false;
//            enroll_index = 0;
//            return;
//        }
//
//        // Save the fingerprint template
//        System.arraycopy(template, 0, regtemparray[enroll_index], 0, template.length);
//        enroll_index++;
//
//        // If 3 enrollments are completed, merge the templates and save the fingerprint
//        if (enroll_index == ENROLL_COUNT) {
//            bRegister = false;
//            enroll_index = 0;
//            byte[] regTemp = new byte[2048];
//            if ((ret = ZKFingerService.merge(regtemparray[0], regtemparray[1], regtemparray[2], regTemp)) > 0) {
//                int retVal = 0;
//                sendTemplateToFlutter(regTemp, "enrollment"); // Send the template to Flutter
//
//                retVal = ZKFingerService.save(regTemp, strUid); // Save fingerprint to device storage
//
//                // If the template is saved successfully, proceed to insert user into the database
//                if (retVal == 0) {
//                    String strFeature = Base64.encodeToString(regTemp, 0, ret, Base64.NO_WRAP);
//
//                    // Create a HashMap to store user data
//                    HashMap<String, Object> userMap = new HashMap<>();
//                    userMap.put("pin", strUid);
//                    userMap.put("feature", strFeature);
//
//                    // Call dbManager's insertUser method to insert user into the database
//                    dbManager.insertUser(userMap, new Callback<Void>() {
//                        @Override
//                        public void onResponse(Call<Void> call, Response<Void> response) {
//                            if (response.isSuccessful()) {
//                                showToast("Enrollment successful and user saved to database");
//                            } else {
//                                showToast("Failed to save user to database: " + response.message());
//                            }
//                        }
//
//                        @Override
//                        public void onFailure(Call<Void> call, Throwable t) {
//                            showToast("Failed to save user to database: " + t.getMessage());
//                        }
//                    });
//                } else {
//                    showToast("Enrollment failed, error code: " + ret);
//                }
//            } else {
//                showToast("Enrollment failed during template merge");
//            }
//        } else {
//            showToast("You need to press your finger " + (ENROLL_COUNT - enroll_index) + " more times");
//        }
//    }
//
//
//    private void doIdentify(byte[] template) {
//        byte[] bufids = new byte[256];
//        int ret = ZKFingerService.identify(template, bufids, 70, 1);
//        // Send identification template to Flutter
//        sendTemplateToFlutter(template, "identification");
//        if (ret > 0) {
//            String strRes[] = new String(bufids).split("\t");
//            Log.d(TAG , "BufferIds Identification: "+ new String(bufids));
//            showToast("Identification successful, User ID: " + strRes[0].trim() + ", Score: " + strRes[1].trim());
//        } else {
//            showToast("Identification failed, error code: " + ret);
//        }
//    }
//
//    // Modified loadAllTemplatesFromDB method to handle Firebase
//    private void loadAllTemplatesFromDB() {
////        dbManager.queryUserList()
////                .addOnSuccessListener(userMap -> {
////                    if (userMap != null) {
////                        for (Map.Entry<String, String> entry : userMap.entrySet()) {
////                            String userId = entry.getKey();
////                            String templateStr = entry.getValue();
////                            byte[] template = Base64.decode(templateStr, Base64.NO_WRAP);
////                            ZKFingerService.save(template, userId);
////                        }
////                    }
////                })
////                .addOnFailureListener(e -> {
////                    Log.e(TAG, "Failed to load templates from Firebase: " + e.getMessage());
////                });
//
//
//        dbManager.queryUserList(new Callback<List<Map<String, String>>>() {
//            @Override
//            public void onResponse(Call<List<Map<String, String>>> call, Response<List<Map<String, String>>> response) {
//                if (response.isSuccessful() && response.body() != null) {
//                    List<Map<String, String>> userList = response.body();
//
//                    // Iterate through the users and process their fingerprint data
//                    for (Map<String, String> userMap : userList) {
//                        for (Map.Entry<String, String> entry : userMap.entrySet()) {
//                            String userId = entry.getKey();
//                            String templateStr = entry.getValue();
//
//                            // Decode the template string to byte array
//                            byte[] template = Base64.decode(templateStr, Base64.NO_WRAP);
//
//                            // Save the template using ZKFingerService
//                            ZKFingerService.save(template, userId);
//                        }
//                    }
//                } else {
//                    Log.e(TAG, "Failed to load user data: " + response.message());
//                }
//            }
//
//            @Override
//            public void onFailure(Call<List<Map<String, String>>> call, Throwable t) {
//                // Handle failure (e.g., network error or other issues)
//                Log.e(TAG, "Failed to load templates: " + t.getMessage());
//            }
//        });
//
//    }
//
//    // ... (keep all other methods the same)
//
//
//    private void startCapture() {
//        if (bStarted) {
//            showToast("Capture already started");
//            return;
//        }
//        if (!enumSensor()) {
//            showToast("Device not found!");
//            return;
//        }
//
//        UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
//        if (usbManager.hasPermission(usbDevice)) {
//            openDevice();
//        } else {
//            PendingIntent permissionIntent = PendingIntent.getBroadcast(this, 0, new Intent(USB_PERMISSION_ACTION), PendingIntent.FLAG_IMMUTABLE);
//            usbManager.requestPermission(usbDevice, permissionIntent);
//        }
//    }
//
//    private void stopCapture() {
//        if (!bStarted) {
//            showToast("Device not connected!");
//            return;
//        }
//        closeDevice();
//        showToast("Device closed!");
//    }
//
//    private void showToast(String message) {
//        runOnUiThread(() -> Toast.makeText(MainActivity.this, message, Toast.LENGTH_SHORT).show());
//    }
//
//    private void sendTemplateToFlutter(byte[] template, String type) {
//        runOnUiThread(() -> {
//            try {
//                // Convert template to Base64 string
//                String base64Template = Base64.encodeToString(template, Base64.NO_WRAP);
//
//                // Create a map to send more detailed information
//                Map<String, Object> templateData = new HashMap<>();
//                templateData.put("type", type);  // e.g., "enrollment", "identification"
//                templateData.put("base64", base64Template);
//                templateData.put("length", template.length);
//
//                // Invoke Flutter method to receive template data
//                new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
//                        .invokeMethod("updateTemplate", templateData);
//            } catch (Exception e) {
//                Log.e(TAG, "Failed to send template to Flutter", e);
//            }
//        });
//    }
//}





package pbi_time;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import android.graphics.Bitmap;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;

import android.util.Base64;
import android.util.Log;
import android.widget.Toast;


import java.io.ByteArrayOutputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

// Import ZKTeco classes (same as before)
import com.zkteco.android.biometric.FingerprintExceptionListener;
import com.zkteco.android.biometric.core.device.ParameterHelper;
import com.zkteco.android.biometric.core.device.TransportType;
import com.zkteco.android.biometric.core.utils.ToolUtils;
import com.zkteco.android.biometric.module.fingerprintreader.FingerprintCaptureListener;
import com.zkteco.android.biometric.module.fingerprintreader.FingerprintSensor;
import com.zkteco.android.biometric.module.fingerprintreader.FingprintFactory;
import com.zkteco.android.biometric.module.fingerprintreader.ZKFingerService;
import com.zkteco.android.biometric.module.fingerprintreader.exception.FingerprintException;

public class MainActivity extends FlutterFragmentActivity {
    // ... (keeping all existing constants and private fields)

    private static final String CHANNEL = "zkfingerprint_channel";
    private static final String TAG = "MainActivity";
    private static final String USB_PERMISSION_ACTION = "com.example.channel_practice.USB_PERMISSION";

    private static final int ZKTECO_VID = 0x1b55;
    private static final int ZK9500_PID = 0x0124;
    private final static int ENROLL_COUNT = 3;
    private FingerprintSensor fingerprintSensor;
    private boolean bStarted = false;
    private int deviceIndex = 0;
    private boolean isReseted = false;
    private final FingerprintExceptionListener fingerprintExceptionListener = () -> {
//        Log.e(TAG, "Fingerprint device exception");
        if (!isReseted) {
            try {
                fingerprintSensor.openAndReboot(deviceIndex);
            } catch (FingerprintException e) {
                e.printStackTrace();
            }
            isReseted = true;
        }
    };
    private String strUid = null;
    private int enroll_index = 0;
    private byte[][] regtemparray = new byte[3][2048];
    private boolean bRegister = false;
//    private DBManager dbManager;
    private final FingerprintCaptureListener fingerprintCaptureListener = new FingerprintCaptureListener() {

        @Override
        public void captureOK(byte[] fpImage) {
            if (fpImage == null) {
                Log.e(TAG, "Fingerprint image is null");
                return;
            }

            // Ensure fingerprintSensor is not null
            if (fingerprintSensor == null) {
                Log.e(TAG, "Fingerprint sensor is not initialized");
                return;
            }

            // Convert the fingerprint image to a bitmap
            final Bitmap bitmap = ToolUtils.renderCroppedGreyScaleBitmap(fpImage, fingerprintSensor.getImageWidth(), fingerprintSensor.getImageHeight());
            if (bitmap == null) {
                Log.e(TAG, "Failed to render the fingerprint image to a bitmap");
                return;
            }

            // Run the Flutter method call on the main thread
            runOnUiThread(() -> {
                try {
                    // Convert the bitmap to a byte array to send to Flutter
                    ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
                    byte[] byteArray = byteArrayOutputStream.toByteArray();

                    // Check if the channel is properly initialized before calling
                    if (getFlutterEngine() != null && getFlutterEngine().getDartExecutor() != null) {
                        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                                .invokeMethod("updateImage", byteArray);
                    } else {
                        Log.e(TAG, "Flutter method channel is not initialized");
                    }
                } catch (Exception e) {
                    Log.e(TAG, "Failed to send image to Flutter", e);
                }
            });
        }

        public void captureError(FingerprintException e) {
//            Log.e(TAG, "Capture error: " + e.getMessage());
        }

        @Override
        public void extractOK(byte[] fpTemplate) {
            if (bRegister) {
                doRegister(fpTemplate);
            } else {
                doIdentify(fpTemplate);
            }
        }

        @Override
        public void extractError(int errorCode) {
//            Log.e(TAG, "Extract error code: " + errorCode);
        }
    };
    private final BroadcastReceiver usbPermissionReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (USB_PERMISSION_ACTION.equals(intent.getAction())) {
                synchronized (this) {
                    UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        if (device != null) {
                            openDevice();
                        }
                    } else {
                        showToast("USB Permission Denied");
                    }
                }
            }
        }
    };
    private UsbDevice usbDevice;
    private MethodChannel methodChannel;


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Initialize Firebase
//        FirebaseApp.initializeApp(this);
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);

        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "startCapture":
                    boolean response = startCapture();
                    result.success(response);
                    break;
                case "stopCapture":
                    stopCapture();
                    result.success("Capture stopped");
                    break;
                case "registerUser":
                    String userId = call.argument("userId");
                    registerUserAsync(userId, result);
                    break;
                case "identifyUser":
                    identifyUserAsync(result);
                    break;
                case "deleteUser":
                    String deleteUserId = call.argument("userId");
//                    deleteUserAsync(deleteUserId, result);
                    break;
                case "clearAllUsers":
//                    clearAllUsersAsync(result);
                    break;
                case "checkDeviceStatus":
                    boolean status = checkDevice();
                    result.success(status);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });
    }

    private boolean checkDevice()
    {
        if (!bStarted) {
//            result.success("Start capture first");
            return false;
        }

        return true;

    }

    private void registerUserAsync(String userId, MethodChannel.Result result) {
        if (!bStarted) {
            result.success("Start capture first");
            return;
        }

        strUid = userId;
        if (strUid == null || strUid.isEmpty()) {
            result.success("Invalid Employee ID");
            return;
        }

        Map<String, Object> arguments = new HashMap<>();
        arguments.put("empId", strUid);

        runOnUiThread(() -> {
            methodChannel.invokeMethod("db_canAddFinger", arguments, new MethodChannel.Result() {
                @Override
                public void success(Object response) {
                    if (response instanceof Map) {
                        Map<String, Object> responseMap = (Map<String, Object>) response;
                        Object dataObject = responseMap.get("data");

                        if (dataObject instanceof Map) {
                            Map<String, Object> data = (Map<String, Object>) dataObject;
                            Boolean canAdd = (Boolean) data.get("isSuccess");
                            String errorMessage = (String) data.get("errorMessage");

                            if (canAdd != null && canAdd) {
                                bRegister = true;
                                enroll_index = 0;
                                result.success("Please press your finger 3 times.");
                            } else {
                                result.success(errorMessage != null ? errorMessage : "User cannot add a fingerprint.");
                            }
                        } else {
                            result.error("INVALID_RESPONSE", "Invalid data format", null);
                        }
                    } else {
                        result.error("INVALID_RESPONSE", "Invalid response type", null);
                    }
                }

                @Override
                public void error(String errorCode, String errorMessage, Object errorDetails) {
                    result.error(errorCode, errorMessage, errorDetails);
                    ZKFingerService.del(strUid);
                }

                @Override
                public void notImplemented() {
                    result.notImplemented();
                }
            });
        });
    }


    private void identifyUserAsync(MethodChannel.Result result) {
        if (!bStarted) {
            result.success("Start capture first");
            return;
        }

        bRegister = false;
        enroll_index = 0;

//        return "Identification started";

        // Get user list from Flutter
        methodChannel.invokeMethod("db_getUserList", null, new MethodChannel.Result() {
            @Override
//            public void success(Object response) {
//                if (response instanceof Map) {
//                    Map<String, Object> responseMap = (Map<String, Object>) response;
//                    boolean hasUsers = (boolean) responseMap.get("success");
//
//                    if (hasUsers) {
//                        result.success("Identification started. Please press your finger.");
//                    } else {
//                        result.success("No registered users found");
//                    }
//                } else {
//                    result.error("INVALID_RESPONSE", "Invalid response format from Flutter", null);
//                }
//            }
            public void success(Object response) {
                if (response instanceof Map) {
                    Map<String, Object> responseMap = (Map<String, Object>) response;

                    // Check if the response indicates success
                    if ((boolean) responseMap.get("isSuccess")) {
                        Map<String, Object> content = (Map<String, Object>) responseMap.get("content");
                        List<Map<String, Object>> userList = (List<Map<String, Object>>) content.get("$values");

                        for (Map<String, Object> user : userList) {
                            // Extract necessary fields
                            Integer employeeId = (Integer) user.get("employeeId");
                            String base64FingerData = (String) user.get("finger");

                            if (employeeId != null && base64FingerData != null) {
                                result.success("Identification started. Please press your finger.");
                                // Decode the base64 fingerprint data
                                byte[] template = Base64.decode(base64FingerData, Base64.NO_WRAP);

                                // Save the decoded fingerprint data (e.g., using your ZKFingerService)
                                ZKFingerService.save(template, employeeId.toString());
                            }
                        }
                    } else {
                        result.success("No registered users found");
                    }
                }
            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {
                result.error(errorCode, errorMessage, errorDetails);
            }

            @Override
            public void notImplemented() {
                result.notImplemented();
            }
        });
    }

//    private void doRegister(byte[] template) {
//        byte[] bufids = new byte[256];
//        int ret = ZKFingerService.identify(template, bufids, 70, 1);
//
//        if (ret > 0) {
//            String[] strRes = new String(bufids).split("\t");
//            showToast("Finger already enrolled by " + strRes[0] + ", canceling enrollment");
//            bRegister = false;
//            enroll_index = 0;
//            ZKFingerService.del(strUid);
//            return;
//        }
//
//        if (enroll_index > 0 && (ret = ZKFingerService.verify(regtemparray[enroll_index - 1], template)) <= 0) {
//            showToast("Please press the same finger 3 times for enrollment, canceling enrollment");
//            bRegister = false;
//            enroll_index = 0;
//            ZKFingerService.del(strUid);
//            return;
//        }
//
//        System.arraycopy(template, 0, regtemparray[enroll_index], 0, template.length);
//        enroll_index++;
//
//        if (enroll_index == ENROLL_COUNT) {
//            bRegister = false;
//            enroll_index = 0;
//            byte[] regTemp = new byte[2048];
//            if ((ret = ZKFingerService.merge(regtemparray[0], regtemparray[1], regtemparray[2], regTemp)) > 0) {
//                int retVal = ZKFingerService.save(regTemp, strUid);
////                sendTemplateToFlutter(regTemp, "enrollment");
////                fingerprintCaptureListener.captureOK(regTemp);    //this crashes the app.
//
//                if (retVal == 0) {
//                    String strFeature = Base64.encodeToString(regTemp, 0, ret, Base64.NO_WRAP);
//
//                    // Send user data to Flutter for storage
//                    Map<String, Object> userData = new HashMap<>();
//                    userData.put("empId", strUid);
//                    userData.put("template", strFeature);
//
//                    runOnUiThread(()->{
//                        methodChannel.invokeMethod("db_insertUser", userData, new MethodChannel.Result() {
//                            @Override
//                            public void success(Object response) {
//                                if (response instanceof Map) {
//                                    Map<String, Object> responseMap = (Map<String, Object>) response;
//                                    boolean success = (boolean) responseMap.get("success");
//
//                                    if (success) {
//                                        String strRes[] = new String(bufids).split("\t");
//                                        String result = "Identification successful, User ID: " + strRes[0].trim() + ", Score: " + strRes[1].trim();
//                                        sendTemplateToFlutter(regTemp, "enrollment" , result);
//                                        showToast("Enrollment successful");
//                                        stopCapture();
//                                    } else {
//                                        String error = (String) responseMap.get("error");
//                                        showToast("Failed to save to database: " + error);
//                                        ZKFingerService.del(strUid);
//                                    }
//                                }
//                                else ZKFingerService.del(strUid);
//                            }
//
//                            @Override
//                            public void error(String errorCode, String errorMessage, Object errorDetails) {
//                                showToast("Failed to save to database: " + errorMessage);
//                                ZKFingerService.del(strUid);
//                            }
//
//                            @Override
//                            public void notImplemented() {
//                                showToast("Database operation not implemented");
//                                ZKFingerService.del(strUid);
//                            }
//                        });
//
//                    });
//                } else {
//                    showToast("Enrollment failed, error code: " + ret);
//                    ZKFingerService.del(strUid);
//                }
//            } else {
//                showToast("Enrollment failed during template merge");
//                ZKFingerService.del(strUid);
//            }
//        } else {
//            showToast("You need to press your finger " + (ENROLL_COUNT - enroll_index) + " more times");
//        }
//    }

    private void doRegister(byte[] template) {
        byte[] bufids = new byte[256];
        int ret = ZKFingerService.identify(template, bufids, 70, 1);

        // Check if finger already exists
        if (ret > 0) {
            String[] strRes = new String(bufids).split("\t");
            showToast("Finger already enrolled by " + strRes[0] + ", canceling enrollment");
            bRegister = false;
            enroll_index = 0;
            return;
        }

        // Verify same finger is being used for enrollment
        if (enroll_index > 0 && (ret = ZKFingerService.verify(regtemparray[enroll_index - 1], template)) <= 0) {
            showToast("Please press the same finger 3 times for enrollment, canceling enrollment");
            bRegister = false;
            enroll_index = 0;
            return;
        }

        // Store the current template
        System.arraycopy(template, 0, regtemparray[enroll_index], 0, template.length);
        enroll_index++;

        // If we haven't collected all required samples
        if (enroll_index < ENROLL_COUNT) {
            showToast("You need to press your finger " + (ENROLL_COUNT - enroll_index) + " more times");
            return;
        }

        // Process final enrollment after collecting all samples
        bRegister = false;
        enroll_index = 0;
        byte[] regTemp = new byte[2048];
        ret = ZKFingerService.merge(regtemparray[0], regtemparray[1], regtemparray[2], regTemp);

        if (ret <= 0) {
            showToast("Enrollment failed during template merge");
            return;
        }

        String strFeature = Base64.encodeToString(regTemp, 0, ret, Base64.NO_WRAP);
        Map<String, Object> userData = new HashMap<>();
        userData.put("empId", strUid);
        userData.put("template", strFeature);

        // Send to Flutter database
        runOnUiThread(() -> {
            methodChannel.invokeMethod("db_insertUser", userData, new MethodChannel.Result() {
                @Override
                public void success(Object response) {
                    if (response instanceof Map) {
                        Map<String, Object> responseMap = (Map<String, Object>) response;
                        boolean success = (boolean) responseMap.get("success");

                        if (success) {
                            // Only save to device after successful DB save
                            int retVal = ZKFingerService.save(regTemp, strUid);
                            if (retVal == 0) {
                                String[] strRes = new String(bufids).split("\t");
                                String result = "Identification successful, User ID: " + strRes[0].trim() +
                                        ", Score: " + strRes[1].trim();
                                sendTemplateToFlutter(regTemp, "enrollment", result);
                                showToast("Enrollment successful");
                                stopCapture();
                            } else {
                                showToast("Failed to save to device: " + retVal);
                            }
                        } else {
                            String error = (String) responseMap.get("error");
                            showToast("Failed to save to database: " + error);
                        }
                    }
                }

                @Override
                public void error(String errorCode, String errorMessage, Object errorDetails) {
                    showToast("Failed to save to database: " + errorMessage);
                }

                @Override
                public void notImplemented() {
                    showToast("Database operation not implemented");
                }
            });
        });
    }

    private void doIdentify(byte[] template) {

        byte[] bufids = new byte[256];
        int ret = ZKFingerService.identify(template, bufids, 70, 1);
        // Send identification template to Flutter
//        sendTemplateToFlutter(template, "identification");
        if (ret > 0) {
            String strRes[] = new String(bufids).split("\t");
            String userId = strRes[0].trim();
            Log.d(TAG , "BufferIds Identification: "+ new String(bufids));
            showToast("Identification successful, User ID: " + strRes[0].trim() + ", Score: " + strRes[1].trim());
            String result = "Identification successful, User ID: " + strRes[0].trim() + ", Score: " + strRes[1].trim();

            sendTemplateToFlutter(template, "identification" , result);

            runOnUiThread(()->{
            methodChannel.invokeMethod("mark_attendance",userId, new MethodChannel.Result() {

                @Override
                public void success(@Nullable Object result) {
                    if (result != null) {
                        Log.d("MethodChannel", "Success: " + result.toString());
                    } else {
                        Log.d("MethodChannel", "Success: Result is null");
                    }
                }

                @Override
                public void error(@NonNull String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
                    Log.e("MethodChannel", "Error - Code: " + errorCode + ", Message: " + errorMessage + ", Details: " + errorDetails);
                }

                @Override
                public void notImplemented() {
                    Log.w("MethodChannel", "Method not implemented");
                }
            });
            });


        } else {
            showToast("Identification failed, error code: " + ret);
        }
    }

    private void loadAllTemplatesFromDB() {
        // Send request to Flutter to get all templates
        methodChannel.invokeMethod("db_getUserList", null, new MethodChannel.Result() {
            @Override
            public void success(Object response) {
                if (response instanceof Map) {
                    Map<String, Object> responseMap = (Map<String, Object>) response;
                    Map<String, Object> data = (Map<String, Object>) responseMap.get("data");


                    // Check if the response indicates success
                    if ((boolean) data.get("isSuccess")) {
                        Map<String, Object> content = (Map<String, Object>) data.get("content");
                        List<Map<String, Object>> userList = (List<Map<String, Object>>) content.get("$values");

                        for (Map<String, Object> user : userList) {
                            // Extract necessary fields
                            Integer employeeId = (Integer) user.get("employeeId");
                            String base64FingerData = (String) user.get("finger");

                            if (employeeId != null && base64FingerData != null) {
                                // Decode the base64 fingerprint data
                                byte[] template = Base64.decode(base64FingerData, Base64.NO_WRAP);

                                // Save the decoded fingerprint data (e.g., using your ZKFingerService)
                                ZKFingerService.save(template, employeeId.toString());

                            }
                        }
                    } else {
                        // Handle case where the response is not successful (e.g., log or show error)
                        String errorMessage = (String) responseMap.get("errorMessage");
                        if (errorMessage != null) {
                            Log.e("FingerprintRegistration", "Error: " + errorMessage);
                        }
                    }
                }
            }


            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {
                Log.e(TAG, "Failed to load templates: " + errorMessage);
            }

            @Override
            public void notImplemented() {
                Log.e(TAG, "Load templates not implemented");
            }
        });
    }

    // ... (keeping all other existing methods unchanged)


        private boolean startCapture() {
        if (bStarted) {
            showToast("Capture already started");
            return false;
        }
        if (!enumSensor()) {
            showToast("Device not found!");
            return false;
        }

//        UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
//        if (usbManager.hasPermission(usbDevice)) {
//            openDevice();
//            return true;
//        } else {
//            PendingIntent permissionIntent = PendingIntent.getBroadcast(this, 0, new Intent(USB_PERMISSION_ACTION), PendingIntent.FLAG_IMMUTABLE);
//            usbManager.requestPermission(usbDevice, permissionIntent);
//            openDevice();
//            return false;
//        }

            UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
            if (!usbManager.hasPermission(usbDevice)) {
                Intent permissionIntent = new Intent(USB_PERMISSION_ACTION);
                PendingIntent pendingIntent = PendingIntent.getBroadcast(this, 0, permissionIntent, PendingIntent.FLAG_IMMUTABLE);
                usbManager.requestPermission(usbDevice, pendingIntent);
            }
            openDevice();
            return usbManager.hasPermission(usbDevice);
    }

    private void stopCapture() {
        if (!bStarted) {
            showToast("Device not connected!");
            return;
        }
        closeDevice();
        showToast("Device closed!");
    }

        private void openDevice() {

        try {
        createFingerprintSensor();
//        loadAllTemplatesFromDB();
        bRegister = false;
        enroll_index = 0;
        isReseted = false;

            fingerprintSensor.open(deviceIndex);
//            loadAllTemplatesFromDB();
            fingerprintSensor.setFingerprintCaptureListener(deviceIndex, fingerprintCaptureListener);
            fingerprintSensor.SetFingerprintExceptionListener(fingerprintExceptionListener);
            fingerprintSensor.startCapture(deviceIndex);
            bStarted = true;

            showToast("Device connected successfully");
            loadAllTemplatesFromDB();

        } catch (Exception e) {
            Log.e(TAG, "Device Open Error in Release Mode", e);
            // Send detailed error to Flutter
            runOnUiThread(() -> {
                Map<String, Object> errorDetails = new HashMap<>();
                errorDetails.put("message", e.getMessage());
                errorDetails.put("stackTrace", Log.getStackTraceString(e));
                methodChannel.invokeMethod("deviceOpenError", errorDetails);
            });
        }
    }

    private void closeDevice() {
        if (bStarted) {
            try {
                fingerprintSensor.stopCapture(deviceIndex);
                fingerprintSensor.close(deviceIndex);
            } catch (FingerprintException e) {
                e.printStackTrace();
            }
            bStarted = false;
        }
    }

    private void createFingerprintSensor() {
        if (fingerprintSensor != null) {
            FingprintFactory.destroy(fingerprintSensor);
            fingerprintSensor = null;
        }
        Map<String, Object> params = new HashMap<>();
        params.put(ParameterHelper.PARAM_KEY_VID, ZKTECO_VID);
        params.put(ParameterHelper.PARAM_KEY_PID, ZK9500_PID);
        fingerprintSensor = FingprintFactory.createFingerprintSensor(getApplicationContext(), TransportType.USB, params);
    }

    private boolean enumSensor() {
        UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
        for (UsbDevice device : usbManager.getDeviceList().values()) {
            if (device.getVendorId() == ZKTECO_VID && device.getProductId() == ZK9500_PID) {
                usbDevice = device;
                return true;
            }
        }
        return false;
    }



    private void showToast(String message) {
        runOnUiThread(() -> Toast.makeText(MainActivity.this, message, Toast.LENGTH_SHORT).show());
    }

    private void sendTemplateToFlutter(byte[] template, String type , String result) {
        runOnUiThread(() -> {
            try {
                // Convert template to Base64 string
                String base64Template = Base64.encodeToString(template, Base64.NO_WRAP);

                // Create a map to send more detailed information
                Map<String, Object> templateData = new HashMap<>();
                templateData.put("type", type);  // e.g., "enrollment", "identification"
                templateData.put("base64", base64Template);
                templateData.put("length", template.length);
                templateData.put("result", result);

                // Invoke Flutter method to receive template data
                new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                        .invokeMethod("updateTemplate", templateData);
            } catch (Exception e) {
                Log.e(TAG, "Failed to send template to Flutter", e);
            }
        });
    }
}