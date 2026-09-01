import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/start_page_bloc.dart';
import '../../../bloc/main_bloc.dart';

/// Tab "Wyszukane" — historia ostatnich wyszukań
/// Kliknięcie w wpis przenosi do ekranu wyszukaj z wypełnionymi filtrami
class StartTabWyszukane extends StatefulWidget {
  final StartPageState state;
  const StartTabWyszukane({super.key, required this.state});

  @override
  State<StartTabWyszukane> createState() => _StartTabWyszukaneState();
}

class _StartTabWyszukaneState extends State<StartTabWyszukane> {
  List<_SearchEntry> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('search_history') ?? [];
    final entries = raw.map((e) {
      final parts = e.split('|');
      if (parts.length < 2) return null;
      return _SearchEntry(
        category: parts[0],
        sector: parts[1],
        location: parts.length > 2 ? parts[2] : '',
      );
    }).whereType<_SearchEntry>().toList();

    if (mounted) setState(() { _history = entries; _loading = false; });
  }

  Future<void> _remove(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('search_history') ?? [];
    raw.removeAt(index);
    await prefs.setStringList('search_history', raw);
    setState(() => _history.removeAt(index));
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() => _history.clear());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Brak historii wyszukań',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Wyszukaj firmy aby zobaczyć historię',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Wyszukaj'),
              onPressed: () => context.read<MainScreenBloc>().add(GoToWyszukajFirmyEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Nagłówek z przyciskiem "Wyczyść"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text('Ostatnie wyszukania',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 8),
              // Nowe wyszukiwanie
              IconButton(
                icon: const Icon(Icons.search, size: 24),
                tooltip: 'Nowe wyszukiwanie',
                visualDensity: VisualDensity.compact,
                onPressed: () => context
                    .read<MainScreenBloc>()
                    .add(GoToWyszukajFirmyEvent()),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearAll,
                child: const Text('Wyczyść wszystko',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _history.length,
            itemBuilder: (context, i) {
              final entry = _history[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    entry.category,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    entry.sector +
                        (entry.location.isNotEmpty ? '  •  ${_formatLocation(entry.location)}' : ''),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => _remove(i),
                  ),
                  onTap: () {
                    final parts = entry.location.split(',');
                    final lat = parts.length == 2 ? double.tryParse(parts[0]) : null;
                    final lng = parts.length == 2 ? double.tryParse(parts[1]) : null;
                    context.read<MainScreenBloc>().add(GoToWyszukajFirmyEvent(
                      autoCategory: entry.category,
                      autoSector: entry.sector,
                      autoLat: lat,
                      autoLng: lng,
                    ));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatLocation(String loc) {
    // "52.23,21.01" → skrót współrzędnych lub pusty string
    try {
      final parts = loc.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);
        return '${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}';
      }
    } catch (_) {}
    return '';
  }
}

class _SearchEntry {
  final String category;
  final String sector;
  final String location;
  const _SearchEntry({
    required this.category,
    required this.sector,
    required this.location,
  });
}