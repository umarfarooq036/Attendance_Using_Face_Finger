//package pbi_time.API_Services;
//
//import retrofit2.Call;
//import retrofit2.http.*;
//
//import java.util.HashMap;
//
//public interface UserApi {
//
//    // Method to check if a user can add fingerprints (based on email)
//    @GET("EmployeeManagement/CanAddFinger")
//    Call<Boolean> canAddFinger(@Query("email") String email);
//
//    // Method to insert a new user with the user's fingerprint data
//    @POST("EmployeeManagement/AddFingers")
//    Call<Void> insertUser(@Body HashMap<String, Object> body);
//
//    // Method to delete a user based on email
//    @DELETE("EmployeeManagement/DeleteUser")
//    Call<Void> deleteUser(@Query("email") String email);
//
//    // Method to fetch the list of all users
//    @GET("EmployeeManagement/Users")
//    Call<HashMap<String, Object>> getUserList();
//
//    // Method to clear all users from the system
//    @DELETE("EmployeeManagement/ClearAll")
//    Call<Void> clearAllUsers();
//}



package pbi_time.API_Services;

import retrofit2.Call;
import retrofit2.http.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public interface UserApi {

    // Method to check if a user can add fingerprints (based on email)
    @GET("EmployeeManagement/CanAddFinger")
    Call<Boolean> canAddFinger(@Query("email") String email);

    // Method to insert a new user with the user's fingerprint data
    @POST("EmployeeManagement/AddFingers")
    Call<Void> insertUser(@Body HashMap<String, Object> body);

    // Method to delete a user based on email
    @DELETE("EmployeeManagement/DeleteUser")
    Call<Void> deleteUser(@Query("email") String email);

    // Method to fetch the list of all users
    @GET("EmployeeManagement/Users")
    Call<HashMap<String, Object>> getUserList();

    // Method to clear all users from the system
    @DELETE("EmployeeManagement/ClearAll")
    Call<Void> clearAllUsers();

    // Method to query a list of users (GET request)
    @GET("EmployeeManagement/Users")
    Call<List<Map<String, String>>> queryUserList();
}
