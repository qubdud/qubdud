import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';


import '../bloc/user_info_bloc.dart';


class UserInfoShortComponent extends StatelessWidget {
  final String id;
  const UserInfoShortComponent({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserInfoComponentBloc(
        firebase: context.read<FirebaseService>(),
        userId: id,
      ),
      child: const View(),
    );
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> with SingleTickerProviderStateMixin {


  @override
  Widget build(BuildContext context) {


    return Column(
      children: [

          BlocConsumer<UserInfoComponentBloc, UserInfoComponentState>(
            listener: (context, state) {
              if (state is UserInfoComponentNextState) {
                context.read<MainScreenBloc>().add(InitEvent());
              }
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

                child:


                _buildTabbedContent(state),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTabbedContent(UserInfoComponentState state) {


    if (state is UserInfoComponentLoadingState) {
      return CircularProgressIndicator(key: UniqueKey());
    }
    if (state is UserInfoComponentNextState) {
      return SizedBox.shrink();
    }

    return CircleAvatar(
      radius: 18,
      foregroundColor: Colors.white,
      backgroundColor: Colors.black38,
      child: Text(
        state.user!.firstName![0]+state.user!.lastName![0],

        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );


  }


}

