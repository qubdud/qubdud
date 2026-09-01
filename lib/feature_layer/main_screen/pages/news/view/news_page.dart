import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_dropdown.dart';
import 'package:qb/shared/widgets/w_label.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../../../bloc/main_appbar_cubit.dart';
import '../../news/widgets/news_card.dart';
import '../bloc/news_page_bloc.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NewsPageBloc(repository: context.read<AppRepository>(), mainBloc: context.read<MainScreenBloc>()),
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
    context.read<MainScreenControlCubit>().updateAppBar(height: 56, child: null);
    return BlocConsumer<NewsPageBloc, NewsPageState>(
      listener: (context, state) {
        if (state is NewsPageMainState) {}
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
          child: _buildWidgetBasedOnState(state, context),
        );
      },
    );
  }

  Widget _buildWidgetBasedOnState(NewsPageState state, BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;

    if (state is NewsPageLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    } else if (state is! NewsPageInitialState) {
      return SizedBox(
        width: maxColumnSize,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (isWideScreen) const SizedBox(height: 50),
              if (isWideScreen) WLabel(text: 'News'),
              Column(
                children: state.news.map((newsItem) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0), // Margines góra-dół
                    child: BpsNewsCard(
                      date: newsItem.publicationAt,
                      title: newsItem.title,
                      news: newsItem.content,
                      isNew: newsItem.isNew,
                      imageHtml: newsItem.imageUrl,
                      newsitem: newsItem,
                      con: context,
                    ),
                  );
                }).toList(),
              ),
              if (state.news.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0), // Margines góra-dół
                  child: WCard(
                    child: Padding(padding: const EdgeInsets.all(16.0), child: WSmallLabel(text: 'Brak aktualności')), // Margines góra-dół),
                  ),
                ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    } else {
      return const Loading(key: ValueKey('Loading'));
    }
  }
}
