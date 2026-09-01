import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_button_small.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:qb/shared/widgets/w_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/domain_models/team_invite.dart';
import '../../../../../domain_layer/domain_models/user_invite.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../../../../../shared/widgets/w_dropdown.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/invite_team_page_bloc.dart';

class InviteInviteTeamPage extends StatelessWidget {
  const InviteInviteTeamPage({super.key});

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
  List<UserInvite> filter = [];
  TextEditingController search = TextEditingController();
  TextEditingController country = TextEditingController();
  TextEditingController department = TextEditingController();
  late TabController tabController;
  List<String> countries = [];
  List<String> departments = [];
  List<UserInvite> list = [];
  final ScrollController _scrollController = ScrollController(); // 🔹 Kontroler

  @override
  void dispose() {
    _scrollController.dispose(); // 🔹 Zawsze zwalniaj zasoby!
    super.dispose();
  }







  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    filter = context.read<InviteTeamPageBloc>().state.invitableUsers;
    list = context.read<InviteTeamPageBloc>().state.invitableUsers;
  }

  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;

    countries = context.read<InviteTeamPageBloc>().state.invitableUsers.map((invite) => invite.country).toList().fold<List<String>>([], (previous, element) {
      if (!previous.contains(element)) previous.add(element);
      return previous;
    });
    countries.add('All');

    departments = context.read<InviteTeamPageBloc>().state.invitableUsers.map((invite) => invite.department).toList().fold<List<String>>([], (previous, element) {
      if (!previous.contains(element)) previous.add(element);
      return previous;
    });
    departments.add('All');

    var width = MediaQuery.of(context).size.width;
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 16),
          child: Column(
            children: [
              SelectableText(
                'Invite new passengers to your team. Each team must include at least 4 people from different countries and at least 3 people from different departments. Each passenger has 24 hours to accept your invitation.',
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 24,
              ),
              if (isWideScreen)
                WInputField(
                  controller: search,
                  onChanged: (val) {
                    filterList(); // Filtruj listę po zmianie tekstu
                  },
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search',
                  focusColor: cDarkBlue,
                ),
              if (isWideScreen)
                SizedBox(
                  height: 16,
                ),
              if (isWideScreen)
                WAnimatedDropdown(
                  controller: department,
                  label: 'FILTER BY DEPARTMENT',
                  items: departments,
                  hintText: 'Choose from the list',
                  onItemSelected: (a) {
                    if (a == 'All') {
                      department.clear();
                      filterList(); // Filtruj listę po zmianie tekstu
                    } else {
                      filterList(); // Filtruj listę po zmianie tekstu
                    }
                  },
                ),
              if (isWideScreen)
                if (isWideScreen)
                  SizedBox(
                    height: 16,
                  ),
              if (isWideScreen)
                WAnimatedDropdown(
                  controller: country,
                  label: 'FILTER BY COUNTRY',
                  items: countries,
                  hintText: 'Choose from the list',
                  onItemSelected: (a) {
                    if (a == 'All') {
                      country.clear();
                    }
                    filterList();
                  },
                ),
              SizedBox(
                height: 16,
              ),
              if (!isWideScreen)
                Scrollbar(
                  controller: _scrollController,

                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal, // Przewijanie w poziomie
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 100, // Minimalna szerokość dropdowna
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // WAŻNE! Pozwala Row działać poprawnie w przewijanym układzie
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 150, // Minimalna szerokość dropdowna
                              maxWidth: 300, // Maksymalna szerokość
                            ),
                            child: WInputField(
                              controller: search,
                              onChanged: (val) {
                                filterList(); // Filtruj listę po zmianie tekstu
                              },
                              label: 'Search by name'.toUpperCase(),
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search',
                              focusColor: cDarkBlue,
                            ),
                          ),
                          SizedBox(width: 16),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 150, // Minimalna szerokość dropdowna
                              maxWidth: 300, // Maksymalna szerokość
                            ),
                            child: WAnimatedDropdown(
                              controller: department,
                              label: 'FILTER BY DEPARTMENT',
                              items: departments,
                              hintText: 'Choose from the list',
                              onItemSelected: (a) {
                                if (a == 'All') {
                                  department.clear();
                                }
                                filterList();
                              },
                            ),
                          ),
                          SizedBox(width: 16), // Odstęp między dropdownami

                          // Dropdown dla kraju
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 150, // Minimalna szerokość dropdowna
                              maxWidth: 300, // Maksymalna szerokość
                            ),
                            child: WAnimatedDropdown(
                              controller: country,
                              label: 'FILTER BY COUNTRY',
                              items: countries,
                              hintText: 'Choose from the list',
                              onItemSelected: (a) {
                                if (a == 'All') {
                                  country.clear();
                                }
                                filterList();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: 16,
              ),
              Column(
                children: filter.map((user) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                    child: Row(
                      children: [
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: groupColors[user.departmentCode],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(1, 2),
                              ),
                            ],
                          ),
                          child: Center(
                              child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
                            child: SelectableText(
                              user.departmentCode,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )),
                        ),
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

                        // Kod kraju
                        SizedBox(
                          width: 30,
                          child: Text(
                            user.countryCode,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                        ),
                        SizedBox(width: 10),

                        // Imię i nazwisko
                        Expanded(
                          child: Text(user.userName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                        if (user.isInvitationSent)
                          SizedBox(
                              height: 32,
                              width: 60,
                              child: Center(
                                  child: Icon(
                                Icons.check_circle_outline,
                                color: cDarkBlue,
                                size: 24,
                              ))),

                        if (!user.isInvitationSent)
                          SizedBox(
                              height: 32,
                              width: 60,
                              child: Center(
                                  child: WButtonSmall(
                                text: 'Invite',
                                onPressed: () {
                                  setState(() {
                                    context.read<InviteTeamPageBloc>().add(SendInviteTeamPageEvent(user.userId));
                                    user.isInvitationSent = true;
                                    filter;
                                  });
                                },
                              ))),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if(filter.isEmpty) const SizedBox(height: 16),
              if(filter.isEmpty) WLabel(text: 'No search results found.'),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  void filterList() {
    filter = list.where((invite) {
      bool matchesSearch = search.text.isEmpty || invite.userName.toLowerCase().contains(search.text.toLowerCase());

      bool matchesDepartment = department.text.isEmpty || invite.department == department.text;

      bool matchesCountry = country.text.isEmpty || invite.country == country.text;

      return matchesSearch && matchesDepartment && matchesCountry;
    }).toList();

    setState(() {});
  }
}

Map<String, Color> groupColors = {
  'OP': cMidRed,
  'OT': cMidOrange,
  'IT': cMidPurple,
};
