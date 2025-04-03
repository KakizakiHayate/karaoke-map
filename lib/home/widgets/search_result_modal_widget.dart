import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/place_result.dart';
import '../../services/places_service.dart';

class SearchResultModalWidget extends StatefulWidget {
  final ScrollController scrollController;
  final List<PlaceResult> searchResults;

  const SearchResultModalWidget({
    super.key,
    required this.scrollController,
    required this.searchResults,
  });

  @override
  State<SearchResultModalWidget> createState() =>
      _SearchResultModalWidgetState();
}

class _SearchResultModalWidgetState extends State<SearchResultModalWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // グラバー
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 検索中のインジケータまたは検索結果
          Expanded(
            child: widget.searchResults.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: widget.searchResults.length,
                    itemBuilder: (context, index) {
                      final result = widget.searchResults[index];
                      return _buildResultCard(context, result);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, PlaceResult result) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 店名とレビュー情報
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                // レビュー情報
                Row(
                  children: [
                    // 星の表示
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < result.rating.floor()
                              ? Icons.star
                              : index < result.rating
                                  ? Icons.star_half
                                  : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        );
                      }),
                    ),
                    const SizedBox(width: 4),
                    // 評価点数
                    Text(
                      result.rating.toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // レビュー数
                    Text(
                      '(${result.userRatingsTotal})',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // 距離表示
                if (result.getDistanceText().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      result.getDistanceText(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
              ],
            ),
          ),

          // 店舗画像
          if (result.photoReference != null)
            Image.network(
              PlacesService().getPhotoUrl(result.photoReference!),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          else
            Image.asset(
              'assets/images/no_image.png', // デフォルト画像を追加する必要があります
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

          // 営業時間と住所
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 営業時間
                Row(
                  children: [
                    Icon(
                      result.isOpenNow == true
                          ? Icons.check_circle
                          : Icons.access_time,
                      size: 16,
                      color:
                          result.isOpenNow == true ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.isOpenNow == true ? '営業中' : '営業時間外',
                      style: TextStyle(
                        color: result.isOpenNow == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.getOpeningHoursText(),
                      style: TextStyle(
                        color:
                            result.isOpenNow == true ? Colors.grey : Colors.red,
                      ),
                    ),
                  ],
                ),
                // 住所
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.address,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // アクションボタン
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text('ここにいく'),
                  onPressed: () => _openInMaps(result),
                ),
                if (result.website != null)
                  TextButton.icon(
                    icon: const Icon(Icons.language),
                    label: const Text('ウェブサイト'),
                    onPressed: () => _launchUrl(result.website!),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('共有'),
                  onPressed: () => _sharePlace(result),
                ),
                if (result.phoneNumber != null)
                  TextButton.icon(
                    icon: const Icon(Icons.phone),
                    label: const Text('電話'),
                    onPressed: () => _callPhone(result.phoneNumber!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(PlaceResult place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _sharePlace(PlaceResult place) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}';
    // Share.shareの実装が必要です
  }

  Future<void> _callPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
