import 'package:flutter/material.dart';

class SearchDetailScreen extends StatefulWidget {
  const SearchDetailScreen({super.key});

  @override
  State<SearchDetailScreen> createState() => _SearchDetailScreenState();
}

class _SearchDetailScreenState extends State<SearchDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 画面表示時に自動的にフォーカスを当てる
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showCurrentLocation = _searchController.text.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            hintText: 'カラオケ店を検索',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: Theme.of(context).textTheme.titleLarge,
          onChanged: (value) {
            // TODO: 検索処理を実装
            setState(() {});
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: showCurrentLocation
            ? 22 // 現在地 + Divider + 検索結果
            : 20, // 検索結果のみ
        itemBuilder: (context, index) {
          if (showCurrentLocation) {
            if (index == 0) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                  ),
                ),
                title: const Text('現在地から検索'),
                onTap: () {
                  // TODO: 現在地を使用した検索処理
                  Navigator.pop(context);
                },
              );
            }

            if (index == 1) {
              return const Divider(height: 1);
            }

            // 現在地表示時の検索結果（インデックスを2つずらす）
            return ListTile(
              title: Text('検索結果 ${index - 1}'),
              subtitle: const Text('住所がここに表示されます'),
              leading: const Icon(Icons.location_on),
              onTap: () {
                Navigator.pop(context);
              },
            );
          } else {
            // 検索時の結果（そのままのインデックス）
            return ListTile(
              title: Text('検索結果 ${index + 1}'),
              subtitle: const Text('住所がここに表示されます'),
              leading: const Icon(Icons.location_on),
              onTap: () {
                Navigator.pop(context);
              },
            );
          }
        },
      ),
    );
  }
}
