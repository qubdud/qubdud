import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import '../../../../../../domain_layer/repository.dart';


part 'show_promo_page_event.dart';

part 'show_promo_page_state.dart';

class ShowPromoPageBloc extends Bloc<ShowPromoPageEvent, ShowPromoPageState> {
  ShowPromoPageBloc({
    required AppRepository repository,
  }) : super(ShowPromoPageMainState()) {
    on<TryShowPromoPageEvent>((event, emit) async {
      emit(ShowPromoPageLoadingState());





      emit(ShowPromoPageNextState());
    });
  }
}
