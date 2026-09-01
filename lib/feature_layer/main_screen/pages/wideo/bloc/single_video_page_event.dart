part of 'single_video_page_bloc.dart';

abstract class SingleVideoPageEvent {}

class GetDataSingleVideoEvent extends SingleVideoPageEvent {}

class ToggleFavoriteVideoEvent extends SingleVideoPageEvent {
  final String promoId;
  final bool isFavorite;
  ToggleFavoriteVideoEvent({required this.promoId, required this.isFavorite});
}