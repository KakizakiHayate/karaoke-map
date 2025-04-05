import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/karaoke_chain_settings_screen.dart';
import '../screens/search_detail_screen.dart';
import '../../app_state.dart';
import '../../theme/app_theme.dart';

class SearchHeaderWidget extends StatefulWidget {
  final TextEditingController? searchController;
  final Function(String, String)? onSearch;
  final Map<String, bool> selectedChains;
  final Function(Map<String, bool>) onChainsUpdated;
  final String? initialRadius;
  final Function(String)? onRadiusChanged;

  const SearchHeaderWidget({
    super.key,
    this.searchController,
    this.onSearch,
    required this.selectedChains,
    required this.onChainsUpdated,
    this.initialRadius,
    this.onRadiusChanged,
  });

  @override
  State<SearchHeaderWidget> createState() => _SearchHeaderWidgetState();
}

class _SearchHeaderWidgetState extends State<SearchHeaderWidget> {
  late final TextEditingController _searchController;
  late String _selectedRadius;
  final List<String> _radiusOptions = [
    '300',
    '500',
    '1000',
    '2000',
    '3000',
    '4000',
    '5000',
    '6000',
    '7000',
    '8000',
    '9000',
    '10000'
  ];

  static const int _maxVisibleChains = 5;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
    _selectedRadius = widget.initialRadius ?? '500';
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
    final visibleChains = widget.selectedChains.entries.take(_maxVisibleChains);

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
                      final userId = context.read<AppState>().userId;
                      if (userId == null) return;

                      final result = await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  SearchDetailScreen(userId: userId),
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
                          _searchController.text = result;
                        });
                        widget.onSearch?.call(result, _selectedRadius);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'カラオケ店を検索',
                      hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 100, 100, 100),
                          fontSize: 14),
                      prefixIcon:
                          const Icon(Icons.search, color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBlue, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBlue, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBlue, width: 1),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBlue, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        widget.onSearch?.call(value, _selectedRadius);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00AEEF)),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedRadius,
                    underline: Container(),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Color(0xFF00AEEF)),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    isExpanded: false,
                    menuMaxHeight: 300,
                    items: _radiusOptions.map((String value) {
                      // 1000m以上はkmで表示
                      final int intValue = int.parse(value);
                      final String displayText = intValue >= 1000
                          ? '${(intValue / 1000).toStringAsFixed(1)}km'
                          : '${value}m';

                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          displayText,
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRadius = newValue;
                        });

                        // 検索範囲変更を親ウィジェットに通知
                        widget.onRadiusChanged?.call(newValue);

                        // 検索ボックスが空の場合でも、範囲変更時に再検索を実行
                        // これにより現在位置からの検索も範囲が変わったら再実行される
                        widget.onSearch?.call(_searchController.text, newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                            label: Text(
                              entry.key,
                              style: TextStyle(
                                color: entry.value
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                                fontWeight: entry.value
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: entry.value,
                            showCheckmark: false,
                            selectedColor: const Color(0xFF00AEEF),
                            backgroundColor: Colors.white,
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: entry.value
                                    ? const Color(0xFF00AEEF)
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            onSelected: (bool selected) {
                              final newChains =
                                  Map<String, bool>.from(widget.selectedChains);
                              newChains[entry.key] = selected;
                              widget.onChainsUpdated(newChains);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, bool>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KaraokeChainSettingsScreen(
                          initialSelectedChains: widget.selectedChains,
                        ),
                      ),
                    );

                    if (result != null) {
                      widget.onChainsUpdated(result);
                      if (_searchController.text.isNotEmpty) {
                        widget.onSearch
                            ?.call(_searchController.text, _selectedRadius);
                      }
                    }
                  },
                  icon: const Icon(Icons.tune,
                      size: 18, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
