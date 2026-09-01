part of 'show_requests_bloc.dart';

abstract class ShowRequestsComponentState {


  static List<Request> requestsStatic = [];
  List<Request> get requests => requestsStatic;
  set requests(List<Request> value) {
    requestsStatic = value;
  }

  static List<Review> reviewsStatic = [];
  List<Review> get reviews => reviewsStatic;
  set reviews(List<Review> value) {
    reviewsStatic = value;
  }




}

class ShowRequestsComponentInitialState extends ShowRequestsComponentState {}

class ShowRequestsComponentMainState extends ShowRequestsComponentState {}


class ShowRequestsComponentLoadingState extends ShowRequestsComponentState {}

class ShowRequestsComponentNextState extends ShowRequestsComponentState {}
