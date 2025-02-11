import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/place_result.dart';
import 'widgets/search_header_widget.dart';
import 'widgets/map_widget.dart';
import 'widgets/search_result_modal_widget.dart';
import 'widgets/bottom_navigation_widget.dart';
import 'screens/search_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import '../services/places_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'dart:typed_data'; // Uint8List用
import 'package:flutter/rendering.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // マジックナンバーを定数として定義
  static const double _kDefaultMaxModalSize = 0.9;
  static const double _kMinModalSize = 0.1;
  static const double _kMiddleModalSize = 0.45;
  static const double _kMapZoomLevel = 14.0;
  static const LatLng _kTokyoStationLocation = LatLng(35.6812, 139.7671);

  final GlobalKey _headerKey = GlobalKey();
  double _maxModalSize = _kDefaultMaxModalSize; // デフォルト値を定数から設定
  int _selectedIndex = 0;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: _kTokyoStationLocation, // 東京駅付近
    zoom: _kMapZoomLevel,
  );

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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadKaraokeIcon();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMaxModalSize();
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
      print('Error getting location: $e');
    }
  }

  Future<void> _loadKaraokeIcon() async {
    _karaokeIcon = await BitmapDescriptor.fromBytes(
      await _getBytesFromCanvas(
        const Icon(
          Icons.mic, // または Icons.mic_external_on
          color: Colors.red,
          size: 64,
        ),
      ),
    );
  }

  Future<Uint8List> _getBytesFromCanvas(Widget widget,
      {Size size = const Size(64, 64)}) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final painter = TextPainter(textDirection: TextDirection.ltr);
    final builder = widget as Icon;

    // 白い円を描画（背景）
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);

    // アイコンを描画
    painter.text = TextSpan(
      text: String.fromCharCode(builder.icon!.codePoint),
      style: TextStyle(
        fontSize: builder.size,
        fontFamily: builder.icon!.fontFamily,
        color: builder.color,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      size.center(Offset(-painter.width / 2, -painter.height / 2)),
    );

    final picture = pictureRecorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> _performSearch(String query) async {
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

    // 検索実行
    final results = await PlacesService().searchKaraoke(
      query,
      userLocation: _userLocation,
      searchLocation: searchLocation,
      isStation: isStation,
    );

    // マーカーを更新
    final markers = results.map((place) {
      return Marker(
        markerId: MarkerId(place.placeId),
        position: LatLng(place.lat, place.lng),
        icon: _karaokeIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.address,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 検索画面
          Stack(
            children: [
              // Google Maps
              MapWidget(
                markers: _markers,
                onMapCreated: (controller) => _mapController = controller,
              ),

              Column(
                children: [
                  SearchHeaderWidget(
                  key: _headerKey,
                  searchController: _searchController,
                  onSearch: _performSearch, // 更新した検索メソッドを使用
                ),
                              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'カラオケ店舗名',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '住所が入ります',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),


              // モーダル
              DraggableScrollableSheet(
                initialChildSize: _kMiddleModalSize,
                minChildSize: _kMinModalSize,
                maxChildSize: _maxModalSize,
                snap: true,
                snapSizes: [_kMinModalSize, _kMiddleModalSize, _maxModalSize],
                builder: (context, scrollController) {
                  return SearchResultModalWidget(
                    scrollController: scrollController,
                    searchResults: _searchResults,
                  );
                },
              ),
            ],
          ),

          // 履歴画面
          const HistoryScreen(),

          // 設定画面
          const SettingsScreen(),
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
