import 'package:bloc/bloc.dart';
import 'package:qb/data_layer/data_models/request/contact.dart';
import 'package:qb/domain_layer/domain_models/business_task.dart';
import '../../../../../../domain_layer/repository.dart';
import '../../../../../domain_layer/domain_models/team_info.dart';
import '../../../../../domain_layer/domain_models/user_stats.dart';

part 'account_page_event.dart';

part 'account_page_state.dart';

class AccountPageBloc extends Bloc<AccountPageEvent, AccountPageState> {
  AccountPageBloc({
    required AppRepository repository,
  }) : super(AccountPageInitialState()) {
    on<GoToMainAccountPageEvent>((event, emit) async {
      emit(AccountPageMainState());
    });

    on<GetDataAccountPageEvent>((event, emit) async {
      emit(AccountPageLoadingState());

      var teamInfoReslut = await repository.getTeamInfo();
      teamInfoReslut.whenSuccess((res) {
        state.teamInfo = res;
      });

      var userStatisticsReslut = await repository.getUserScore();
      userStatisticsReslut.whenSuccess((res) {
        state.userStatistics = res;
      });

      var businessTaskReslut = await repository.getUserBusinessTasks();
      businessTaskReslut.whenSuccess((res) {
        state.businessTasks = res;
      });

      emit(StatisticsAccountPageState());
    });

    on<GoToStatisticsAccountPageEvent>((event, emit) async {
      emit(StatisticsAccountPageState());
    });

    on<GoToPersonalAccountPageEvent>((event, emit) async {
      emit(PersonalAccountPageState());
    });

    on<GoToPasswordAccountPageEvent>((event, emit) async {
      emit(PasswordAccountPageState());
    });

    on<TryDeleteAccountPageEvent>((event, emit) async {
      emit(AccountPageLoadingState());
      var result = await repository.sendContact(ContactRequest(subject: 'Account deletion', message: 'Please remove my account.'));

      result.whenSuccess((response) {
        emit(AccountPageDeletedState());

      });
      add(GoToPersonalAccountPageEvent());
    });




    add(GetDataAccountPageEvent());
  }
}
