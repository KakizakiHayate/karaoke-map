import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/place_result.dart';
import '../../services/places_service.dart';
import '../../services/saved_place_service.dart';
import '../../app_state.dart';
import '../../theme/app_theme.dart';

typedef SavedStateChangedCallback = void Function(String placeId, bool isSaved);

class SearchResultModalWidget extends StatefulWidget {
  final ScrollController scrollController;
  final List<PlaceResult> searchResults;
  final bool isLoading;
  final String searchRadius;
  final SavedStateChangedCallback? onSavedStateChanged;

  const SearchResultModalWidget({
    super.key,
    required this.scrollController,
    required this.searchResults,
    required this.isLoading,
    required this.searchRadius,
    this.onSavedStateChanged,
  });

  @override
  SearchResultModalWidgetState createState() => SearchResultModalWidgetState();
}

class SearchResultModalWidgetState extends State<SearchResultModalWidget> {
  final SavedPlaceService _savedPlaceService = SavedPlaceService();
  final PlacesService _placesService = PlacesService();
  // 保存済みの場所のIDを管理するためのセット
  final Set<String> _savedPlaceIds = {};
  // 詳細情報を読み込み中の場所IDを管理
  final Set<String> _loadingDetailsIds = {};
  // 詳細情報が読み込まれた結果を管理
  final Map<String, PlaceResult> _detailedResults = {};

  @override
  void initState() {
    super.initState();
    _checkSavedPlaces();
  }

  @override
  void didUpdateWidget(SearchResultModalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 検索結果が変更された場合、保存状態をリロード
    if (widget.searchResults != oldWidget.searchResults) {
      _checkSavedPlaces();
    }
  }

  // 表示中の場所が保存済みかどうかを確認する
  Future<void> _checkSavedPlaces() async {
    final userId = context.read<AppState>().userId;
    if (userId == null) return;

    _savedPlaceIds.clear();

    for (final place in widget.searchResults) {
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
          // 検索中のインジケータ、検索結果なし、または検索結果リスト
          Expanded(
            child: _buildContentBasedOnState(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBasedOnState() {
    // ローディング中
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('検索中...', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
      );
    }

    // 検索結果がない場合
    if (widget.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              '検索結果がありません',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.searchRadius}m範囲内にはカラオケチェーン店がありません',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '別の場所や検索条件をお試しください',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // 検索結果がある場合
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: widget.searchResults.length,
      itemBuilder: (context, index) {
        final originalResult = widget.searchResults[index];
        // 詳細情報が読み込まれていればそれを使用、そうでなければ元の結果を使用
        final result = _detailedResults[originalResult.placeId] ?? originalResult;
        
        // 表示時に詳細情報を読み込み開始
        _loadPlaceDetails(originalResult);
        
        return _buildResultCard(context, result);
      },
    );
  }

  // 詳細情報を遅延読み込みする
  Future<void> _loadPlaceDetails(PlaceResult place) async {
    // すでに詳細情報が読み込まれている、または読み込み中の場合はスキップ
    if (place.hasDetailsLoaded || 
        _loadingDetailsIds.contains(place.placeId) ||
        _detailedResults.containsKey(place.placeId)) {
      return;
    }

    setState(() {
      _loadingDetailsIds.add(place.placeId);
    });

    try {
      final detailsData = await _placesService.getPlaceDetails(place.placeId);
      
      if (detailsData != null) {
        // 営業時間のパース
        Map<String, String>? openingHours;
        if (detailsData['opening_hours'] != null) {
          final periods = detailsData['opening_hours']['periods'] as List?;
          if (periods != null && periods.isNotEmpty) {
            openingHours = {
              'open': periods[0]['open']?['time'] ?? '',
              'close': periods[0]['close']?['time'] ?? '',
            };
          }
        }

        // 詳細情報付きのPlaceResultを作成
        final detailedPlace = place.withDetails(
          phoneNumber: detailsData['formatted_phone_number'],
          website: detailsData['website'],
          openingHours: openingHours,
          isOpenNow: detailsData['opening_hours']?['open_now'],
          photoReference: detailsData['photos']?[0]?['photo_reference'] ?? place.photoReference,
        );

        setState(() {
          _detailedResults[place.placeId] = detailedPlace;
        });
      }
    } catch (e) {
      // エラーログは既にPlacesServiceで出力されているのでここでは無視
    } finally {
      setState(() {
        _loadingDetailsIds.remove(place.placeId);
      });
    }
  }

  Widget _buildResultCard(BuildContext context, PlaceResult result) {
    final isSaved = _savedPlaceIds.contains(result.placeId);

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
              child: result.photoReference!.startsWith('assets/')
                  ? Image.asset(
                      result.photoReference!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
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
                    // 詳細情報読み込み中の場合はローディングアイコンを表示
                    if (_loadingDetailsIds.contains(result.placeId) && !result.hasDetailsLoaded)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
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
                    if (result.hasDetailsLoaded && result.isOpenNow != null)
                      Text(
                        result.isOpenNow == true ? '営業中' : '営業時間外',
                        style: TextStyle(
                          color: result.isOpenNow == true
                              ? Colors.green
                              : AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (_loadingDetailsIds.contains(result.placeId))
                      const Text(
                        '読み込み中...',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      const Text(
                        '営業時間情報なし',
                        style: TextStyle(color: Colors.grey),
                      ),
                    const SizedBox(width: 8),
                    if (result.hasDetailsLoaded)
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
                    const Icon(
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

                // 距離情報を追加（駅からの距離など）
                if (result.distance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          result.getDistanceText(),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
                OutlinedButton.icon(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: AppTheme.primaryBlue,
                  ),
                  label: Text(
                    isSaved ? '保存済み' : '保存する',
                    style: const TextStyle(color: AppTheme.primaryBlue),
                  ),
                  onPressed: () => _toggleSavePlace(result),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (result.website != null)
                  OutlinedButton.icon(
                    icon:
                        const Icon(Icons.language, color: AppTheme.primaryBlue),
                    label: const Text('ウェブサイト',
                        style: TextStyle(color: AppTheme.primaryBlue)),
                    onPressed: () => _launchUrl(result.website!),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share, color: AppTheme.primaryBlue),
                  label: const Text('共有',
                      style: TextStyle(color: AppTheme.primaryBlue)),
                  onPressed: () => _sharePlace(result),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBlue),
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
                    icon: const Icon(Icons.phone, color: AppTheme.primaryBlue),
                    label: const Text('電話',
                        style: TextStyle(color: AppTheme.primaryBlue)),
                    onPressed: () => _callPhone(result.phoneNumber!),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryBlue),
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
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );
    }
  }

  Future<void> _sharePlace(PlaceResult place) async {
    await Share.share(
      'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}',
      subject: place.name,
    );
  }

  Future<void> _callPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
