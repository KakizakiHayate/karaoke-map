import 'package:flutter/material.dart';
import '../../models/place_result.dart';

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
      height: 120, // カードの高さを固定
      child: PageView.builder(
        controller: PageController(
          viewportFraction: 0.85, // ビューポートの85%を表示（両サイドに次のカードが見える）
          initialPage: selectedIndex,
        ),
        onPageChanged: onPageChanged,
        itemCount: places.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
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
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    places[index].name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    places[index].address,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
