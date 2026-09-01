import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../bloc/rules_page_bloc.dart';
import '../widgets/rule_1.dart';
import '../widgets/rule_2.dart';
import '../widgets/rule_3.dart';
import '../widgets/rule_4.dart';
import '../widgets/rule_5.dart';
import '../widgets/rule_6.dart';
import '../widgets/rule_7.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RulesPageBloc(repository: context.read<AppRepository>()),
      child: const View(),
    );
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  Widget build(BuildContext context) {
    return BlocConsumer<RulesPageBloc, RulesPageState>(
      listener: (context, state) {
        if (state is RulesPageMainState) {}
      },
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildWidgetBasedOnState(state),
        );
      },
    );
  }

  Widget _buildWidgetBasedOnState(RulesPageState state) {
    if (state is RulesPageLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    } else if (state is! RulesPageInitialState) {



      return SingleChildScrollView(
        child: Column(
          children: [

         const SizedBox(height: 16),
          Rule1(),
            const SizedBox(height: 16),
            Rule2(),
            const SizedBox(height: 16),
            Rule3(),
            const SizedBox(height: 16),
            Rule4(),
            const SizedBox(height: 16),
            Rule5(),
            const SizedBox(height: 16),
            Rule6(),
            const SizedBox(height: 16),
            Rule7(),
            const SizedBox(height: 60),
          ])

      );





    } else {
      return const Loading(key: ValueKey('Loading'));
    }
  }
}








