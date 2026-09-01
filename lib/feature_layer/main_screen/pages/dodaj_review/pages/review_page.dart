import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_button.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/dodaj_rev_page_bloc.dart';

class DodajReviewFormPage extends StatelessWidget {
  const DodajReviewFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<DodajReviewPageBloc>(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _desc = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DodajReviewPageBloc, DodajReviewPageState>(
      listener: (context, state) {
        if (state is DodajReviewPageNextState) {
          context.read<MainScreenBloc>().add(InitEvent());
        }
      },
      builder: (context, state) {
        final content = state.selectedContent;
        final thumbPath = state is DodajRequestPromoState ? state.thumbPath : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Podgląd wybranego pliku ───────────────────────
              if (content != null) ...[
                WSmallLabel(text: 'Wybrany plik'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Miniatura
                      thumbPath != null
                          ? Image.file(
                        File(thumbPath),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : content.fileType == 'img'
                          ? Image.file(
                        content.file,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.black,
                        child: const Center(
                          child: Icon(Icons.play_circle_outline,
                              color: Colors.white, size: 64),
                        ),
                      ),
                      // Badge typ pliku
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                content.fileType == 'video'
                                    ? Icons.videocam
                                    : Icons.photo,
                                color: Colors.white, size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                content.fileType == 'video' ? 'Video' : 'Zdjęcie',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Przycisk zmiany pliku
                      Positioned(
                        bottom: 8, left: 8,
                        child: GestureDetector(
                          onTap: () => context
                              .read<DodajReviewPageBloc>()
                              .add(GetDataDodajReviewPageEvent()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Zmień', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Gwiazdki ──────────────────────────────────────
              WSmallLabel(text: 'Twoja ocena'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () => setState(() => _rating = i + 1),
                  );
                }),
              ),
              if (_rating > 0)
                Center(
                  child: Text(
                    _ratingLabel(_rating),
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // ── Opis ──────────────────────────────────────────
              WInputField(
                label: 'Opis recenzji',
                controller: _desc,
                maxLines: 5,
                isPassword: false,
                hintText: 'Opisz swoją opinię o usłudze...',
              ),
              const SizedBox(height: 32),

              WButton(
                text: 'Dodaj recenzję',
                isEnabled: _rating > 0 && content != null,
                onPressed: () {
                  context.read<DodajReviewPageBloc>().state.reviewMetadata =
                      ReviewMetadata(
                        score: _rating,
                        description: _desc.text.trim(),
                      );
                  context
                      .read<DodajReviewPageBloc>()
                      .add(DodajDodajReviewPageEvent());
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Bardzo słabo';
      case 2: return 'Słabo';
      case 3: return 'Przeciętnie';
      case 4: return 'Dobrze';
      case 5: return 'Doskonale!';
      default: return '';
    }
  }
}

class StarRating extends StatefulWidget {
  final int maxRating;
  final ValueChanged<int>? onRatingChanged;
  const StarRating({super.key, this.maxRating = 5, this.onRatingChanged});

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber, size: 32,
          ),
          onPressed: () {
            setState(() => _rating = index + 1);
            widget.onRatingChanged?.call(_rating);
          },
        );
      }),
    );
  }
}