import 'package:flutter/material.dart';
import 'package:qb/shared/globals.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';


import '../bloc/user_info_bloc.dart';


class UserInfoComponent extends StatefulWidget {
  final String id;
  final bool simpleMode; // Nowa flaga

  const UserInfoComponent({super.key, required this.id, this.simpleMode = false});

  @override
  State<UserInfoComponent> createState() => _UserInfoComponentState();
}


class _UserInfoComponentState extends State<UserInfoComponent> {

  @override
  void didUpdateWidget(covariant UserInfoComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      context.read<UserInfoComponentBloc>().add(GetDataUserInfoComponentEvent());
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserInfoComponentBloc(
        firebase: context.read<FirebaseService>(),
        userId: widget.id,
      ),
      child:  View(userId:widget.id, simpleMode: widget.simpleMode, ),
    );
  }
}

class View extends StatefulWidget {
  final String userId;
  final bool simpleMode;

  const View({super.key, required this.userId, required this.simpleMode, });

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

    String companyName ='Polskie Górnictwo Naftowe i Gazownictwo Spółka Akcyjna Example Long Company Name';
    var cN =(state as UserInfoComponentMainState).user.companyName??'Polskie Górnictwo Naftowe i Gazownictwo Spółka Akcyjna';
    String userName ='AA';
    var uN =(state).user.firstName![0]+state.user.lastName![0];
    if (uN.isNotEmpty){
      userName = uN;
    }
    if (cN.isNotEmpty){
      companyName = cN;
    }
    if (Globals.instance.anonim) {
      companyName = 'Firma · zaloguj się, aby zobaczyć';
      userName = '?';
    }

    final String initials = (state.user.firstName?[0] ?? '') + (state.user.lastName?[0] ?? '');

    if(widget.simpleMode)
    return Container(
      key: UniqueKey(),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.black.withOpacity(0.5),
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
        ),
      ),
    );






    return Column( key: UniqueKey(),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4,),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 4,),
            CircleAvatar(
              radius: 18,
              foregroundColor: Colors.white,
              backgroundColor: Colors.black38,
              child: Text(
                userName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            SizedBox(width: 4,),
            Flexible(child: Text(maxLines: 2, textAlign: TextAlign.center,  companyName, style: TextStyle(color: Colors.black, fontSize: 14),)),
          ],
        ),
        SizedBox(height: 4,),
        Padding(
          padding: const EdgeInsets.fromLTRB(4,0,0,0),
          child: Text( (state).user.companyCity??'Kielce'.toString(), style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),),
        ),
        if (!Globals.instance.anonim)
          Padding(
            padding: const EdgeInsets.fromLTRB(4,0,0,0),
            child: Text( (state).user.email??'', style: TextStyle(color: Colors.black,fontSize: 12, fontWeight: FontWeight.bold)),
          ),

      ],
    );












  }


}

