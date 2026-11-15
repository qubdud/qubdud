part of 'show_request_page_bloc.dart';

abstract class ShowRequestPageEvent {}

class TryShowRequestPageEvent extends ShowRequestPageEvent {}

class RequestChangedShowRequestPageEvent extends ShowRequestPageEvent {
  final Request request;
  RequestChangedShowRequestPageEvent(this.request);
}
