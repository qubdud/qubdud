part of 'dodaj_page_bloc.dart';

abstract class DodajPageEvent {}

class TryDodajPageEvent extends DodajPageEvent {}

class UploadDodajPageEvent extends DodajPageEvent {
  final File file;
  final File fileThumb;
  final String fileName;
  final String thumbName;
  final String fileType;
  final String selectType;


  UploadDodajPageEvent({
    required this.file,
    required this.fileThumb,
    required this.fileName,
    required this.thumbName,
    required this.fileType,
    required this.selectType,
  });
}




class UploadMetadataDodajPageEvent extends DodajPageEvent {

  final Reference fileRef;
  final Reference fileRefThumb;
  final String fileName;


  UploadMetadataDodajPageEvent({
    required this.fileRef,
    required this.fileRefThumb,
    required this.fileName,

});
}


class DodajDodajPageEvent extends DodajPageEvent {}

class SelectedDodajPageEvent extends DodajPageEvent {
  final File file;
  final String fileType;
  final String selectType;
  SelectedDodajPageEvent({required this.fileType, required this.file, required this.selectType});
}



