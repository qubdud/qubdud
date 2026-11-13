part of 'dodaj_page_bloc.dart';

abstract class DodajPageEvent {}

class DodajDodajPageEvent extends DodajPageEvent {}

class SkipFileDodajPageEvent extends DodajPageEvent {}

class SelectedDodajPageEvent extends DodajPageEvent {
  final File file;
  final String fileType;
  final String selectType;
  SelectedDodajPageEvent({required this.fileType, required this.file, required this.selectType});
}
