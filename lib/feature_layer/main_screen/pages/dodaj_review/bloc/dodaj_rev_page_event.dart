part of 'dodaj_rev_page_bloc.dart';

abstract class DodajReviewPageEvent {}

class TryDodajReviewPageEvent extends DodajReviewPageEvent {}

class UploadDodajReviewPageEvent extends DodajReviewPageEvent {
  final File file;
  final File fileThumb;
  final String fileName;
  final String thumbName;
  final String fileType;
  final String selectType;


  UploadDodajReviewPageEvent({
    required this.file,
    required this.fileThumb,
    required this.fileName,
    required this.thumbName,
    required this.fileType,
    required this.selectType,
  });
}




class UploadMetadataDodajReviewPageEvent extends DodajReviewPageEvent {

  final Reference fileRef;
  final Reference fileRefThumb;
  final String fileName;


  UploadMetadataDodajReviewPageEvent({
    required this.fileRef,
    required this.fileRefThumb,
    required this.fileName,

});
}


class DodajDodajReviewPageEvent extends DodajReviewPageEvent {}

class SelectedDodajReviewPageEvent extends DodajReviewPageEvent {
  final File file;
  final String fileType;
  final String selectType;
  SelectedDodajReviewPageEvent({required this.fileType, required this.file, required this.selectType});
}

class GetDataDodajReviewPageEvent extends DodajReviewPageEvent {}



