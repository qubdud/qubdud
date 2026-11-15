import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/empty_state.dart';
import 'package:qb/shared/widgets/promo_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../bloc/main_bloc.dart';
import '../bloc/start_page_bloc.dart';

/// Zakładka „Odkrywaj" — pierwsza rzecz, jaką widzi użytkownik:
/// duży przycisk szukania, ostatnie wyszukania jako chipy i siatka
/// prezentacji firm (tap = pionowy feed wideo).
class StartTabWyszukane extends StatefulWidget {
  final StartPageState state;
  const StartTabWyszukane({super.key, required this.state});

  @override
  State<StartTabWyszukane> createState() => _StartTabWyszukaneState();
}

class _StartTabWyszukaneState extends State<StartTabWyszukane> {
  List<_SearchEntry> _history = [];

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
    // jedna pozycja na kategorię+branżę (współrzędne różnią się co wyszukanie)
    final seen = <String>{};
    entries.retainWhere((e) => seen.add('${e.category}|${e.sector}'));
    if (mounted) setState(() => _history = entries);
  }

  Future<void> _remove(_SearchEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('search_history') ?? [];
    raw.removeWhere((e) => e.startsWith('${entry.category}|${entry.sector}|'));
    await prefs.setStringList('search_history', raw);
    setState(() => _history.remove(entry));
  }

  void _repeat(_SearchEntry entry) {
    final parts = entry.location.split(',');
    final lat = parts.length == 2 ? double.tryParse(parts[0]) : null;
    final lng = parts.length == 2 ? double.tryParse(parts[1]) : null;
    context.read<MainScreenBloc>().add(GoToWyszukajFirmyEvent(
          autoCategory: entry.category,
          autoSector: entry.sector,
          autoLat: lat,
          autoLng: lng,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final videos = widget.state.videos;

    return ListView(
      padding: const EdgeInsets.fromLTRB(kGapL, kGapL, kGapL, kGapXl),
      children: [
        // ── Szukaj ─────────────────────────────────────────
        FilledButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('Szukaj firmy / usługi'),
          style: FilledButton.styleFrom(
            backgroundColor: cDarkBlue,
            foregroundColor: Colors.white,
          ),
          onPressed: () =>
              context.read<MainScreenBloc>().add(GoToWyszukajFirmyEvent()),
        ),

        // ── Ostatnie wyszukania jako chipy ─────────────────
        if (_history.isNotEmpty) ...[
          const SizedBox(height: kGapL),
          const _SectionTitle('Ostatnio szukane'),
          const SizedBox(height: kGapS),
          Wrap(
            spacing: kGapS,
            runSpacing: kGapS,
            children: _history
                .map((e) => InputChip(
                      avatar: const Icon(Icons.history, size: 16),
                      label: Text(e.sector,
                          style: const TextStyle(fontSize: 13)),
                      onPressed: () => _repeat(e),
                      onDeleted: () => _remove(e),
                      deleteIconColor: Colors.grey,
                    ))
                .toList(),
          ),
        ],

        // ── Prezentacje firm ───────────────────────────────
        const SizedBox(height: kGapXl),
        const _SectionTitle('Poznaj firmy',
            subtitle: 'Dotknij, aby obejrzeć prezentację'),
        const SizedBox(height: kGapS),
        if (videos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: kGapXl),
            child: EmptyState(
              icon: Icons.videocam_outlined,
              title: 'Jeszcze nic tu nie ma',
              subtitle: 'Użyj wyszukiwarki, aby znaleźć firmy w swojej okolicy.',
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: kGapM,
              mainAxisSpacing: kGapM,
            ),
            itemCount: videos.length,
            itemBuilder: (context, i) => PromoTile(
              promo: videos[i],
              onTap: () => context.read<MainScreenBloc>().add(
                  GoToPromoFirmyEvent(videos[i],
                      playlist: videos, initialIndex: i)),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final String? subtitle;
  const _SectionTitle(this.text, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (subtitle != null)
          Text(subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
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
