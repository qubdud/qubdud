part of 'single_video_page_bloc.dart';

// single_video_page_state.dart

abstract class SingleVideoPageState {}

class SingleVideoPageLoadingState extends SingleVideoPageState {}

class SingleVideoPageMainState extends SingleVideoPageState {
  final Promo promo;
  final AppUser author;
  final List<dynamic> reviews;

  SingleVideoPageMainState({
    required this.promo,
    required this.author,
    required this.reviews,
  });

  int get averageRating {
    if (reviews.isEmpty) return 0;
    final avg = reviews.map((r) => r.score).reduce((a, b) => a + b) / reviews.length;
    return avg.round();
  }
}