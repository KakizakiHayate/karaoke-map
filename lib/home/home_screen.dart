import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'widgets/search_header_widget.dart';
import 'widgets/map_widget.dart';
import 'widgets/search_result_modal_widget.dart';
import 'widgets/bottom_navigation_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // マジックナンバーを定数として定義
  static const double _kDefaultMaxModalSize = 0.9;
  static const double _kInitialModalSize = 0.1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Maps
          const MapWidget(),

          // 検索ヘッダー
          SafeArea(
            top: false,
            child: SearchHeaderWidget(key: _headerKey),
          ),

          // モーダル
          DraggableScrollableSheet(
            initialChildSize: _kInitialModalSize,
            minChildSize: _kMinModalSize,
            maxChildSize: _maxModalSize,
            snap: true,
            snapSizes: [_kMinModalSize, _kMiddleModalSize, _maxModalSize],
            builder: (context, scrollController) {
              return SearchResultModalWidget(
                scrollController: scrollController,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
