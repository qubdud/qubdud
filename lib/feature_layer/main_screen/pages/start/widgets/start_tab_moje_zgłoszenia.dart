import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/globals.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/start_page_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StartTabMojeZgloszenia extends StatelessWidget {
  final StartPageState state;

  const StartTabMojeZgloszenia({super.key, required this.state});

  @override
  Widget build(BuildContext context) {


    return ListView.builder(
      itemCount: state.myRequests.length,
      itemBuilder: (context, index) {
        final video = state.myRequests[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Globals.instance.selectedRequest = video;
                  context.read<MainScreenBloc>().add(
                    GoToShowRequestEvent(),
                  );
                },
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: video.thumbUrl,
                        width: 90,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (video.is24)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.running_with_errors_outlined,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(video.distance! / 1000).toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (video.description.isNotEmpty)
                        Text(
                          video.description,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Expanded(child: SizedBox()),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.message_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            context.read<MainScreenBloc>().add(
                              GoToChatEvent(video.userId),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );





















    return SingleChildScrollView(
      child: Column(
        children: state.myRequests.asMap().entries.map((entry) {
          final video = entry.value;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Globals.instance.selectedRequest = entry.value;
                    context.read<MainScreenBloc>().add(
                      GoToShowRequestEvent(),
                    );
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: video.thumbUrl,
                          width: 90,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (video.is24)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.running_with_errors_outlined,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(video.distance! / 1000).toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (video.description.isNotEmpty)
                          Text(
                            video.description,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const Expanded(child: SizedBox()),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.message_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              context.read<MainScreenBloc>().add(
                                GoToChatEvent(video.userId),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}