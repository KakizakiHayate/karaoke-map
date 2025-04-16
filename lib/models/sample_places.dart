import 'place_result.dart';

/// サンプルの検索結果データを提供するクラス
class SamplePlaces {
  /// 著作権の問題がないサンプルのカラオケ店データを取得
  static List<PlaceResult> getSamplePlaces() {
    return [
      PlaceResult(
        placeId: 'sample_place_1',
        name: 'サンプルカラオケ 新宿店',
        address: '東京都新宿区新宿3-1-1',
        photoReference: null, // サンプルなので写真なし
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
        photoReference: null,
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
        photoReference: null,
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
        photoReference: null,
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
        photoReference: null,
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
    ];
  }
}
