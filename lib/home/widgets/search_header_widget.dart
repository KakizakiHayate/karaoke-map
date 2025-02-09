import 'package:flutter/material.dart';
import '../screens/karaoke_chain_settings_screen.dart';
import '../screens/search_detail_screen.dart';

class SearchHeaderWidget extends StatefulWidget {
  final TextEditingController? searchController;
  final Function(String)? onSearch;

  const SearchHeaderWidget({
    super.key,
    this.searchController,
    this.onSearch,
  });

  @override
  State<SearchHeaderWidget> createState() => _SearchHeaderWidgetState();
}

class _SearchHeaderWidgetState extends State<SearchHeaderWidget> {
  late final TextEditingController _searchController;
  String _selectedRadius = '500';
  final List<String> _radiusOptions = ['300', '500', '1000', '2000'];

  final Map<String, bool> _selectedChains = {
    'カラオケまねきねこ': true,
    'ビッグエコー': true,
    'カラオケBanBan': true,
    'カラオケ館': true,
    'ジャンカラ': true,
    'JOYSOUND直営店': true,
    'カラオケJOYJOY': true,
    'コート・ダジュール': true,
    'カラオケCLUB DAM': true,
    'カラオケルーム歌広場': true,
  };

  static const int _maxVisibleChains = 5;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.searchController == null) {
      _searchController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 最初の5つのチェーン店のみを表示
    final visibleChains = _selectedChains.entries.take(_maxVisibleChains);

    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    readOnly: true,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const SearchDetailScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 200),
                        ),
                      );

                      if (result != null && result is String) {
                        setState(() {
                          _searchController.text = result; // テキストフィールドを更新
                        });
                        widget.onSearch?.call(result);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'カラオケ店を検索',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DropdownButton<String>(
                    value: _selectedRadius,
                    underline: Container(),
                    items: _radiusOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('${value}m'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRadius = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: visibleChains.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(entry.key),
                            selected: entry.value,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedChains[entry.key] = selected;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, bool>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KaraokeChainSettingsScreen(
                          initialSelectedChains: _selectedChains,
                        ),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _selectedChains.clear();
                        _selectedChains.addAll(result);
                      });
                    }
                  },
                  child: const Text('すべて表示'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
