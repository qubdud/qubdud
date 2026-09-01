import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/shared/constants.dart';

import '../bloc/main_appbar_cubit.dart';

class AppBarComponent extends StatelessWidget {
  const AppBarComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainScreenControlCubit, MainScreenControlState>(
      builder: (context, state) {
        Widget? child = state.child;
        bool childTitle = state.isChildTitle;

        return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: state.isVisible ? MediaQuery.of(context).padding.top + state.height : 0, // Zmienna wysokość
            child: SizedBox(child: BpsAppBar(state.title, state.onBackPressed, child, childTitle, state.backgroundColor, state.key)));
      },
    );
  }
}

Widget BpsAppBar(String appBarTitle, VoidCallback? appBarVoidCallback, Widget? child, bool childTitle, Color background, String key) {
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
    child: SingleChildScrollView(
      key: ValueKey(key),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: background == Colors.transparent ? Colors.transparent : Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            AppBar(
                centerTitle: true,
                scrolledUnderElevation: 0.0,
                backgroundColor: Colors.transparent,
                title: childTitle
                    ? child
                    : Text(
                  appBarTitle,
                  style: const TextStyle(
                    color: cDarkerBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_outlined),
                  color: cDarkerBlue,
                  onPressed: appBarVoidCallback,
                ),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ))),
            if (child != null && !childTitle) child,
          ],
        ),
      ),
    ),
  );
}