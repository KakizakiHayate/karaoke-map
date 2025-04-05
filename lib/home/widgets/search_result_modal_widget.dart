import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/place_result.dart';
import '../../services/places_service.dart';
import '../../theme/app_theme.dart';

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
          // カラオケ店の写真が存在する場合のみ表示
          if (result.photoReference != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                PlacesService().getPhotoUrl(result.photoReference!),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    child: const Center(
                      child: Icon(Icons.image_not_supported),
                    ),
                  );
                },
              ),
            ),

          // 基本情報
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (result.rating > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text('${result.rating}'),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),

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
                          : AppTheme.primaryRed,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.isOpenNow == true ? '営業中' : '営業時間外',
                      style: TextStyle(
                        color: result.isOpenNow == true
                            ? Colors.green
                            : AppTheme.primaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.getOpeningHoursText(),
                      style: TextStyle(
                        color: result.isOpenNow == true
                            ? AppTheme.textPrimary
                            : AppTheme.primaryRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 住所
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.address,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
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
                    backgroundColor: AppTheme.primaryBlue,
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
                    icon: Icon(Icons.language, color: AppTheme.primaryBlue),
                    label: Text('ウェブサイト',
                        style: TextStyle(color: AppTheme.primaryBlue)),
                    onPressed: () => _launchUrl(result.website!),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: Icon(Icons.share, color: AppTheme.primaryBlue),
                  label:
                      Text('共有', style: TextStyle(color: AppTheme.primaryBlue)),
                  onPressed: () => _sharePlace(result),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryBlue),
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
                    icon: Icon(Icons.phone, color: AppTheme.primaryBlue),
                    label: Text('電話',
                        style: TextStyle(color: AppTheme.primaryBlue)),
                    onPressed: () => _callPhone(result.phoneNumber!),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryBlue),
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
