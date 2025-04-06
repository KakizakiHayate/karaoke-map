import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/place_result.dart';
import '../../services/places_service.dart';
import '../../theme/app_theme.dart';

class PlaceInfoWindow extends StatelessWidget {
  final List<PlaceResult> places;
  final int selectedIndex;
  final Function(int) onPageChanged;

  const PlaceInfoWindow({
    super.key,
    required this.places,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180, // カードの高さを大きくする
      child: PageView.builder(
        controller: PageController(
          viewportFraction: 0.90, // ビューポートの90%を表示
          initialPage: selectedIndex,
        ),
        onPageChanged: onPageChanged,
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 左側に店舗の写真を表示
                if (place.photoReference != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      bottomLeft: Radius.circular(12.0),
                    ),
                    child: SizedBox(
                      width: 120,
                      height: 180,
                      child: Image.network(
                        PlacesService().getPhotoUrl(place.photoReference!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.music_note,
                                  size: 40, color: AppTheme.primaryRed),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 120,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        bottomLeft: Radius.circular(12.0),
                      ),
                    ),
                    child: const Center(
                      child:
                          Icon(Icons.music_note, size: 40, color: Colors.white),
                    ),
                  ),
                // 右側に店舗情報を表示
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 店舗名
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // 評価
                        if (place.rating > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${place.rating} (${place.userRatingsTotal}件)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),

                        // 営業時間
                        Row(
                          children: [
                            Icon(
                              place.isOpenNow == true
                                  ? Icons.check_circle
                                  : Icons.access_time,
                              size: 14,
                              color: place.isOpenNow == true
                                  ? Colors.green
                                  : AppTheme.primaryRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              place.isOpenNow == true ? '営業中' : '営業時間外',
                              style: TextStyle(
                                fontSize: 12,
                                color: place.isOpenNow == true
                                    ? Colors.green
                                    : AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.getOpeningHoursText(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // 距離情報
                        if (place.distance != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_walk,
                                size: 14,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place.getDistanceText(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),

                        // 住所
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // アクションボタン
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildActionButton(
                              context,
                              icon: Icons.directions,
                              color: Colors.blue,
                              onTap: () => _openInMaps(place),
                            ),
                            if (place.website != null)
                              _buildActionButton(
                                context,
                                icon: Icons.language,
                                color: Colors.green,
                                onTap: () => _launchUrl(place.website!),
                              ),
                            if (place.phoneNumber != null)
                              _buildActionButton(
                                context,
                                icon: Icons.phone,
                                color: Colors.red,
                                onTap: () => _callPhone(place.phoneNumber!),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 20,
          color: color,
        ),
      ),
    );
  }

  Future<void> _openInMaps(PlaceResult place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  Future<void> _callPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
