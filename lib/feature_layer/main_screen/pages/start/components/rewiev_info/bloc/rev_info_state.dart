part of 'rev_info_bloc.dart';

abstract class RevInfoComponentState {


}

class RevInfoComponentInitialState extends RevInfoComponentState {}

class RevInfoComponentMainState extends RevInfoComponentState {
  final List<Review> reviews;


  RevInfoComponentMainState(this.reviews);
}


class RevInfoComponentLoadingState extends RevInfoComponentState {}

class RevInfoComponentNextState extends RevInfoComponentState {




}
