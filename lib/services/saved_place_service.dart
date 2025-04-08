import '../models/saved_place.dart';
import '../models/place_result.dart';
import 'database_helper.dart';

class SavedPlaceService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // 場所を保存する
  Future<SavedPlace> savePlace(int userId, PlaceResult place) async {
    final savedPlace = SavedPlace(
      userId: userId,
      placeId: place.placeId,
      name: place.name,
      address: place.address,
      photoReference: place.photoReference,
      rating: place.rating,
      userRatingsTotal: place.userRatingsTotal,
      lat: place.lat,
      lng: place.lng,
      phoneNumber: place.phoneNumber,
      website: place.website,
    );

    return await _db.createSavedPlace(savedPlace);
  }

  // 場所が保存済みかどうか確認する
  Future<bool> isPlaceSaved(int userId, String placeId) async {
    return await _db.isSavedPlace(userId, placeId);
  }

  // ユーザーの保存済み場所を取得する
  Future<List<SavedPlace>> getUserSavedPlaces(int userId) async {
    return await _db.readUserSavedPlaces(userId);
  }

  // 保存済み場所を削除する
  Future<bool> deleteSavedPlace(int userId, String placeId) async {
    final result = await _db.deleteSavedPlace(userId, placeId);
    return result > 0;
  }

  // PlaceResultを保存済み場所から作成する
  PlaceResult convertToPlaceResult(SavedPlace savedPlace) {
    return PlaceResult(
      placeId: savedPlace.placeId,
      name: savedPlace.name,
      address: savedPlace.address,
      photoReference: savedPlace.photoReference,
      rating: savedPlace.rating,
      userRatingsTotal: savedPlace.userRatingsTotal,
      lat: savedPlace.lat,
      lng: savedPlace.lng,
      phoneNumber: savedPlace.phoneNumber,
      website: savedPlace.website,
    );
  }
}
