import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants.dart';

class MainScreenControlCubit extends Cubit<MainScreenControlState> {
  MainScreenControlCubit() : super(const MainScreenControlState());

  void updateAppBar(
      {String? title, bool? isVisible, VoidCallback? onBackPressed, Widget? child, double? height, Color? backgroundColor, String? key, bool? isMenuVisible, bool? isChildTitle, bool? showBack}) {
    // ekran z tekstowym tytułem nie może odziedziczyć widgetu tytułu
    // z poprzedniego ekranu (np. „Wyszukaj” + mapa na profilu firmy)
    final textTitle = title != null && isChildTitle == null;
    emit(state.copyWith(
        title: title,
        showBack: showBack,
        isVisible: isVisible,
        onBackPressed: onBackPressed,
        child: textTitle ? const SizedBox.shrink() : child,
        height: height,
        backgroundColor: backgroundColor,
        key: key,
        isMenuVisible: isMenuVisible,
        isChildTitle: textTitle ? false : isChildTitle));
  }

  bool getIsVisible() {
    return state.isVisible;
  }

  void setIsVisible(bool isVisible) {
    emit(state.copyWith(isVisible: isVisible));
  }

  bool getIsMenuVisible() {
    return state.isMenuVisible;
  }

  void setIsMenuVisible(bool isMenuVisible) {
    emit(state.copyWith(isMenuVisible: isMenuVisible));
  }
}

class MainScreenControlState {
  final String title;
  final bool isVisible;
  final bool isMenuVisible;
  final String key;
  final VoidCallback? onBackPressed;
  final Widget? child;
  final bool isChildTitle;
  final double height;
  final Color backgroundColor;

  /// false na ekranach dolnego paska (Kontakty/Profil/Dodaj) — strzałka
  /// „wstecz" ma sens tylko na ekranach w głąb.
  final bool showBack;

  const MainScreenControlState({
    this.showBack = true,
    this.title = '',
    this.isVisible = false,
    this.isMenuVisible = true,
    this.key = 'ChildKeyAppBar',
    this.onBackPressed,
    this.height = 56.0,
    this.child = const SizedBox.shrink(),
    this.isChildTitle = false,
    this.backgroundColor = Colors.transparent,
  });

  MainScreenControlState copyWith({
    bool? showBack,
    String? title,
    bool? isVisible,
    bool? isMenuVisible,
    bool? isChildTitle,
    String? key,
    VoidCallback? onBackPressed,
    Widget? child,
    double? height,
    Color? backgroundColor,
  }) {
    return MainScreenControlState(
        showBack: showBack ?? this.showBack,
        title: title ?? this.title,
        isMenuVisible: isMenuVisible ?? this.isMenuVisible,
        isVisible: isVisible ?? this.isVisible,
        key: key ?? this.key,
        onBackPressed: onBackPressed ?? this.onBackPressed,
        child: child ?? this.child,
        isChildTitle: isChildTitle ?? this.isChildTitle,
        height: height ?? this.height,
        backgroundColor: backgroundColor ?? this.backgroundColor);
  }
}
