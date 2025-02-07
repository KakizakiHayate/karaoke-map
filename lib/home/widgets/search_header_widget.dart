import 'package:flutter/material.dart';

class SearchHeaderWidget extends StatefulWidget {
  const SearchHeaderWidget({super.key});

  @override
  State<SearchHeaderWidget> createState() => _SearchHeaderWidgetState();
}

class _SearchHeaderWidgetState extends State<SearchHeaderWidget> {
  String _selectedRadius = '500';
  final List<String> _radiusOptions = ['300', '500', '1000', '2000'];
  
  final Map<String, bool> _selectedChains = {
    'カラオケマック': false,
    'ジョイサウンド': false,
    'ビッグエコー': false,
    'カラオケバンバン': false,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 120,
                  child: TextField(
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
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _selectedChains.keys.map((chain) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(chain),
                            selected: _selectedChains[chain]!,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedChains[chain] = selected;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: 詳細画面への遷移処理を追加
                    },
                    child: const Text('すべて表示'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}