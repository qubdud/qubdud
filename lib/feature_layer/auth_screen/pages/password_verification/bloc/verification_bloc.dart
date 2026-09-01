import 'dart:developer';

import 'package:bloc/bloc.dart';



import '../../../../../domain_layer/repository.dart';

part 'verification_event.dart';

part 'verification_state.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  VerificationBloc({
    required AppRepository repository,
    required Uri uri,
  }) : super(VerificationLoadingState()) {

    on<TryVerificationEvent>((event, emit) async {
      emit(VerificationLoadingState());



      print(uri.pathSegments[1]);
      print(uri.pathSegments[2]);
      print(uri.pathSegments[3]);
   //   var result = await repository.Verification(event.VerificationRequest);

   //   result.whenSuccess((response) {
        emit(VerificationNextState());
      });

   //   result.whenError((response) {
   //     showToastError(text: response.message);
   //     emit(VerificationErrorState(VerificationError: response));
  //    });
   // });


    on<GoToLoginVerificationEvent>((event, emit) async {
      emit(VerificationBackState());
    });



    add(TryVerificationEvent());
  }
}
