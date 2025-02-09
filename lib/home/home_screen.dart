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

  // 表示する画面のリスト
  final List<Widget> _screens = [
    const SearchScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
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
              const MapWidget(),

              // 検索ヘッダー
              SafeArea(
                top: false,
                child: SearchHeaderWidget(
                  key: _headerKey,
                  searchController: _searchController,
                  onSearch: (query) async {
                    final results = await PlacesService().searchKaraoke(query);
                    setState(() {
                      _searchResults = results;
                    });
                  },
                ),
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
