// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// class LocationService {
//   static final LocationService _instance = LocationService._internal();
//   factory LocationService() => _instance;
//   LocationService._internal();
//
//   Future<bool> _handlePermission() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return false;
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return false;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       return false;
//     }
//
//     return true;
//   }
//
//   bool _isPlusCode(String? text) {
//     if (text == null) return false;
//     // Plus codes usually contain "+" and are alphanumeric
//     return text.contains('+') && RegExp(r'^[A-Z0-9+]+$').hasMatch(text);
//   }
//
//   Future<Map<String, dynamic>> getCurrentLocation() async {
//     try {
//       final hasPermission = await _handlePermission();
//       if (!hasPermission) {
//         return {
//           'error': 'Location permissions are denied',
//           'success': false,
//         };
//       }
//
//       // Get precise location
//       final Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.bestForNavigation,
//       );
//
//       // Try to get address from multiple sources for better accuracy
//       List<Placemark> placemarks = [];
//
//       // First attempt with high accuracy
//       placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//         // localeIdentifier: 'en',
//       );
//
//       // If first attempt didn't give good results, try with different accuracy
//       if (placemarks.isEmpty || _isPlusCode(placemarks[0].name)) {
//         try {
//           final List<Placemark> secondAttempt = await placemarkFromCoordinates(
//             position.latitude,
//             position.longitude,
//             // localeIdentifier: 'en',
//           );
//           if (secondAttempt.isNotEmpty && !_isPlusCode(secondAttempt[0].name)) {
//             placemarks = secondAttempt;
//           }
//         } catch (e) {
//           // Keep original placemarks if second attempt fails
//         }
//       }
//
//       if (placemarks.isEmpty) {
//         return {
//           'error': 'Could not get address',
//           'success': false,
//         };
//       }
//
//       final Placemark place = placemarks[0];
//
//       // Construct detailed address components
//       final List<String> addressComponents = [];
//
//       // Skip plus codes and prioritize actual address components
//       if (place.subThoroughfare != null &&
//           place.subThoroughfare!.isNotEmpty &&
//           !_isPlusCode(place.subThoroughfare)) {
//         addressComponents.add(place.subThoroughfare!);
//       }
//
//       if (place.thoroughfare != null &&
//           place.thoroughfare!.isNotEmpty &&
//           !_isPlusCode(place.thoroughfare)) {
//         addressComponents.add(place.thoroughfare!);
//       }
//
//       // Add neighborhood/area
//       if (place.subLocality != null &&
//           place.subLocality!.isNotEmpty &&
//           !_isPlusCode(place.subLocality)) {
//         addressComponents.add(place.subLocality!);
//       }
//
//       // Add city
//       if (place.locality != null &&
//           place.locality!.isNotEmpty &&
//           !_isPlusCode(place.locality)) {
//         addressComponents.add(place.locality!);
//       }
//
//       // Add state/province
//       if (place.administrativeArea != null &&
//           place.administrativeArea!.isNotEmpty &&
//           !_isPlusCode(place.administrativeArea)) {
//         addressComponents.add(place.administrativeArea!);
//       }
//
//       // Add country
//       if (place.country != null &&
//           place.country!.isNotEmpty &&
//           !_isPlusCode(place.country)) {
//         addressComponents.add(place.country!);
//       }
//
//       // If we still don't have a proper street address, try to get a better one
//       if (addressComponents.isEmpty ||
//           (addressComponents[0].contains('+') && addressComponents[0].length < 10)) {
//         // Fallback to get more detailed address
//         try {
//           final List<Placemark> detailedPlacemarks = await placemarkFromCoordinates(
//             position.latitude + 0.0001, // Slight offset to get nearby address
//             position.longitude + 0.0001,
//             // localeIdentifier: 'en',
//           );
//
//           if (detailedPlacemarks.isNotEmpty) {
//             final detailedPlace = detailedPlacemarks[0];
//             if (!_isPlusCode(detailedPlace.name ?? '') &&
//                 detailedPlace.name != null &&
//                 detailedPlace.name!.isNotEmpty) {
//               addressComponents.insert(0, detailedPlace.name!);
//             }
//           }
//         } catch (e) {
//           // Keep original address if fallback fails
//         }
//       }
//
//       // Create formatted address strings
//       String fullAddress = addressComponents.join(', ');
//
//       // If we still have a plus code, add a note
//       if (_isPlusCode(addressComponents.firstOrNull)) {
//         fullAddress += ' (Approximate location)';
//       }
//
//       return {
//         'success': true,
//         'coordinates': {
//           'latitude': position.latitude,
//           'longitude': position.longitude,
//           'accuracy': position.accuracy,
//           'altitude': position.altitude,
//         },
//         'address': {
//           'streetAddress': addressComponents.firstOrNull,
//           'subLocality': place.subLocality,
//           'locality': place.locality,
//           'administrativeArea': place.administrativeArea,
//           'country': place.country,
//           'fullAddress': fullAddress,
//           'isPlusCode': _isPlusCode(addressComponents.firstOrNull),
//           'rawComponents': addressComponents,
//         },
//         'timestamp': DateTime.now().toIso8601String(),
//       };
//     } catch (e) {
//       return {
//         'error': e.toString(),
//         'success': false,
//       };
//     }
//   }
// }




import 'package:location/location.dart' as location ;
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final _location = location.Location();

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    PermissionStatus permissionStatus;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  Future<Map<String, dynamic>> getCurrentLocationAddress() async {
    try {
      final hasPermission = await _handlePermission();
      if (!hasPermission) {
        return {
          'error': 'Location permissions are denied',
          'success': false,
        };
      }

      // Get current location
      final LocationData locationData = await _location.getLocation();

      // Get address from coordinates
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      if (placemarks.isEmpty) {
        return {
          'error': 'Could not get address',
          'success': false,
        };
      }

      final place = placemarks[0];

      // Create formatted address
      final List<String> addressComponents = [];

      // Add each component if it exists and isn't empty
      if (place.name != null && place.name!.isNotEmpty && place.name != place.street) {
        addressComponents.add(place.name!);
      }

      if (place.street != null && place.street!.isNotEmpty) {
        addressComponents.add(place.street!);
      }

      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressComponents.add(place.subLocality!);
      }

      if (place.locality != null && place.locality!.isNotEmpty) {
        addressComponents.add(place.locality!);
      }

      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressComponents.add(place.administrativeArea!);
      }

      if (place.country != null && place.country!.isNotEmpty) {
        addressComponents.add(place.country!);
      }

      String formattedAddress = addressComponents.join(', ');

      return {
        'success': true,
        'coordinates': {
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
        },
        'address': formattedAddress,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'success': false,
      };
    }
  }
}