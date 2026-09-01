import 'dart:developer';

import 'package:bloc/bloc.dart';

import '../../../../../../domain_layer/repository.dart';

part 'rules_page_event.dart';

part 'rules_page_state.dart';

class RulesPageBloc extends Bloc<RulesPageEvent, RulesPageState> {
  RulesPageBloc({
    required AppRepository repository,
  }) : super(RulesPageInitialState()) {
    on<GoToMainRulesPageEvent>((event, emit) async {
      emit(RulesPageMainState());
    });

    on<GetDataRulesPageEvent>((event, emit) async {
      emit(RulesPageLoadingState());
      emit(RulesPageMainState());
    });
    add(GetDataRulesPageEvent());
  }
}
