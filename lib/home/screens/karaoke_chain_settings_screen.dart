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
  static const int _maxVisibleOnHome = 5;

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '※ 上から$_maxVisibleOnHome件までがホーム画面に表示されます',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
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
                  title: Row(
                    children: [
                      Text(chain.key),
                      if (index < _maxVisibleOnHome)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ホーム表示',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
          ),
        ],
      ),
    );
  }
}
