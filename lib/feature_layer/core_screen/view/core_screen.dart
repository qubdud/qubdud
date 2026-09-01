import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants.dart';
import '../../auth_screen/view/auth_screen.dart';
import '../../main_screen/bloc/main_appbar_cubit.dart';
import '../../main_screen/view/main_page.dart';
import '../../../shared/widgets/loading.dart';
import '../widgets/background.dart';
import '../bloc/core_screen_bloc.dart';

class CoreScreen extends StatelessWidget {
  const CoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CoreScreenBloc()),
        BlocProvider(create: (_) => MainScreenControlCubit()),
      ],
      child: const View(),
    );
  }
}

class View extends StatelessWidget {
  const View({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoreScreenBloc, CoreScreenState>(
      listener: (context, state) {},
      builder: (context, state) {
        return BackgroundImage(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildWidgetBasedOnState(state, context),
          ),
        );
      },
    );
  }

  Widget _buildWidgetBasedOnState(CoreScreenState state, BuildContext context) {
    if (state is CoreScreenInitialState) {
      return SizedBox(key: UniqueKey());
    } else if (state is CoreScreenUnauthenticatedState) {
      return const AuthScreen(key: ValueKey('AuthScreen'));
    } else if (state is CoreScreenAuthenticatedState) {
      return const MainScreen(key: ValueKey('MainMob'));
    } else if (state is CoreScreenLoadingState) {
      return Material(
          color: Colors.transparent,
          child: Loading(key: ValueKey('Loading')));
    } else {
      return const SizedBox();
    }
  }
}