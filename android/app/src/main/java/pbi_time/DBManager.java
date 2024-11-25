////package com.example.channel_practice;
////
////import android.content.ContentValues;
////import android.content.Context;
////import android.database.Cursor;
////import android.database.sqlite.SQLiteDatabase;
////
////import java.util.HashMap;
////
////public class DBManager {
////    private String dbName;
////    SQLiteDatabase db = null;
////    boolean bIsOpened = false;
////
////    public DBManager(Context applicationContext) {
////    }
////
////    public boolean opendb(String fileName)
////    {
////        if (bIsOpened)
////        {
////            return true;
////        }
////        dbName = fileName;
////        db = SQLiteDatabase.openOrCreateDatabase(dbName, null);
////        if (null == db)
////        {
////            return false;
////        }
////        String strSQL = "create table if not exists userinfo(id integer primary key autoincrement,pin text not null,feature text not null)";
////        db.execSQL(strSQL);
////        bIsOpened = true;
////        return true;
////    }
////
////    public boolean isUserExited(String pin)
////    {
////        if (!bIsOpened)
////        {
////            opendb(dbName);
////        }
////        if (null == db)
////        {
////            return false;
////        }
////        Cursor cursor = db.query("userinfo", null, "pin=?", new String[] { pin }, null, null, null);
////        return cursor.getCount() > 0;
////    }
////
////    public boolean deleteUser(String pin)
////    {
////        if (!bIsOpened)
////        {
////            opendb(dbName);
////        }
////        if (null == db)
////        {
////            return false;
////        }
////        db.delete("userinfo", "pin=?", new String[] { pin });
////        return true;
////    }
////
////
////    public boolean clear()
////    {
////        if (!bIsOpened)
////        {
////            opendb(dbName);
////        }
////        if (null == db)
////        {
////            return false;
////        }
////        String strSQL = "delete from userinfo;";
////        db.execSQL(strSQL);
////        return true;
////    }
////
////    public boolean modifyUser(String pin, String feature)
////    {
////        if (!bIsOpened)
////        {
////            opendb(dbName);
////        }
////        if (null == db)
////        {
////            return false;
////        }
////        ContentValues value = new ContentValues();
////        value.put("feature", feature);
////        db.update("userinfo", value, "pin=?", new String[] { pin });
////        return true;
////    }
////
////    public int getCount()
////    {
////        if (!bIsOpened)
////        {
////            opendb(dbName);
////        }
////        if (null == db)
////        {
////            return 0;
////        }
////        Cursor cursor = db.query("userinfo", null, null, null, null, null, null);
////        return cursor.getCount();
////    }
////
////    public boolean insertUser(String pin, String feature)
////    {
////        if (!bIsOpened)
////        {
////            opendb(dbName);
////        }
////        if (null == db)
////        {
////            return false;
////        }
////        ContentValues value = new ContentValues();
////        value.put("pin", pin);
////        value.put("feature", feature);
////        db.insert("userinfo", null, value);
////        return true;
////    }
////
////    public HashMap<String, String> queryUserList()
////    {
////        if (!bIsOpened)
////        {
////            return null;
////        }
////        if (null == db)
////        {
////            return null;
////        }
////        Cursor cursor = db.query("userinfo", null, null, null, null, null, null);
////        if (cursor.getCount() == 0)
////        {
////            cursor.close();
////            return null;
////        }
////        HashMap<String, String> map = new HashMap<String, String>();
////        for (cursor.moveToFirst();!cursor.isAfterLast();cursor.moveToNext()) {
////           map.put(cursor.getString(cursor.getColumnIndex("pin")), cursor.getString(cursor.getColumnIndex("feature")));
////        }
////        cursor.close();
////        return map;
////    }
////
////}
//
//
//package pbi_time;
//
//import android.content.ContentValues;
//import android.content.Context;
//import android.database.Cursor;
//import android.database.sqlite.SQLiteDatabase;
//
//import java.util.HashMap;
//
//public class DBManager {
//    private String dbName;
//    private SQLiteDatabase db = null;
//    private boolean bIsOpened = false;
//
//    public DBManager(Context context, String fileName) {
//        dbName = context.getFilesDir().getAbsolutePath() + "/" + fileName;
//        opendb();
//    }
//
//    // Opens the database and creates the userinfo table if it does not exist
//    public boolean opendb() {
//        if (bIsOpened) {
//            return true;
//        }
//        db = SQLiteDatabase.openOrCreateDatabase(dbName, null);
//        if (db == null) {
//            return false;
//        }
//        String strSQL = "CREATE TABLE IF NOT EXISTS userinfo(" +
//                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
//                "pin TEXT NOT NULL," +
//                "feature TEXT NOT NULL)";
//        db.execSQL(strSQL);
//        bIsOpened = true;
//        return true;
//    }
//
//    // Checks if a user with a specific pin exists in the database
//    public boolean isUserExist(String pin) {
//        if (!bIsOpened) {
//            opendb();
//        }
//        if (db == null) {
//            return false;
//        }
//        Cursor cursor = db.query("userinfo", null, "pin=?", new String[]{pin}, null, null, null);
//        boolean exists = cursor.getCount() > 0;
//        cursor.close();
//        return exists;
//    }
//
//    // Deletes a user with a specific pin from the database
//    public boolean deleteUser(String pin) {
//        if (!bIsOpened) {
//            opendb();
//        }
//        if (db == null) {
//            return false;
//        }
//        db.delete("userinfo", "pin=?", new String[]{pin});
//        return true;
//    }
//
//    // Clears all users from the database
//    public boolean clear() {
//        if (!bIsOpened) {
//            opendb();
//        }
//        if (db == null) {
//            return false;
//        }
//        db.execSQL("DELETE FROM userinfo;");
//        return true;
//    }
//
//    // Updates the feature of a user with a specific pin
//    public boolean modifyUser(String pin, String feature) {
//        if (!bIsOpened) {
//            opendb();
//        }
//        if (db == null) {
//            return false;
//        }
//        ContentValues value = new ContentValues();
//        value.put("feature", feature);
//        db.update("userinfo", value, "pin=?", new String[]{pin});
//        return true;
//    }
//
//    // Returns the count of users in the database
//    public int getCount() {
//        if (!bIsOpened) {
//            opendb();
//        }
//        if (db == null) {
//            return 0;
//        }
//        Cursor cursor = db.query("userinfo", null, null, null, null, null, null);
//        int count = cursor.getCount();
//        cursor.close();
//        return count;
//    }
//
//    // Inserts a new user into the database
//    public boolean insertUser(String pin, String feature) {
//        if (!bIsOpened) {
//            opendb();
//        }
//        if (db == null) {
//            return false;
//        }
//        ContentValues value = new ContentValues();
//        value.put("pin", pin);
//        value.put("feature", feature);
//        db.insert("userinfo", null, value);
//        return true;
//    }
//
//    // Queries and returns all users in the database as a HashMap
//    public HashMap<String, String> queryUserList() {
//        if (!bIsOpened) {
//            return null;
//        }
//        if (db == null) {
//            return null;
//        }
//        Cursor cursor = db.query("userinfo", null, null, null, null, null, null);
//        if (cursor.getCount() == 0) {
//            cursor.close();
//            return null;
//        }
//        HashMap<String, String> map = new HashMap<>();
//        while (cursor.moveToNext()) {
//            map.put(cursor.getString(cursor.getColumnIndex("pin")), cursor.getString(cursor.getColumnIndex("feature")));
//        }
//        cursor.close();
//        return map;
//    }
//
//    // Closes the database if open
//    public void closeDB() {
//        if (bIsOpened && db != null) {
//            db.close();
//            bIsOpened = false;
//        }
//    }
//
//}





//////With FireBase
//package pbi_time;
//
//import android.content.Context;
//import com.google.firebase.database.*;
//import com.google.android.gms.tasks.Task;
//import com.google.android.gms.tasks.TaskCompletionSource;
//
//import java.util.HashMap;
//
//public class DBManager {
//    private DatabaseReference dbRef;
//    private boolean bIsOpened = false;
//    private static final String USERS_PATH = "userinfo";
//
//    public DBManager(Context context, String fileName) {
//        // Initialize Firebase Database reference
////        dbRef = FirebaseDatabase.getInstance().getReference(USERS_PATH);
//        FirebaseDatabase database = FirebaseDatabase.getInstance("https://pbi-time-management-default-rtdb.firebaseio.com/");
//        dbRef = database.getReference(USERS_PATH);
//        bIsOpened = true;
//    }
//
//    // Opens the database connection
//    public boolean opendb() {
//        bIsOpened = true;
//        return true;
//    }
//
//    // Checks if a user with a specific pin exists in the database
//    public Task<Boolean> isUserExist(String pin) {
//        TaskCompletionSource<Boolean> taskCompletionSource = new TaskCompletionSource<>();
//        if (!bIsOpened) {
//            taskCompletionSource.setException(new IllegalStateException("Database not opened"));
//            return taskCompletionSource.getTask();
//        }
//        dbRef.orderByChild("pin").equalTo(pin).addListenerForSingleValueEvent(new ValueEventListener() {
//            @Override
//            public void onDataChange(DataSnapshot dataSnapshot) {
//                taskCompletionSource.setResult(dataSnapshot.exists());
//            }
//
//            @Override
//            public void onCancelled(DatabaseError databaseError) {
//                taskCompletionSource.setException(databaseError.toException());
//            }
//        });
//        return taskCompletionSource.getTask();
//    }
//
//    // Deletes a user with a specific pin from the database
//    public Task<Void> deleteUser(String pin) {
//        TaskCompletionSource<Void> taskCompletionSource = new TaskCompletionSource<>();
//        if (!bIsOpened) {
//            taskCompletionSource.setException(new IllegalStateException("Database not opened"));
//            return taskCompletionSource.getTask();
//        }
//
//        dbRef.orderByChild("pin").equalTo(pin).addListenerForSingleValueEvent(new ValueEventListener() {
//            @Override
//            public void onDataChange(DataSnapshot dataSnapshot) {
//                if (dataSnapshot.exists()) {
//                    for (DataSnapshot userSnapshot : dataSnapshot.getChildren()) {
//                        userSnapshot.getRef().removeValue()
//                                .addOnSuccessListener(aVoid -> taskCompletionSource.setResult(null))
//                                .addOnFailureListener(taskCompletionSource::setException);
//                    }
//                } else {
//                    taskCompletionSource.setException(new IllegalArgumentException("User not found"));
//                }
//            }
//
//            @Override
//            public void onCancelled(DatabaseError databaseError) {
//                taskCompletionSource.setException(databaseError.toException());
//            }
//        });
//        return taskCompletionSource.getTask();
//    }
//
//    // Clears all users from the database
//    public Task<Void> clear() {
//        if (!bIsOpened) {
//            TaskCompletionSource<Void> taskCompletionSource = new TaskCompletionSource<>();
//            taskCompletionSource.setException(new IllegalStateException("Database not opened"));
//            return taskCompletionSource.getTask();
//        }
//        return dbRef.removeValue();
//    }
//
//    // Updates the feature of a user with a specific pin
//    public Task<Void> modifyUser(String pin, String feature) {
//        TaskCompletionSource<Void> taskCompletionSource = new TaskCompletionSource<>();
//        if (!bIsOpened) {
//            taskCompletionSource.setException(new IllegalStateException("Database not opened"));
//            return taskCompletionSource.getTask();
//        }
//
//        dbRef.orderByChild("pin").equalTo(pin).addListenerForSingleValueEvent(new ValueEventListener() {
//            @Override
//            public void onDataChange(DataSnapshot dataSnapshot) {
//                if (dataSnapshot.exists()) {
//                    for (DataSnapshot userSnapshot : dataSnapshot.getChildren()) {
//                        userSnapshot.getRef().child("feature").setValue(feature)
//                                .addOnSuccessListener(aVoid -> taskCompletionSource.setResult(null))
//                                .addOnFailureListener(taskCompletionSource::setException);
//                    }
//                } else {
//                    taskCompletionSource.setException(new IllegalArgumentException("User not found"));
//                }
//            }
//
//            @Override
//            public void onCancelled(DatabaseError databaseError) {
//                taskCompletionSource.setException(databaseError.toException());
//            }
//        });
//        return taskCompletionSource.getTask();
//    }
//
//    // Returns the count of users in the database
//    public Task<Integer> getCount() {
//        TaskCompletionSource<Integer> taskCompletionSource = new TaskCompletionSource<>();
//        if (!bIsOpened) {
//            taskCompletionSource.setException(new IllegalStateException("Database not opened"));
//            return taskCompletionSource.getTask();
//        }
//
//        dbRef.addListenerForSingleValueEvent(new ValueEventListener() {
//            @Override
//            public void onDataChange(DataSnapshot dataSnapshot) {
//                taskCompletionSource.setResult((int) dataSnapshot.getChildrenCount());
//            }
//
//            @Override
//            public void onCancelled(DatabaseError databaseError) {
//                taskCompletionSource.setException(databaseError.toException());
//            }
//        });
//        return taskCompletionSource.getTask();
//    }
//
//    // Inserts a new user into the database
//    public Task<Void> insertUser(String pin, String feature) {
//        TaskCompletionSource<Void> taskCompletionSource = new TaskCompletionSource<>();
//        if (!bIsOpened) {
//            taskCompletionSource.setException(new IllegalStateException("Database not opened"));
//            return taskCompletionSource.getTask();
//        }
//
//        HashMap<String, Object> userValues = new HashMap<>();
//        userValues.put("pin", pin);
//        userValues.put("feature", feature);
//
//        String newKey = dbRef.push().getKey();
//        if (newKey == null) {
//            taskCompletionSource.setException(new IllegalStateException("Failed to generate a new key"));
//            return taskCompletionSource.getTask();
//        }
//
//        dbRef.child(newKey).setValue(userValues)
//                .addOnSuccessListener(aVoid -> taskCompletionSource.setResult(null))
//                .addOnFailureListener(taskCompletionSource::setException);
//
//        return taskCompletionSource.getTask();
//    }
//
//    // Queries and returns all users in the database as a HashMap
//    public Task<HashMap<String, String>> queryUserList() {
//        TaskCompletionSource<HashMap<String, String>> taskCompletionSource = new TaskCompletionSource<>();
//        if (!bIsOpened) {
//            taskCompletionSource.setException(new IllegalStateException("Database not opened"));
//            return taskCompletionSource.getTask();
//        }
//
//        dbRef.addListenerForSingleValueEvent(new ValueEventListener() {
//            @Override
//            public void onDataChange(DataSnapshot dataSnapshot) {
//                HashMap<String, String> map = new HashMap<>();
//                for (DataSnapshot userSnapshot : dataSnapshot.getChildren()) {
//                    String pin = userSnapshot.child("pin").getValue(String.class);
//                    String feature = userSnapshot.child("feature").getValue(String.class);
//                    if (pin != null && feature != null) {
//                        map.put(pin, feature);
//                    }
//                }
//                taskCompletionSource.setResult(map.isEmpty() ? null : map);
//            }
//
//            @Override
//            public void onCancelled(DatabaseError databaseError) {
//                taskCompletionSource.setException(databaseError.toException());
//            }
//        });
//        return taskCompletionSource.getTask();
//    }
//
//    // Closes the database connection
//    public void closeDB() {
//        bIsOpened = false;
//    }
//}



//With API's already defined


package pbi_time;

import android.content.Context;
import pbi_time.API_Services.UserApi;
import pbi_time.models.CanAddFingerModel;
import retrofit2.Callback;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DBManager {

    private UserApi userApi;
    private boolean bIsOpened = false;

    public DBManager(Context context) {
        // Initialize Retrofit instance and UserApi
        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl("https://your-api-url.com") // Use the actual base URL of your API
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        userApi = retrofit.create(UserApi.class);
        bIsOpened = true;
    }

    public boolean opendb() {
        bIsOpened = true;
        return true;
    }

    // Check if a user can add fingerprints by email
    public void canAddFinger(String email, Callback<CanAddFingerModel<Boolean>> callback) {
        if (!bIsOpened) {
            callback.onFailure(null, new Exception("Database not opened"));
            return;
        }
        userApi.canAddFinger(email);
    }

    // Insert a new user with fingerprint data
    public void insertUser(HashMap<String, Object> userData, Callback<Void> callback) {
        if (!bIsOpened) {
            callback.onFailure(null, new Exception("Database not opened"));
            return;
        }
        userApi.insertUser(userData).enqueue(callback);
    }

    // Delete a user by email
    public void deleteUser(String email, Callback<Void> callback) {
        if (!bIsOpened) {
            callback.onFailure(null, new Exception("Database not opened"));
            return;
        }
        userApi.deleteUser(email).enqueue(callback);
    }

    // Get the list of all users
    public void getUserList(Callback<HashMap<String, Object>> callback) {
        if (!bIsOpened) {
            callback.onFailure(null, new Exception("Database not opened"));
            return;
        }
        userApi.getUserList().enqueue(callback);
    }

    // Clear all users from the system
    public void clearAllUsers(Callback<Void> callback) {
        if (!bIsOpened) {
            callback.onFailure(null, new Exception("Database not opened"));
            return;
        }
        userApi.clearAllUsers().enqueue(callback);
    }

    // Query a list of users
    public void queryUserList(Callback<List<Map<String, String>>> callback) {
        if (!bIsOpened) {
            callback.onFailure(null, new Exception("Database not opened"));
            return;
        }
        userApi.queryUserList().enqueue(callback);
    }

    // Close the DB connection
    public void closeDB() {
        bIsOpened = false;
    }
}
