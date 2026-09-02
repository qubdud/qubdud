import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import '../../../../../../shared/globals.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../bloc/start_page_bloc.dart';
import '../components/moje_zgloszenia/view/show_requests_view.dart';
import '../../profil_my/view/tab_kalendarz.dart';
import '../../../../../shared/functions/effective_role.dart';
import '../widgets/start_tab_favourites.dart';
import '../widgets/start_tab_rezerwacje.dart';
import '../widgets/start_tab_moi_klienci.dart';
import '../widgets/start_tab_otrzymane_rec.dart';
import '../widgets/start_tab_wyszukane.dart';
import '../../../../../shared/new_counts.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StartPageBloc(
        firebase: context.read<FirebaseService>(),
        user: context.read<MainScreenBloc>().state.user!,
      ),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isAnon;
  late bool _isCompany;

  @override
  void initState() {
    super.initState();
    final user = context.read<MainScreenBloc>().state.user;
    _isAnon = Globals.instance.anonim;
    _isCompany = (!_isAnon) && isCompanyMode(user);

    final length = _isAnon ? 1 : (_isCompany ? 3 : 4);
    final wanted = Globals.instance.startTab;
    Globals.instance.startTab = null;
    _tabController = TabController(
        length: length,
        vsync: this,
        initialIndex: (wanted ?? 0).clamp(0, length - 1));
    // Listener żeby setState przy zmianie taba → rebuild
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _markSeen(_tabController.index);
        setState(() {});
      }
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _markSeen(_tabController.index));
  }

  /// Zakładka otwarta → jej licznik znika (poza Kalendarzem: tam liczba
  /// oczekujących rezerwacji ma zostać, dopóki firma ich nie rozstrzygnie).
  void _markSeen(int index) {
    final key = _isCompany
        ? const ['zgloszenia', 'kalendarz', 'recenzje'][index]
        : const ['', 'rezerwacje', '', 'zgloszenia'][index];
    if (key.isEmpty || key == 'kalendarz') return;
    if ((NewCounts.counts[key] ?? 0) > 0) {
      NewCounts.markSeen(key).then((_) {
        if (mounted) setState(() {});
      });
    } else {
      NewCounts.markSeen(key);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Po restarcie apki StartPage bywa budowany zanim wczyta się konto —
  /// gdy tryb się zmieni, przestawiamy zakładki.
  void _syncTabs() {
    final user = context.read<MainScreenBloc>().state.user;
    final anon = Globals.instance.anonim;
    final company = (!anon) && isCompanyMode(user);
    if (anon == _isAnon && company == _isCompany) return;
    final length = anon ? 1 : (company ? 3 : 4);
    final old = _tabController;
    setState(() {
      _isAnon = anon;
      _isCompany = company;
      _tabController = TabController(length: length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          _markSeen(_tabController.index);
          setState(() {});
        }
      });
    });
    old.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncTabs();
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelColor: Colors.black,
            tabs: _isAnon
                ? const [Tab(text: 'Odkrywaj')]
                : _isCompany
                ? [
              const Tab(text: 'Zgłoszenia'),
              const Tab(text: 'Kalendarz'),
              const Tab(text: 'Recenzje'),
            ]
                : [
              const Tab(text: 'Odkrywaj'),
              const Tab(text: 'Rezerwacje'),
              const Tab(text: 'Ulubione'),
              const Tab(text: 'Zgłoszenia'),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<StartPageBloc, StartPageState>(
            builder: (context, state) {
              if (state is StartPageLoadingState) {
                return Loading(noText: true, key: UniqueKey());
              }
              return _buildContent(state);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent(StartPageState state) {
    if (_isAnon) return StartTabWyszukane(state: state);

    final idx = _tabController.index;

    if (_isCompany) {
      final myId = context.read<MainScreenBloc>().state.user?.id ?? '';
      switch (idx) {
        case 0: return MoiKlienciTab(key: const ValueKey(0), state: state);
        case 1: return TabKalendarz(
            key: const ValueKey(1), companyId: myId, showGenerator: false);
        case 2: return StartTabOtrzymaneRecenzje(key: const ValueKey(2), state: state);
      }
    } else {
      switch (idx) {
        case 0: return StartTabWyszukane(key: const ValueKey(0), state: state);
        case 1: return const StartTabRezerwacje(key: ValueKey(1));
        case 2: return StartTabFavourites(key: const ValueKey(2), state: state);
        case 3: return ShowRequestsComponent(key: const ValueKey(3));
      }
    }

    return const SizedBox.shrink();
  }
}