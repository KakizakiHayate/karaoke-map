import 'package:flutter/material.dart';
import '../../models/place_suggestion.dart';
import '../../models/place_result.dart';
import '../../services/places_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchDetailScreen extends StatefulWidget {
  const SearchDetailScreen({super.key});

  @override
  State<SearchDetailScreen> createState() => _SearchDetailScreenState();
}

class _SearchDetailScreenState extends State<SearchDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PlacesService _placesService = PlacesService();

  List<PlaceSuggestion> _suggestions = [];
  List<PlaceResult> _searchResults = [];
  bool _isSearching = false;

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
    setState(() {
      _suggestions = suggestions;
      _isSearching = false;
    });
  }

  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    _searchController.text = suggestion.mainText;
    Navigator.pop(context, suggestion.mainText);
  }

  Future<void> _openInMaps(PlaceResult place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}',
    );
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
                    onTap: () {
                      // TODO: 現在地を使用した検索処理
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 1),
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
                          ButtonBar(
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
