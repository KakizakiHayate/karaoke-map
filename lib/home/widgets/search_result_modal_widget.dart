import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 店名とレビュー情報
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        result.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (result.getDistanceText().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00AEEF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.directions_walk,
                              size: 14,
                              color: Color(0xFF00AEEF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              result.getDistanceText(),
                              style: const TextStyle(
                                color: Color(0xFF00AEEF),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
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
                          color: const Color(0xFF00AEEF),
                        );
                      }),
                    ),
                    const SizedBox(width: 4),
                    // 評価点数
                    Text(
                      result.rating.toString(),
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // レビュー数
                    Text(
                      '(${result.userRatingsTotal})',
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 店舗画像
          if (result.photoReference != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              child: Image.network(
                PlacesService().getPhotoUrl(result.photoReference!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              child: Image.asset(
                'assets/images/no_image.png',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          // 営業時間と住所
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                      color: result.isOpenNow == true
                          ? Colors.green
                          : const Color(0xFFE4002B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.isOpenNow == true ? '営業中' : '営業時間外',
                      style: TextStyle(
                        color: result.isOpenNow == true
                            ? Colors.green
                            : const Color(0xFFE4002B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.getOpeningHoursText(),
                      style: TextStyle(
                        color: result.isOpenNow == true
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFE4002B),
                      ),
                    ),
                  ],
                ),
                // 住所
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFF00AEEF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.address,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 14,
                        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text('ここにいく',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => _openInMaps(result),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AEEF),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (result.website != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.language, color: Color(0xFF00AEEF)),
                    label: const Text('ウェブサイト',
                        style: TextStyle(color: Color(0xFF00AEEF))),
                    onPressed: () => _launchUrl(result.website!),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00AEEF)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share, color: Color(0xFF00AEEF)),
                  label: const Text('共有',
                      style: TextStyle(color: Color(0xFF00AEEF))),
                  onPressed: () => _sharePlace(result),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00AEEF)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (result.phoneNumber != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.phone, color: Color(0xFF00AEEF)),
                    label: const Text('電話',
                        style: TextStyle(color: Color(0xFF00AEEF))),
                    onPressed: () => _callPhone(result.phoneNumber!),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00AEEF)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
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
    await Share.share(
      'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}',
      subject: place.name,
    );
  }

  Future<void> _callPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
