import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/place_result.dart';
import '../../services/places_service.dart';

class SearchResultModalWidget extends StatefulWidget {
  final ScrollController scrollController;
  final List<PlaceResult> searchResults;

  const SearchResultModalWidget({
    super.key,
    required this.scrollController,
    required this.searchResults,
  });

  @override
  State<SearchResultModalWidget> createState() =>
      _SearchResultModalWidgetState();
}

class _SearchResultModalWidgetState extends State<SearchResultModalWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView.builder(
        controller: widget.scrollController,
        itemCount: widget.searchResults.length,
        itemBuilder: (context, index) {
          final result = widget.searchResults[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.photoReference != null)
                  Image.network(
                    PlacesService().getPhotoUrl(result.photoReference!),
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
          );
        },
      ),
    );
  }

  Future<void> _openInMaps(PlaceResult place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
