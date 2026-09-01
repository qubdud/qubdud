import 'package:qb/domain_layer/domain_models/user_invite_request.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:qb/shared/widgets/w_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/domain_models/team_invite.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../../../../../shared/widgets/w_dropdown.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/invite_team_page_bloc.dart';

class OfferInviteTeamPage extends StatelessWidget {
  const OfferInviteTeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return View();
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> with SingleTickerProviderStateMixin {
  List<UserInviteRequest> requests = [];


  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;
    requests = context.read<InviteTeamPageBloc>().state.usersRequests;


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
          child: SizedBox(
            width: maxColumnSize,
            child: Column(
              children: [
                SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SelectableText(
                    'Remember that you cannot remove a user from your team once you have accepted them. You have 24 hours to accept the offer.',
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 24,
                ),

                Column(
                  children: requests.map((user) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                      child: WCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    countryFlagImages[user.countryCode] ?? "assets/images/placeholder.png",
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 10),


                                Expanded(
                                  child: Text(user.userName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: groupColors[user.departmentCode.toUpperCase()] ?? Colors.grey, // Pobieranie koloru grupy
                                    borderRadius: BorderRadius.circular(15), // Jajowaty kształt
                                  ),
                                  child: SelectableText(
                                    user.department,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // Dostosuj kolor tekstu jeśli potrzeba
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),



                              ],
                            ),
                            SizedBox(height: 16,),
                            WButton(text: 'Accept',
                              onPressed: (){
                                var parentContext = context;
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Center(
                                      child: WCard(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: isWideScreen ? 16 : 0, horizontal: isWideScreen ? 40 : 0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SelectableText(
                                                  'Do you want to accept this passenger?',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                                ),
                                                SizedBox(height: 20),
                                                SelectableText('You cannot remove a user from your team once you have accepted them.', textAlign: TextAlign.center,),
                                                SizedBox(height: 20),
                                                WButton(
                                                    text: 'Yes, I want to accept',
                                                    onPressed: () {
                                                      if (mounted) {
                                                        parentContext.read<InviteTeamPageBloc>().add(AcceptOfferInviteTeamPageEvent(user.userId));
                                                      }
                                                      Navigator.of(context, rootNavigator: true).pop();
                                                    }),
                                                SizedBox(height: 24,),
                                                WButton(
                                                    colorType: ButtonColorType.white,
                                                    text: 'No, take me back',
                                                    onPressed: () {
                                                      Navigator.of(context, rootNavigator: true).pop();
                                                    }),

                                              ],
                                            ),
                                          )),
                                    );
                                  },
                                );


                              },





                            ),
                            SizedBox(height: 16,),
                            SelectableText('Invitation received: ${user.receivedDate}')


                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),








                if(requests.isEmpty) const SizedBox(height: 16),
                if(requests.isEmpty) WLabel(text: 'No one has sent a request to join your team yet.'),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
  }
}
Map<String, Color> groupColors = {
  'OP': cMidRed,
  'OT': cMidOrange,
  'IT': cMidPurple,
};

