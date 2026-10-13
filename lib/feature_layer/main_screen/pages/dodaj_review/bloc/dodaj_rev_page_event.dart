part of 'dodaj_rev_page_bloc.dart';

abstract class DodajReviewPageEvent {}

class DodajDodajReviewPageEvent extends DodajReviewPageEvent {}

class SelectedDodajReviewPageEvent extends DodajReviewPageEvent {
  final File file;
  final String fileType;
  final String selectType;
  SelectedDodajReviewPageEvent({required this.fileType, required this.file, required this.selectType});
}

class GetDataDodajReviewPageEvent extends DodajReviewPageEvent {}
