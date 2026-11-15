import 'package:qb/shared/widgets/empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qb/shared/constants.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/functions/plural.dart';
import '../../../../../shared/widgets/review.dart';
import '../bloc/start_page_bloc.dart';

class StartTabOtrzymaneRecenzje extends StatelessWidget {
  final StartPageState state;
  const StartTabOtrzymaneRecenzje({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final reviews = state.myReview;

    if (reviews.isEmpty) {
      return const EmptyState(
        icon: Icons.star_outline,
        title: 'Brak opinii',
        subtitle: 'Tu pojawią się recenzje wystawione Twojej firmie.',
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
              const SizedBox(width: kGapS),
              Text(avg.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('  (${reviews.length} ${plural(reviews.length, 'opinia', 'opinie', 'opinii')})',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(kGapL, kGapM, kGapL, kGapL),
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
      margin: const EdgeInsets.only(bottom: kGapM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kGapM),
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
              const SizedBox(width: kGapM),
            ],
            Expanded(child: ReviewWithComments(review: review)),
          ],
        ),
      ),
    );
  }
}