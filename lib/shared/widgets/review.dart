import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain_layer/domain_models/promoVideo.dart';
import '../../domain_layer/firebase_service.dart';
import '../../feature_layer/main_screen/bloc/main_bloc.dart';
import '../functions/show_toast_error.dart';

/// Widget recenzji z sekcją komentarzy.
/// Zasada: każdy user/firma może dodać dokładnie 1 komentarz.
class ReviewWithComments extends StatefulWidget {
  final Review review;
  final bool showCompanyActions; // czy pokazać "odpowiedz jako firma"

  /// Nazwa firmy, której dotyczy recenzja — podawana na profilu użytkownika
  /// (tam autor jest oczywisty, ważne jest KOGO ocenił).
  final String? subjectName;

  const ReviewWithComments({
    super.key,
    required this.review,
    this.showCompanyActions = false,
    this.subjectName,
  });

  @override
  State<ReviewWithComments> createState() => _ReviewWithCommentsState();
}

class _ReviewWithCommentsState extends State<ReviewWithComments> {
  List<ReviewComment> _comments = [];
  bool _loading = true;
  bool _showInput = false;
  bool _alreadyCommented = false;
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _authorName = '';

  Future<void> _load() async {
    final firebase = context.read<FirebaseService>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final comments = await firebase.getCommentsForReview(widget.review.id);
      final already = await firebase.hasUserCommented(
        reviewId: widget.review.id,
        userId: uid,
      );
      // Pobierz nazwę autora jeśli nie ma w modelu
      String authorName = widget.review.authorName;
      if (authorName.isEmpty) {
        final author = await firebase.fetchUser(widget.review.userId);
        authorName = author?.displayName ?? '';
      }
      if (mounted) {
        setState(() {
          _comments = comments;
          _alreadyCommented = already;
          _authorName = authorName;
          _loading = false;
        });
      }
    } catch (_) {
      // bez komentarzy recenzja i tak jest czytelna — chowamy tylko spinner
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final firebase = context.read<FirebaseService>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final user = context.read<MainScreenBloc>().state.user;
    final name = user?.displayName ?? '';
    final isOwner = user?.firma == true &&
        user?.id == widget.review.reviewedUserId;

    try {
      await firebase.addComment(ReviewComment(
        id: '',
        reviewId: widget.review.id,
        authorId: uid,
        authorName: name,
        isOwner: isOwner,
        text: text,
      ));
    } catch (_) {
      showToastError(text: 'Nie udało się dodać komentarza');
      return;
    }
    if (!mounted) return;

    _ctrl.clear();
    setState(() {
      _showInput = false;
      _alreadyCommented = true;
    });
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return GestureDetector(
      onTap:(){context.read<MainScreenBloc>().add(GoToProfilPublicznyFirmyEvent(widget.review.reviewedUserId));},


      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          


          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                i < widget.review.score ? Icons.star : Icons.star_border,
                color: Colors.amber, size: 16,
              )),
              const SizedBox(width: 6),
              Expanded(
                child:


                GestureDetector(
                  onTap:(){context.read<MainScreenBloc>().add(GoToProfilPublicznyUseraEvent(widget.review.userId));},


                  child:


                  widget.subjectName != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.storefront_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(widget.subjectName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          ],
                        )
                      : Text(
                          _authorName.isNotEmpty
                              ? _authorName
                              : widget.review.authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              if (widget.review.timestamp != null)
                Text(
                  '${widget.review.timestamp!.day}.${widget.review.timestamp!.month}.${widget.review.timestamp!.year}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          if (widget.review.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(widget.review.description, style: const TextStyle(fontSize: 13)),
          ],

          // ── Komentarze ────────────────────────────────────────
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            if (_comments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._comments.map((c) => _CommentBubble(
                comment: c,
                canDelete: c.authorId == uid,
                onDelete: () async {
                  try {
                    await context.read<FirebaseService>().deleteComment(
                      reviewId: widget.review.id,
                      commentId: c.id,
                    );
                  } catch (_) {
                    showToastError(text: 'Nie udało się usunąć komentarza');
                    return;
                  }
                  _load();
                },
              )),
            ],

            // Komentować może autor recenzji albo oceniona firma — nikt postronny
            if (!_alreadyCommented &&
                (uid == widget.review.userId ||
                    uid == widget.review.reviewedUserId)) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _showInput = !_showInput),
                child: Text(
                  _showInput ? 'Anuluj' : 'Dodaj komentarz',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (_showInput) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(fontSize: 14),
                        controller: _ctrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Twój komentarz...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _submit,
                      icon: const Icon(Icons.send, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final ReviewComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  const _CommentBubble({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 6, left: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: comment.isOwner
            ? (isDark ? const Color(0xFF17263A) : Colors.blue.shade50)
            : (isDark ? const Color(0xFF2A2930) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: comment.isOwner
              ? (isDark ? Colors.blue.shade800 : Colors.blue.shade200)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: comment.isOwner
                              ? (isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade700)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                    if (comment.isOwner) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('firma', style: TextStyle(fontSize: 9, color: Colors.blue)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (canDelete)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}