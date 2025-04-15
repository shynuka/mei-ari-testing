import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';

part 'get_location_state.dart';

class GetLocationCubit extends Cubit<GetLocationState> {
  GetLocationCubit() : super(GetLocationInitial());

  static GetLocationCubit get(context) => BlocProvider.of(context);

  Position? position; // ✅ Nullable to prevent uninitialized access
  Placemark? place; // ✅ Nullable to prevent LateInitializationError

  /// Initialize location services
  Future<void> initLocation() async {
    bool isServiceEnabled;
    LocationPermission permission;

    isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();

    if (!isServiceEnabled) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permission denied forever');
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied');
      }
    }
  }

  /// Get the current location
  Future<Position?> getLocation() async {
    try {
      Position loc = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      position = loc; // ✅ Ensure position is assigned
      return position;
    } catch (error) {
      emit(LocationFail("Error fetching location: $error"));
      return null;
    }
  }

  /// Get the country and city based on coordinates
  Future<Placemark?> getCountry() async {
    emit(LocationLoading());

    try {
      Position? loc = await getLocation();

      if (loc == null) {
        emit(LocationFail("Location not available"));
        return null;
      }

      List<Placemark> places = await placemarkFromCoordinates(
        loc.latitude,
        loc.longitude,
      );

      if (places.isNotEmpty) {
        place = places[0]; // ✅ Assign `place`
        emit(LocationSuccess());
        return place;
      } else {
        emit(LocationFail("No location found."));
        return null;
      }
    } catch (error) {
      emit(LocationFail("Error fetching location: $error"));
      return null;
    }
  }
}
