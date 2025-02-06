import 'package:flutter/material.dart';

class SearchHeaderWidget extends StatefulWidget {
  const SearchHeaderWidget({super.key});

  @override
  State<SearchHeaderWidget> createState() => _SearchHeaderWidgetState();
}

class _SearchHeaderWidgetState extends State<SearchHeaderWidget> {
  String _selectedRadius = '500';
  final List<String> _radiusOptions = ['300', '500', '1000', '2000'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
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
      ),
    );
  }
}