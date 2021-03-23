// import 'package:geolocator/geolocator.dart';
// import 'package:geocoder/geocoder.dart';

// class UserLocation {
//   Future<String> getUserLocation() async {
//     Position position = await Geolocator.getLastKnownPosition();

//     if (position == null) {
//       await Geolocator.requestPermission();
//       position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.low);
//     }

//     //  print(position.latitude.toString());

//     final coordinates = new Coordinates(position.latitude, position.longitude);
//     var addresses =
//         await Geocoder.local.findAddressesFromCoordinates(coordinates);
//     var first = addresses.first;

//     var completeAdress = first.addressLine.toString().split(',');

//     var i = completeAdress.length;

//     var location = completeAdress[i - 3] +
//         ', ' +
//         completeAdress[i - 2] +
//         ', ' +
//         completeAdress[i - 1];

//     return location;
//     //"${first.featureName} : ${first.addressLine}";
//   }
// }
