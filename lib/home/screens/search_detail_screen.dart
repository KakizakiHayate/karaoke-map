import 'package:flutter/material.dart';
import '../../models/place_suggestion.dart';
import '../../models/place_result.dart';
import '../../services/places_service.dart';
import '../../services/search_history_service.dart';
import '../../models/search_history.dart';
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
          onChanged: _onSearchChanged,
          onSubmitted: (value) async {
            if (value.isNotEmpty) {
              if (!mounted) return;
              final navigator = Navigator.of(context);
              final searchType = value.contains('駅') ? 'station' : 'location';
              await _saveSearchHistory(value, searchType);
              if (!mounted) return;
              navigator.pop(value);
            }
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (showCurrentLocation) ...[
                  ListTile(
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
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      if (!mounted) return;
                      navigator.pop('');
                    },
                  ),
                  const Divider(height: 1),
                  if (_searchHistory.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '検索履歴',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton(
                            onPressed: () async {
                              if (!mounted) return;
                              await _historyService
                                  .deleteAllUserSearchHistory(widget.userId);
                              await _loadSearchHistory();
                            },
                            child: const Text('すべて削除'),
                          ),
                        ],
                      ),
                    ),
                    ..._searchHistory
                        .where((history) =>
                            history.searchType == 'location' ||
                            history.searchType == 'station')
                        .map(
                          (history) => ListTile(
                            leading: Icon(
                              history.searchType == 'station'
                                  ? Icons.train
                                  : Icons.search,
                              color: Colors.grey,
                            ),
                            title: Text(history.searchQuery),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () async {
                                if (history.id != null) {
                                  if (!mounted) return;
                                  await _historyService
                                      .deleteSearchHistory(history.id!);
                                  await _loadSearchHistory();
                                }
                              },
                            ),
                            onTap: () {
                              final navigator = Navigator.of(context);
                              if (!mounted) return;
                              navigator.pop(history.searchQuery);
                            },
                          ),
                        ),
                    const Divider(height: 1),
                  ],
                ],
                if (_suggestions.isNotEmpty)
                  ..._suggestions.map(
                    (suggestion) => ListTile(
                      leading: const Icon(Icons.search),
                      title: Text(suggestion.mainText),
                      subtitle: Text(suggestion.secondaryText),
                      onTap: () => _onSuggestionSelected(suggestion),
                    ),
                  ),
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
    );
  }
}
