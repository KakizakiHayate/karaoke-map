import 'package:flutter/material.dart';
import '../../models/place_suggestion.dart';
import '../../models/place_result.dart';
import '../../services/places_service.dart';
import '../../services/search_history_service.dart';
import '../../models/search_history.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchDetailScreen extends StatefulWidget {
  final int userId;

  const SearchDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SearchDetailScreen> createState() => _SearchDetailScreenState();
}

class _SearchDetailScreenState extends State<SearchDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PlacesService _placesService = PlacesService();
  final SearchHistoryService _historyService = SearchHistoryService();

  List<PlaceSuggestion> _suggestions = [];
  List<PlaceResult> _searchResults = [];
  List<SearchHistory> _searchHistory = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _loadSearchHistory() async {
    final history = await _historyService.getUserSearchHistory(widget.userId);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _saveSearchHistory(String query, String type) async {
    final history = SearchHistory(
      userId: widget.userId,
      searchQuery: query,
      searchType: type,
    );
    await _historyService.saveSearchHistory(history);
    await _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() {
        _suggestions = [];
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final suggestions = await _placesService.getAutocompleteSuggestions(
      value,
      'ja',
    );
    if (!mounted) return;
    setState(() {
      _suggestions = suggestions;
      _isSearching = false;
    });
  }

  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    final String text = suggestion.mainText;
    if (!mounted) return;
    _searchController.text = text;
    final searchType = text.contains('駅') ? 'station' : 'location';
    await _saveSearchHistory(text, searchType);
    if (!mounted) return;
    Navigator.pop(context, text);
  }

  Future<void> _openInMaps(PlaceResult place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}',
    );
    if (!mounted) return;
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showCurrentLocation = _searchController.text.isEmpty;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'カラオケ店を検索',
                        border: InputBorder.none,
                        hintStyle:
                            TextStyle(color: Colors.grey[600], fontSize: 16),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey[600], size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 9, horizontal: 16),
                      ),
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 16),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: AppTheme.primaryBlue),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _suggestions = [];
                        _searchResults = [];
                        _isSearching = false;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _isSearching
              ? LinearProgressIndicator(
                  backgroundColor: Colors.white,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                )
              : const SizedBox(height: 2),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (showCurrentLocation) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEEEEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF00AEEF),
                        size: 20,
                      ),
                    ),
                    title: const Text('現在地から検索',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        )),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    visualDensity: const VisualDensity(vertical: -1),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      if (!mounted) return;
                      navigator.pop('');
                    },
                  ),
                  Container(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  Container(
                    height: 8,
                    color: const Color(0xFFF2F2F2),
                  ),
                  if (_searchHistory.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '履歴',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (!mounted) return;
                              await _historyService
                                  .deleteAllUserSearchHistory(widget.userId);
                              await _loadSearchHistory();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('すべて削除',
                                style: TextStyle(
                                  color: Color(0xFF00AEEF),
                                  fontSize: 13,
                                )),
                          ),
                        ],
                      ),
                    ),
                    ..._searchHistory
                        .where((history) =>
                            history.searchType == 'location' ||
                            history.searchType == 'station')
                        .map(
                          (history) => Column(
                            children: [
                              Dismissible(
                                key: Key(history.id?.toString() ??
                                    '${history.searchQuery}_${DateTime.now().millisecondsSinceEpoch}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) async {
                                  if (history.id != null) {
                                    if (!mounted) return;
                                    await _historyService
                                        .deleteSearchHistory(history.id!);
                                    await _loadSearchHistory();
                                  }
                                },
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEEEEEE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      history.searchType == 'station'
                                          ? Icons.train
                                          : Icons.access_time,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    history.searchQuery,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: history.searchType == 'location'
                                      ? null
                                      : Text(
                                          '東京都${history.searchQuery.contains('駅') ? history.searchQuery : ''}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 2),
                                  visualDensity:
                                      const VisualDensity(vertical: -1),
                                  onTap: () {
                                    final navigator = Navigator.of(context);
                                    if (!mounted) return;
                                    navigator.pop(history.searchQuery);
                                  },
                                ),
                              ),
                              Container(
                                height: 1,
                                color: Colors.grey[200],
                                margin: const EdgeInsets.only(left: 72),
                              ),
                            ],
                          ),
                        ),
                  ],
                ],
                if (_suggestions.isNotEmpty) ...[
                  Container(
                    height: 8,
                    color: const Color(0xFFF2F2F2),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '検索候補',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  ..._suggestions.map(
                    (suggestion) => Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEEEEE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Color(0xFF00AEEF),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            suggestion.mainText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            suggestion.secondaryText,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          visualDensity: const VisualDensity(vertical: -1),
                          onTap: () => _onSuggestionSelected(suggestion),
                        ),
                        Container(
                          height: 1,
                          color: Colors.grey[200],
                          margin: const EdgeInsets.only(left: 72),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_searchResults.isNotEmpty)
                  ..._searchResults.map(
                    (result) => Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (result.photoReference != null)
                            Image.network(
                              _placesService
                                  .getPhotoUrl(result.photoReference!),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(result.address),
                                if (result.rating > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${result.rating} (${result.userRatingsTotal})',
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          OverflowBar(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.directions),
                                label: const Text('ルート案内'),
                                onPressed: () => _openInMaps(result),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
