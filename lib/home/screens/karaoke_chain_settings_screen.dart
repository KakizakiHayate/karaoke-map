import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KaraokeChainSettingsScreen extends StatefulWidget {
  final Map<String, bool> initialSelectedChains;

  const KaraokeChainSettingsScreen({
    super.key,
    required this.initialSelectedChains,
  });

  @override
  State<KaraokeChainSettingsScreen> createState() =>
      _KaraokeChainSettingsScreenState();
}

class _KaraokeChainSettingsScreenState
    extends State<KaraokeChainSettingsScreen> {
  late List<MapEntry<String, bool>> _chainSettings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _chainSettings = widget.initialSelectedChains.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カラオケチェーン設定'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: () {
                final Map<String, bool> result =
                    Map.fromEntries(_chainSettings);
                Navigator.pop(context, result);
              },
              child: const Text('保存'),
            ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: _chainSettings.length,
        onReorderStart: (_) {
          HapticFeedback.mediumImpact();
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _chainSettings.removeAt(oldIndex);
            _chainSettings.insert(newIndex, item);
            _hasChanges = true;
          });
        },
        itemBuilder: (context, index) {
          final chain = _chainSettings[index];
          return ListTile(
            key: Key(chain.key),
            leading: const Icon(Icons.drag_handle),
            title: Text(chain.key),
            trailing: Checkbox(
              value: chain.value,
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() {
                    _chainSettings[index] = MapEntry(chain.key, value);
                    _hasChanges = true;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }
}
