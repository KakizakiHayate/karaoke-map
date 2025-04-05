import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/place_result.dart';
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
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

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

  final GlobalKey _headerKey = GlobalKey();
  double _maxModalSize = _kDefaultMaxModalSize;
  int _selectedIndex = 0;
  final Logger _logger = Logger();

  final TextEditingController _searchController = TextEditingController();
  List<PlaceResult> _searchResults = [];
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  // 表示する画面のリスト
  final List<Widget> _screens = [
    const SearchScreen(),
    const HistoryScreen(),
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadKaraokeIcon();
    _loadSelectedChains(); // チェーン店の選択状態を読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMaxModalSize();
    });
  }

  // チェーン店の選択状態を読み込むメソッドを追加
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

  // チェーン店の選択状態を保存するメソッドを追加
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
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _getCurrentLocation() async {
    // 位置情報の権限を確認・取得
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      _logger.e('Error getting location: $e');
    }
  }

  Future<void> _loadKaraokeIcon() async {
    _karaokeIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );
  }

  Future<void> _performSearch(String query, String selectedRadius) async {
    setState(() => _searchResults = []); // 検索中は結果をクリア

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
    });

    // 検索結果がある場合、マップの表示位置を調整
    if (results.isNotEmpty && _mapController != null) {
      final bounds = _calculateBounds(results);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_selectedIndex == 0) ...[
            MapWidget(
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
              initialLocation: _userLocation ?? _kTokyoStationLocation,
              initialZoom: _kMapZoomLevel,
            ),
            SearchHeaderWidget(
              key: _headerKey,
              searchController: _searchController,
              onSearch: _performSearch,
              selectedChains: _selectedChains,
              onChainsUpdated: (newChains) async {
                await _saveSelectedChains(newChains);
                // 強制的に現在の検索を再実行
                final currentQuery = _searchController.text;
                if (currentQuery.isNotEmpty) {
                  await _performSearch(currentQuery, '500');
                }
              },
            ),
            if (_selectedPlace != null)
              Positioned(
                left: 0,
                right: 0,
                bottom:
                    MediaQuery.of(context).size.height * _kMinModalSize + 16,
                child: PlaceInfoWindow(
                  places: _searchResults,
                  selectedIndex: _selectedPlaceIndex,
                  onPageChanged: _onPageChanged,
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
                    scrollController: scrollController,
                    searchResults: _searchResults,
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
