part of 'profil_my_page_bloc.dart';

abstract class ProfilPubliczyPageState {
  final List<Promo> videos;
  final List<Request> requests;
  final List<Review> reviews;
  final ProfileInfo? companyInfo;
  final AppUser? targetUser;
  final double averageScore;

  const ProfilPubliczyPageState({
    this.videos = const [],
    this.requests = const [],
    this.reviews = const [],
    this.companyInfo,
    this.targetUser,
    this.averageScore = 0.0,
  });
}

// Stan początkowy
class ProfilPubliczyPageInitialState extends ProfilPubliczyPageState {
  const ProfilPubliczyPageInitialState() : super();
}

// Stan ładowania - może opcjonalnie trzymać stare dane, żeby UI nie migało
class ProfilPubliczyPageLoadingState extends ProfilPubliczyPageState {
  const ProfilPubliczyPageLoadingState({
    super.videos,
    super.requests,
    super.reviews,
    super.companyInfo,
    super.targetUser,
    super.averageScore,
  });
}

// Główny stan z danymi
class ProfilPubliczyPageMainState extends ProfilPubliczyPageState {
  const ProfilPubliczyPageMainState({
    required super.videos,
    required super.requests,
    required super.reviews,
    super.companyInfo,
    super.targetUser,
    super.averageScore = 0.0,
  });
}

// Stan błędu
class ProfilPubliczyPageErrorState extends ProfilPubliczyPageState {
  final String errorMessage;
  const ProfilPubliczyPageErrorState({required this.errorMessage});
}

class ProfilPubliczyPageNextState extends ProfilPubliczyPageState {}