import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/saved_place.dart';
import '../../services/saved_place_service.dart';
import '../../services/places_service.dart';
import '../../theme/app_theme.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final SavedPlaceService _savedPlaceService = SavedPlaceService();
  final PlacesService _placesService = PlacesService();

  List<SavedPlace> _savedPlaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPlaces();
  }

  Future<void> _loadSavedPlaces() async {
    setState(() {
      _isLoading = true;
    });

    final userId = context.read<AppState>().userId;
    if (userId != null) {
      final savedPlaces = await _savedPlaceService.getUserSavedPlaces(userId);
      setState(() {
        _savedPlaces = savedPlaces;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromSaved(SavedPlace place) async {
    final userId = context.read<AppState>().userId;
    if (userId != null) {
      final success =
          await _savedPlaceService.deleteSavedPlace(userId, place.placeId);
      if (success) {
        setState(() {
          _savedPlaces
              .removeWhere((savedPlace) => savedPlace.placeId == place.placeId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存済みリストから削除しました'),
              backgroundColor: AppTheme.primaryBlue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '保存済み',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _savedPlaces.isEmpty
                ? _buildEmptyState()
                : _buildSavedPlacesList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            '保存済みの場所がありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '検索結果から場所を保存してください',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPlacesList() {
    return RefreshIndicator(
      onRefresh: _loadSavedPlaces,
      child: ListView.builder(
        itemCount: _savedPlaces.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final place = _savedPlaces[index];
          return _buildPlaceCard(place);
        },
      ),
    );
  }

  Widget _buildPlaceCard(SavedPlace place) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (place.photoReference != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                _placesService.getPhotoUrl(place.photoReference!),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    child: const Center(
                      child: Icon(Icons.image_not_supported),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (place.rating > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text('${place.rating}'),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  place.address,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('ここにいく'),
                      onPressed: () => _openInMaps(place),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _showDeleteConfirmation(place),
                      color: AppTheme.primaryRed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(SavedPlace place) async {
    // PlaceResultに変換
    final placeResult = _savedPlaceService.convertToPlaceResult(place);
    // マップアプリを開く処理（実装済みの機能を使用）
    Navigator.pop(context, placeResult);
  }

  void _showDeleteConfirmation(SavedPlace place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存済みから削除'),
        content: Text('${place.name}を保存済みリストから削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromSaved(place);
            },
            child:
                const Text('削除', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }
}
