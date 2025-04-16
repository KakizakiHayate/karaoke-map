import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/place_result.dart';
import '../../models/sample_places.dart';
import '../../app_state.dart';
import 'package:provider/provider.dart';
import 'widgets/search_header_widget.dart';
import 'widgets/map_widget.dart';
import 'widgets/search_result_modal_widget.dart';
import 'widgets/bottom_navigation_widget.dart';
import '../services/places_service.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/place_info_window.dart';
import '../services/karaoke_chain_service.dart';
import 'package:logger/logger.dart';
import 'screens/search_screen.dart';
import 'screens/saved_places_screen.dart';
import 'screens/settings_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _kDefaultMaxModalSize = 0.9;
  static const double _kMinModalSize = 0.1;
  static const double _kMiddleModalSize = 0.45;
  static const double _kMapZoomLevel = 14.0;
  static const LatLng _kTokyoStationLocation = LatLng(35.6812, 139.7671);
  static const String _debugPassword = 'karaoke123'; // デバッグモード用パスワード

  final GlobalKey _headerKey = GlobalKey();
  double _maxModalSize = _kDefaultMaxModalSize;
  int _selectedIndex = 0;
  final Logger _logger = Logger();

  // 設定タブタップのカウントと時間
  int _settingsTabTapCount = 0;
  DateTime? _lastSettingsTapTime;
  static const int _requiredTapCount = 5; // デバッグモード表示に必要なタップ回数
  static const Duration _tapTimeWindow = Duration(seconds: 3); // タップが有効な時間枠

  final TextEditingController _searchController = TextEditingController();
  List<PlaceResult> _searchResults = [];
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  // 検索中の状態を追加
  bool _isLoading = false;

  // 表示する画面のリスト
  final List<Widget> _screens = [
    const SearchScreen(),
    const SavedPlacesScreen(),
    const SettingsScreen(),
  ];

  // 現在地の状態を追加
  LatLng? _userLocation;

  BitmapDescriptor? _karaokeIcon;

  // マーカータップ時の店舗情報表示用のState
  PlaceResult? _selectedPlace;

  // 選択された店舗のインデックスを追加
  int _selectedPlaceIndex = 0;

  final DraggableScrollableController _draggableScrollableController =
      DraggableScrollableController();

  // KaraokeChainServiceのインスタンスを追加
  final KaraokeChainService _karaokeChainService = KaraokeChainService();

  // 選択されたカラオケチェーン店の状態を追加
  Map<String, bool> _selectedChains = {};

  // 現在選択されている検索範囲
  String _currentRadius = '500';

  // SearchResultModalWidgetのGlobalKeyを追加
  final GlobalKey<SearchResultModalWidgetState> _searchResultModalKey =
      GlobalKey<SearchResultModalWidgetState>();

  // PlaceInfoWindowのGlobalKeyを追加
  final GlobalKey<PlaceInfoWindowState> _placeInfoWindowKey =
      GlobalKey<PlaceInfoWindowState>();

  @override
  void initState() {
    super.initState();
    _loadKaraokeIcon();
    _loadSelectedChains(); // チェーン店の選択状態を読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMaxModalSize();
    });

    // 現在位置を取得して自動検索を実行
    _initializeLocationAndSearch();
  }

  // 初期化時に位置情報を取得して自動検索を行うメソッドを追加
  Future<void> _initializeLocationAndSearch() async {
    try {
      // 位置情報の権限を取得
      await _getCurrentLocation();

      // カラオケアイコンをロード
      await _loadKaraokeIcon();

      // カラオケチェーン店の選択状態をロード
      await _loadSelectedChains();

      // 位置情報があれば現在地から検索、なければ東京駅から検索
      if (_userLocation != null) {
        await _performSearchNearby(
          _userLocation!,
          int.parse(_getInitialRadius()),
        );
        // 地図の表示位置を現在地に設定
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_userLocation!, _kMapZoomLevel),
        );
      } else {
        // 位置情報が取得できない場合は東京都内を検索
        await _performSearchInTokyo();
      }
    } catch (e) {
      _logger.e('自動検索でエラーが発生しました: $e');
      // エラー時もUIをフリーズさせないために状態を更新
      setState(() {
        _isLoading = false;
      });

      // エラーメッセージをスナックバーで表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('検索中にエラーが発生しました。ネットワーク接続を確認して再試行してください。'),
            backgroundColor: AppTheme.primaryRed,
            duration: Duration(seconds: 4),
          ),
        );
      }

      // エラー時も東京都内を検索してみる
      try {
        await _performSearchInTokyo();
      } catch (e) {
        _logger.e('東京での検索もエラーが発生しました: $e');
      }
    }
  }

  // 初期検索用の範囲を取得
  String _getInitialRadius() {
    return '500'; // 初期検索時のデフォルト範囲
  }

  // 特定の位置から指定した半径内を検索するメソッド
  Future<void> _performSearchNearby(LatLng location, int radius) async {
    // 検索開始時にローディング状態をtrueに設定
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await PlacesService().searchKaraoke(
        '', // クエリは空で位置情報だけで検索
        userLocation: location,
        searchLocation: location,
        isStation: false,
        selectedChains: _selectedChains,
        radius: radius,
      );

      // マーカーを更新
      final markers = results.map((place) {
        return Marker(
          markerId: MarkerId(place.placeId),
          position: LatLng(place.lat, place.lng),
          icon: _karaokeIcon ?? BitmapDescriptor.defaultMarker,
          onTap: () => _onMarkerTapped(place),
        );
      }).toSet();

      setState(() {
        _searchResults = results;
        _markers.clear();
        _markers.addAll(markers);
        _isLoading = false; // 検索完了時にローディング状態をfalseに設定
      });

      // 検索結果がある場合、マップの表示位置を調整
      if (results.isNotEmpty && _mapController != null) {
        final bounds = _calculateBounds(results);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
      }
    } catch (e) {
      _logger.e('検索中にエラーが発生しました: $e');

      // エラー時にUIを更新
      setState(() {
        _isLoading = false;
      });

      // エラーメッセージをスナックバーで表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('検索中にエラーが発生しました。ネットワーク接続を確認して再試行してください。'),
            backgroundColor: AppTheme.primaryRed,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // 東京都内のカラオケ店を検索するメソッド
  Future<void> _performSearchInTokyo() async {
    // 東京駅の座標を使って検索するように変更
    await _performSearchNearby(_kTokyoStationLocation, int.parse(_getRadius()));
  }

  // 現在選択されている検索範囲を取得するヘルパーメソッド
  String _getRadius() {
    return _currentRadius; // SearchHeaderWidgetから選択された値を使用
  }

  Future<void> _getCurrentLocation() async {
    // 位置情報の権限を確認
    final permission = await Geolocator.checkPermission();

    // 権限が拒否または永久に拒否されている場合
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // 位置情報が利用できない場合はnullのままにする（後で東京都検索に使用）
      _logger.i('位置情報の権限がありません。東京都で検索を行います。');
      return; // ここで終了
    }

    // 権限がある場合だけ位置情報取得を試みる
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      _logger.e('位置情報の取得に失敗しました: $e');
      // 位置情報取得エラー時は_userLocationはnullのまま
    }
  }

  void _updateMaxModalSize() {
    final headerBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (headerBox != null) {
      final headerHeight = headerBox.size.height;
      final screenHeight = MediaQuery.of(context).size.height;
      setState(() {
        _maxModalSize = (screenHeight - headerHeight) / screenHeight;
      });
    }
  }

  void _onItemTapped(int index) {
    final now = DateTime.now();

    // 設定タブ（index=2）をタップした場合
    if (index == 2) {
      // 前回のタップから3秒以内なら連続タップとみなす
      if (_lastSettingsTapTime != null &&
          now.difference(_lastSettingsTapTime!) < _tapTimeWindow) {
        _settingsTabTapCount++;

        // 5回連続でタップした場合
        if (_settingsTabTapCount == _requiredTapCount) {
          _showPasswordDialog();
          _settingsTabTapCount = 0; // カウントをリセット
        }
      } else {
        // 時間が空きすぎていた場合はカウントをリセット
        _settingsTabTapCount = 1;
      }

      _lastSettingsTapTime = now;
    } else {
      // 設定タブ以外をタップした場合はカウントをリセット
      _settingsTabTapCount = 0;
      _lastSettingsTapTime = null;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadKaraokeIcon() async {
    _karaokeIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );
  }

  Future<void> _loadSelectedChains() async {
    final chains = await _karaokeChainService.getAllChains();
    final selectedChains =
        await _karaokeChainService.getSelectedChains(1); // 仮のユーザーID: 1

    setState(() {
      _selectedChains = {
        for (var chain in chains)
          chain.name: selectedChains.any((selected) => selected.id == chain.id)
      };
    });
  }

  Future<void> _saveSelectedChains(Map<String, bool> newChains) async {
    final chains = await _karaokeChainService.getAllChains();

    for (var chain in chains) {
      final isSelected = newChains[chain.name] ?? false;
      await _karaokeChainService.updateChainSelection(1, chain.id!, isSelected);
    }

    setState(() {
      _selectedChains = newChains;
    });
  }

  Future<void> _performSearch(String query, String selectedRadius) async {
    // 検索開始時にローディング状態をtrueに設定
    setState(() {
      _searchResults = []; // 検索中は結果をクリア
      _isLoading = true;
    });

    try {
      // デバッグモードの場合、サンプルデータを表示
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.isDebugMode) {
        // クエリを確認して、駅名検索かどうかを判断
        final isStationSearch = query.contains('駅');
        List<PlaceResult> sampleResults;

        if (isStationSearch) {
          // 駅名検索の場合は駅用のサンプルデータを使用
          sampleResults = SamplePlaces.getStationSamplePlaces(query);

          // 検索クエリを表示してデバッグ情報を提供
          _logger.d('駅名検索: $query');
        } else if (query.isNotEmpty) {
          // エリア検索の場合も通常のサンプルデータ
          sampleResults = SamplePlaces.getSamplePlaces();
          // 検索範囲に応じて、距離の近いデータだけにフィルタリング
          final radius = int.parse(selectedRadius);
          sampleResults = sampleResults
              .where((place) =>
                  place.distance != null && place.distance! <= radius)
              .toList();

          _logger.d('エリア検索: $query (半径: ${selectedRadius}m)');
        } else {
          // クエリが空の場合は全サンプルデータ
          sampleResults = SamplePlaces.getSamplePlaces();
          _logger.d('現在地周辺検索 (半径: ${selectedRadius}m)');
        }

        // マーカーを更新
        final markers = sampleResults.map((place) {
          return Marker(
            markerId: MarkerId(place.placeId),
            position: LatLng(place.lat, place.lng),
            icon: _karaokeIcon ?? BitmapDescriptor.defaultMarker,
            onTap: () => _onMarkerTapped(place),
          );
        }).toSet();

        setState(() {
          _searchResults = sampleResults;
          _markers.clear();
          _markers.addAll(markers);
          _isLoading = false; // 検索完了時にローディング状態をfalseに設定
        });

        // 検索結果の境界を計算してマップを調整
        if (sampleResults.isNotEmpty && _mapController != null) {
          final bounds = _calculateBounds(sampleResults);
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50.0),
          );
        }

        // デバッグモードの場合は早期リターン
        return;
      }

      // 通常の検索フロー（既存のコード）
      // 検索クエリが空の場合は現在位置から検索
      if (query.isEmpty && _userLocation != null) {
        await _performSearchNearby(_userLocation!, int.parse(selectedRadius));
        return;
      } else if (query.isEmpty) {
        // 検索クエリが空かつ現在位置もない場合は東京都で検索
        await _performSearchInTokyo();
        return;
      }

      // 検索タイプを判断（駅名かエリア名か）
      final isStation = query.contains('駅');
      LatLng? searchLocation;

      if (isStation) {
        // 駅の座標を取得
        final stationLocation = await PlacesService().getPlaceLocation(query);
        if (stationLocation != null) {
          searchLocation = stationLocation;
        }
      }

      // 検索実行時に選択されたチェーン店の情報と距離を渡す
      final results = await PlacesService().searchKaraoke(
        query,
        userLocation: _userLocation,
        searchLocation: searchLocation,
        isStation: isStation,
        selectedChains: _selectedChains,
        radius: int.parse(selectedRadius),
      );

      // マーカーを更新
      final markers = results.map((place) {
        return Marker(
          markerId: MarkerId(place.placeId),
          position: LatLng(place.lat, place.lng),
          icon: _karaokeIcon ?? BitmapDescriptor.defaultMarker,
          onTap: () => _onMarkerTapped(place),
        );
      }).toSet();

      setState(() {
        _searchResults = results;
        _markers.clear();
        _markers.addAll(markers);
        _isLoading = false; // 検索完了時にローディング状態をfalseに設定
      });

      // 検索結果がある場合、マップの表示位置を調整
      if (results.isNotEmpty && _mapController != null) {
        final bounds = _calculateBounds(results);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
      }
    } catch (e) {
      _logger.e('検索中にエラーが発生しました: $e');

      // エラー時にUIを更新
      setState(() {
        _isLoading = false;
      });

      // エラーメッセージをスナックバーで表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('検索中にエラーが発生しました。ネットワーク接続を確認して再試行してください。'),
            backgroundColor: AppTheme.primaryRed,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  LatLngBounds _calculateBounds(List<PlaceResult> places) {
    double? minLat, maxLat, minLng, maxLng;

    for (final place in places) {
      if (minLat == null || place.lat < minLat) minLat = place.lat;
      if (maxLat == null || place.lat > maxLat) maxLat = place.lat;
      if (minLng == null || place.lng < minLng) minLng = place.lng;
      if (maxLng == null || place.lng > maxLng) maxLng = place.lng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  // マーカータップ時のハンドラを更新
  void _onMarkerTapped(PlaceResult place) {
    final index = _searchResults.indexOf(place);
    setState(() {
      _selectedPlaceIndex = index;
      _selectedPlace = place;
    });

    _draggableScrollableController.animateTo(
      _kMinModalSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ページ変更時のハンドラを追加
  void _onPageChanged(int index) {
    setState(() {
      _selectedPlaceIndex = index;
      _selectedPlace = _searchResults[index];
    });

    // 地図の表示位置を更新
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(_searchResults[index].lat, _searchResults[index].lng),
      ),
    );
  }

  // 保存状態が変更された時のコールバック
  void _onSavedStateChanged(String placeId, bool isSaved) {
    // PlaceInfoWindowの保存状態を更新
    _placeInfoWindowKey.currentState?.updateSavedState(placeId, isSaved);

    // SearchResultModalWidgetの保存状態を更新
    _searchResultModalKey.currentState?.updateSavedState(placeId, isSaved);
  }

  // パスワード入力ダイアログを表示するメソッド
  void _showPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('デバッグモード'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'パスワードを入力',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text == _debugPassword) {
                  // デバッグモードを有効化
                  Provider.of<AppState>(context, listen: false)
                      .toggleDebugMode(true);
                  Navigator.of(context).pop();

                  // 成功メッセージを表示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('デバッグモードが有効になりました'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  // エラーメッセージを表示
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('パスワードが正しくありません'),
                      backgroundColor: AppTheme.primaryRed,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: const Text('確認'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_selectedIndex == 0) ...[
            MapWidget(
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                // マップが作成された時点で現在地が取得できていれば、そこにカメラを移動
                if (_userLocation != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_userLocation!, _kMapZoomLevel),
                  );
                }
              },
              initialLocation: _userLocation ?? _kTokyoStationLocation,
              initialZoom: _kMapZoomLevel,
            ),
            SearchHeaderWidget(
              key: _headerKey,
              searchController: _searchController,
              onSearch: _performSearch,
              selectedChains: _selectedChains,
              initialRadius: _currentRadius,
              onRadiusChanged: (radius) {
                setState(() {
                  _currentRadius = radius;
                });
              },
              onChainsUpdated: (newChains) async {
                await _saveSelectedChains(newChains);
                // 強制的に現在の検索を再実行
                final currentQuery = _searchController.text;
                // クエリがなくても現在位置から検索できるようにする
                await _performSearch(currentQuery, _getRadius());
              },
            ),
            if (_selectedPlace != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).size.height * _kMinModalSize + 8,
                child: PlaceInfoWindow(
                  key: _placeInfoWindowKey,
                  places: _searchResults,
                  selectedIndex: _selectedPlaceIndex,
                  onPageChanged: _onPageChanged,
                  onSavedStateChanged: _onSavedStateChanged,
                ),
              ),
            DraggableScrollableSheet(
              controller: _draggableScrollableController,
              initialChildSize: _kMiddleModalSize,
              minChildSize: _kMinModalSize,
              maxChildSize: _maxModalSize,
              snap: true,
              snapSizes: [_kMinModalSize, _kMiddleModalSize, _maxModalSize],
              builder: (context, scrollController) {
                return Material(
                  elevation: 8,
                  child: SearchResultModalWidget(
                    key: _searchResultModalKey,
                    scrollController: scrollController,
                    searchResults: _searchResults,
                    isLoading: _isLoading,
                    searchRadius: _currentRadius,
                    onSavedStateChanged: _onSavedStateChanged,
                  ),
                );
              },
            ),
          ] else
            _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
