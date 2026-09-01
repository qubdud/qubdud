import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../shared/widgets/review.dart';
import '../bloc/start_page_bloc.dart';

class StartTabMojeRecenzje extends StatelessWidget {
  final StartPageState state;
  const StartTabMojeRecenzje({super.key, required this.state});

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
            Text('Brak recenzji', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reviews.length,
      itemBuilder: (context, i) => ReviewWithComments(
        review: reviews[i],
        showCompanyActions: false,
      ),
    );
  }
}