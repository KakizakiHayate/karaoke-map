import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/place_result.dart';
import '../../services/places_service.dart';
import '../../services/saved_place_service.dart';
import '../../app_state.dart';
import '../../theme/app_theme.dart';

typedef SavedStateChangedCallback = void Function(String placeId, bool isSaved);

class PlaceInfoWindow extends StatefulWidget {
  final List<PlaceResult> places;
  final int selectedIndex;
  final Function(int) onPageChanged;
  final SavedStateChangedCallback? onSavedStateChanged;

  const PlaceInfoWindow({
    super.key,
    required this.places,
    required this.selectedIndex,
    required this.onPageChanged,
    this.onSavedStateChanged,
  });

  @override
  PlaceInfoWindowState createState() => PlaceInfoWindowState();
}

class PlaceInfoWindowState extends State<PlaceInfoWindow> {
  final SavedPlaceService _savedPlaceService = SavedPlaceService();
  final Set<String> _savedPlaceIds = {};

  @override
  void initState() {
    super.initState();
    _checkSavedPlaces();
  }

  @override
  void didUpdateWidget(PlaceInfoWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 表示される場所が変更された場合、保存状態を再確認
    if (widget.places != oldWidget.places ||
        widget.selectedIndex != oldWidget.selectedIndex) {
      _checkSavedPlaces();
    }
  }

  // 表示中の場所が保存済みかどうか確認する
  Future<void> _checkSavedPlaces() async {
    final userId = context.read<AppState>().userId;
    if (userId == null) return;

    _savedPlaceIds.clear();

    for (final place in widget.places) {
      final isSaved =
          await _savedPlaceService.isPlaceSaved(userId, place.placeId);
      if (isSaved) {
        setState(() {
          _savedPlaceIds.add(place.placeId);
        });
      }
    }
  }

  // 保存状態を外部から更新するメソッド
  void updateSavedState(String placeId, bool isSaved) {
    if (isSaved && !_savedPlaceIds.contains(placeId)) {
      setState(() {
        _savedPlaceIds.add(placeId);
      });
    } else if (!isSaved && _savedPlaceIds.contains(placeId)) {
      setState(() {
        _savedPlaceIds.remove(placeId);
      });
    }
  }

  // 場所を保存または削除する
  Future<void> _toggleSavePlace(PlaceResult place) async {
    final userId = context.read<AppState>().userId;
    if (userId == null) return;

    final isSaved = _savedPlaceIds.contains(place.placeId);

    if (isSaved) {
      // 削除処理
      final success =
          await _savedPlaceService.deleteSavedPlace(userId, place.placeId);
      if (success) {
        setState(() {
          _savedPlaceIds.remove(place.placeId);
        });

        // 保存状態の変更を通知
        widget.onSavedStateChanged?.call(place.placeId, false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存済みリストから削除しました'),
              backgroundColor: AppTheme.primaryBlue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // 保存処理
      await _savedPlaceService.savePlace(userId, place);
      setState(() {
        _savedPlaceIds.add(place.placeId);
      });

      // 保存状態の変更を通知
      widget.onSavedStateChanged?.call(place.placeId, true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存済みリストに追加しました'),
            backgroundColor: AppTheme.primaryBlue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180, // カードの高さを大きくする
      child: PageView.builder(
        controller: PageController(
          viewportFraction: 0.90, // ビューポートの90%を表示
          initialPage: widget.selectedIndex,
        ),
        onPageChanged: widget.onPageChanged,
        itemCount: widget.places.length,
        itemBuilder: (context, index) {
          final place = widget.places[index];
          final isSaved = _savedPlaceIds.contains(place.placeId);

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
                        // 店舗名と保存アイコン
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                place.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 保存状態アイコン
                            InkWell(
                              onTap: () => _toggleSavePlace(place),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                size: 22,
                                color: isSaved
                                    ? AppTheme.primaryBlue
                                    : Colors.grey,
                              ),
                            ),
                          ],
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
                            _buildActionButton(
                              context,
                              icon: isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: AppTheme.primaryBlue,
                              onTap: () => _toggleSavePlace(place),
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
