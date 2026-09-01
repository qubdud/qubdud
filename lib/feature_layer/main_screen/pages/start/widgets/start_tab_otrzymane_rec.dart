import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/widgets/review.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/start_page_bloc.dart';

class StartTabOtrzymaneRecenzje extends StatelessWidget {
  final StartPageState state;
  const StartTabOtrzymaneRecenzje({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final reviews = state.myReview;

    if (reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 56, color: Colors.black12),
            SizedBox(height: 12),
            Text('Brak opinii', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Średnia
    final avg = reviews.fold<double>(0, (s, r) => s + r.score) / reviews.length;

    return Column(
      children: [
        // Pasek z oceną
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.amber.shade50,
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 6),
              Text(avg.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('  (${reviews.length} opinii)',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reviews.length,
            itemBuilder: (context, i) => _ReviewCard(review: reviews[i]),
          ),
        ),
      ],
    );
  }
}

// Identyczna karta jak w profilu publicznym
class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (review.thumbUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: review.thumbUrl,
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: ReviewWithComments(review: review)),
          ],
        ),
      ),
    );
  }
}