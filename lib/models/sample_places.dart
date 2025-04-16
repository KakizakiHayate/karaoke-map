import 'place_result.dart';

/// サンプルの検索結果データを提供するクラス
class SamplePlaces {
  /// サンプル画像のパス
  static const String sampleImagePath =
      'assets/images/sample_search_result_image.jpg';

  /// 著作権の問題がないサンプルのカラオケ店データを取得
  static List<PlaceResult> getSamplePlaces() {
    return [
      PlaceResult(
        placeId: 'sample_place_1',
        name: 'サンプルカラオケ 新宿店',
        address: '東京都新宿区新宿3-1-1',
        photoReference: sampleImagePath, // サンプル画像を使用
        rating: 4.2,
        userRatingsTotal: 128,
        lat: 35.689722,
        lng: 139.700333,
        phoneNumber: '03-1234-5678',
        website: 'https://example.com/karaoke1',
        openingHours: {
          'open': '1100',
          'close': '2300',
        },
        isOpenNow: true,
        distance: 350,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_2',
        name: 'カラオケサンプル 渋谷店',
        address: '東京都渋谷区道玄坂2-2-2',
        photoReference: sampleImagePath,
        rating: 4.0,
        userRatingsTotal: 95,
        lat: 35.658034,
        lng: 139.701636,
        phoneNumber: '03-8765-4321',
        website: 'https://example.com/karaoke2',
        openingHours: {
          'open': '1000',
          'close': '0500',
        },
        isOpenNow: true,
        distance: 520,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_3',
        name: 'サンプル歌屋 池袋店',
        address: '東京都豊島区東池袋1-1-1',
        photoReference: sampleImagePath,
        rating: 3.8,
        userRatingsTotal: 67,
        lat: 35.729503,
        lng: 139.711665,
        phoneNumber: '03-5555-1234',
        website: null,
        openingHours: {
          'open': '1200',
          'close': '2330',
        },
        isOpenNow: false,
        distance: 780,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_4',
        name: 'テストカラオケ 銀座店',
        address: '東京都中央区銀座4-4-4',
        photoReference: sampleImagePath,
        rating: 4.5,
        userRatingsTotal: 210,
        lat: 35.673992,
        lng: 139.767531,
        phoneNumber: '03-1111-2222',
        website: 'https://example.com/karaoke4',
        openingHours: {
          'open': '0000',
          'close': '0000',
        },
        isOpenNow: true,
        distance: 630,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_5',
        name: 'サンプルボイス 秋葉原店',
        address: '東京都千代田区外神田1-1-1',
        photoReference: sampleImagePath,
        rating: 3.9,
        userRatingsTotal: 85,
        lat: 35.698683,
        lng: 139.771883,
        phoneNumber: '03-2222-3333',
        website: 'https://example.com/karaoke5',
        openingHours: {
          'open': '1300',
          'close': '2200',
        },
        isOpenNow: true,
        distance: 450,
        distanceType: 'current',
      ),
      // 追加データ
      PlaceResult(
        placeId: 'sample_place_6',
        name: 'デモカラオケ 六本木店',
        address: '東京都港区六本木6-6-6',
        photoReference: sampleImagePath,
        rating: 4.7,
        userRatingsTotal: 176,
        lat: 35.659912,
        lng: 139.729265,
        phoneNumber: '03-6666-6666',
        website: 'https://example.com/karaoke6',
        openingHours: {
          'open': '1200',
          'close': '0600',
        },
        isOpenNow: true,
        distance: 800,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_7',
        name: 'テスト歌謡館 上野店',
        address: '東京都台東区上野7-7-7',
        photoReference: sampleImagePath,
        rating: 3.5,
        userRatingsTotal: 42,
        lat: 35.712673,
        lng: 139.773822,
        phoneNumber: '03-7777-7777',
        website: null,
        openingHours: {
          'open': '1400',
          'close': '2400',
        },
        isOpenNow: false,
        distance: 950,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_8',
        name: 'サンプル歌の広場 品川店',
        address: '東京都港区高輪4-8-8',
        photoReference: sampleImagePath,
        rating: 4.1,
        userRatingsTotal: 103,
        lat: 35.628462,
        lng: 139.738619,
        phoneNumber: '03-8888-8888',
        website: 'https://example.com/karaoke8',
        openingHours: {
          'open': '1100',
          'close': '2200',
        },
        isOpenNow: true,
        distance: 1100,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_9',
        name: 'デモ音楽館 恵比寿店',
        address: '東京都渋谷区恵比寿西1-9-9',
        photoReference: sampleImagePath,
        rating: 4.3,
        userRatingsTotal: 87,
        lat: 35.646691,
        lng: 139.708376,
        phoneNumber: '03-9999-9999',
        website: 'https://example.com/karaoke9',
        openingHours: {
          'open': '1300',
          'close': '2330',
        },
        isOpenNow: true,
        distance: 1250,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_10',
        name: 'サンプルソング 浅草店',
        address: '東京都台東区浅草1-10-10',
        photoReference: sampleImagePath,
        rating: 3.9,
        userRatingsTotal: 64,
        lat: 35.712438,
        lng: 139.796858,
        phoneNumber: '03-1010-1010',
        website: null,
        openingHours: {
          'open': '1000',
          'close': '2200',
        },
        isOpenNow: false,
        distance: 1500,
        distanceType: 'current',
      ),
      // さらにサンプルデータを追加
      PlaceResult(
        placeId: 'sample_place_11',
        name: 'テストボーカル 東京駅前店',
        address: '東京都千代田区丸の内1-11-11',
        photoReference: sampleImagePath,
        rating: 4.6,
        userRatingsTotal: 132,
        lat: 35.681236,
        lng: 139.767125,
        phoneNumber: '03-1111-1111',
        website: 'https://example.com/karaoke11',
        openingHours: {
          'open': '1100',
          'close': '2300',
        },
        isOpenNow: true,
        distance: 250,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_12',
        name: 'サンプル歌声 高田馬場店',
        address: '東京都新宿区高田馬場4-12-12',
        photoReference: sampleImagePath,
        rating: 3.7,
        userRatingsTotal: 78,
        lat: 35.712056,
        lng: 139.704454,
        phoneNumber: '03-1212-1212',
        website: null,
        openingHours: {
          'open': '1300',
          'close': '2230',
        },
        isOpenNow: true,
        distance: 870,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_13',
        name: 'カラオケテスト 目黒店',
        address: '東京都品川区上大崎3-13-13',
        photoReference: sampleImagePath,
        rating: 4.0,
        userRatingsTotal: 92,
        lat: 35.633998,
        lng: 139.715828,
        phoneNumber: '03-1313-1313',
        website: 'https://example.com/karaoke13',
        openingHours: {
          'open': '1200',
          'close': '2300',
        },
        isOpenNow: true,
        distance: 1300,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_14',
        name: 'デモ歌の館 中野店',
        address: '東京都中野区中野5-14-14',
        photoReference: sampleImagePath,
        rating: 3.6,
        userRatingsTotal: 54,
        lat: 35.708030,
        lng: 139.665218,
        phoneNumber: '03-1414-1414',
        website: null,
        openingHours: {
          'open': '1400',
          'close': '2330',
        },
        isOpenNow: false,
        distance: 1450,
        distanceType: 'current',
      ),
      PlaceResult(
        placeId: 'sample_place_15',
        name: 'サンプルカラオケBOX 代々木店',
        address: '東京都渋谷区代々木1-15-15',
        photoReference: sampleImagePath,
        rating: 4.2,
        userRatingsTotal: 113,
        lat: 35.683061,
        lng: 139.702042,
        phoneNumber: '03-1515-1515',
        website: 'https://example.com/karaoke15',
        openingHours: {
          'open': '1100',
          'close': '0500',
        },
        isOpenNow: true,
        distance: 680,
        distanceType: 'current',
      ),
    ];
  }

  /// 駅周辺の検索結果向けサンプルデータ
  static List<PlaceResult> getStationSamplePlaces(String stationName) {
    final baseList = getSamplePlaces();

    // 駅名に合わせて位置や距離を少し調整したデータを作成
    return baseList.map((place) {
      return PlaceResult(
        placeId: place.placeId,
        name: place.name,
        address: place.address,
        photoReference: sampleImagePath, // サンプル画像を使用
        rating: place.rating,
        userRatingsTotal: place.userRatingsTotal,
        lat: place.lat + 0.001, // 少しずらす
        lng: place.lng - 0.001, // 少しずらす
        phoneNumber: place.phoneNumber,
        website: place.website,
        openingHours: place.openingHours,
        isOpenNow: place.isOpenNow,
        distance: place.distance! * 0.8, // 駅近として距離を短くする
        distanceType: 'station',
        stationName: stationName,
      );
    }).toList();
  }

  /// サンプルの店舗詳細データを取得
  static PlaceResult getSamplePlaceDetail(String placeId) {
    final places = getSamplePlaces();
    for (final place in places) {
      if (place.placeId == placeId) {
        return place;
      }
    }

    // 該当するIDがない場合は最初のデータを返す
    return places.first;
  }
}
