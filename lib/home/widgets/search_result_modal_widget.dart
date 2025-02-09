import 'package:flutter/material.dart';

class SearchResultModalWidget extends StatelessWidget {
  final ScrollController scrollController;
  final List<double> snapSizes;

  const SearchResultModalWidget({
    super.key,
    required this.scrollController,
    this.snapSizes = const [0.1, 0.6, 0.9],
  });

  void _handleDragEnd(DragEndDetails details, BuildContext context) {
    final currentSize = (scrollController.position.pixels /
            MediaQuery.of(context).size.height) +
        0.1;
    final velocity = details.primaryVelocity ?? 0;

    double targetSize;
    if (velocity == 0) {
      // ドラッグ終了時、最も近いスナップポイントへ
      targetSize = snapSizes.reduce((a, b) {
        return (currentSize - a).abs() < (currentSize - b).abs() ? a : b;
      });
    } else if (velocity < 0) {
      // 上方向へのスワイプ
      targetSize = snapSizes.firstWhere(
        (size) => size > currentSize,
        orElse: () => snapSizes.last,
      );
    } else {
      // 下方向へのスワイプ
      targetSize = snapSizes.lastWhere(
        (size) => size < currentSize,
        orElse: () => snapSizes.first,
      );
    }

    DraggableScrollableActuator.reset(context);
    scrollController.animateTo(
      (targetSize - 0.1) * MediaQuery.of(context).size.height,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // グラバー
          GestureDetector(
            onVerticalDragUpdate: (details) {
              scrollController.jumpTo(
                scrollController.offset - details.delta.dy,
              );
            },
            onVerticalDragEnd: (details) => _handleDragEnd(details, context),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // 検索結果リスト
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                // ここに検索結果を表示
              ],
            ),
          ),
        ],
      ),
    );
  }
}
