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
  final GlobalKey _headerKey = GlobalKey();
  double _maxModalSize = 0.9; // デフォルト値
  int _selectedIndex = 0;
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(35.6812, 139.7671), // 東京駅付近
    zoom: 14.0,
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
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: _maxModalSize,
            snap: true,
            snapSizes: [0.1, 0.45, _maxModalSize],
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
