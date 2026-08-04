import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/campus_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dio_error_message.dart';

/// Hub campus : bibliothèque, transport, cantine.
class CampusHubScreen extends ConsumerStatefulWidget {
  const CampusHubScreen({super.key});

  @override
  ConsumerState<CampusHubScreen> createState() => _CampusHubScreenState();
}

class _CampusHubScreenState extends ConsumerState<CampusHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _overview;
  List<dynamic> _books = [];
  List<dynamic> _routes = [];
  List<dynamic> _plans = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _errMsg(Object e, {String fallback = 'Erreur'}) {
    if (e is DioException) {
      return dioErrorMessage(e, fallback: fallback);
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CampusApiService.overview(),
        CampusApiService.listBooks(),
        CampusApiService.listRoutes(),
        CampusApiService.listPlans(),
      ]);
      _overview = Map<String, dynamic>.from(results[0] as Map);
      _books = results[1] as List<dynamic>;
      _routes = results[2] as List<dynamic>;
      _plans = results[3] as List<dynamic>;
    } catch (e) {
      _overview = null;
      _books = [];
      _routes = [];
      _plans = [];
      _error = _errMsg(e, fallback: 'Chargement campus impossible');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtXof(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '$s FCFA';
  }

  Future<void> _showCreateBook() async {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvel ouvrage'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre *'),
                textCapitalization: TextCapitalization.sentences,
              ),
              TextField(
                controller: authorCtrl,
                decoration:
                    const InputDecoration(labelText: 'Auteur (optionnel)'),
              ),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantité'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final title = titleCtrl.text.trim();
    if (title.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le titre est obligatoire'),
          backgroundColor: dangerRed,
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final payload = <String, dynamic>{
        'title': title,
        'quantity': int.tryParse(qtyCtrl.text.trim()) ?? 1,
      };
      final author = authorCtrl.text.trim();
      if (author.isNotEmpty) payload['author'] = author;
      await CampusApiService.createBook(payload);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errMsg(e, fallback: 'Création impossible')),
          backgroundColor: dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showCreateRoute() async {
    final nameCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau circuit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  hintText: 'ex: Riviera → École',
                ),
              ),
              TextField(
                controller: capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacité (optionnel)',
                ),
              ),
              TextField(
                controller: feeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tarif FCFA (optionnel)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom du circuit est obligatoire'),
          backgroundColor: dangerRed,
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final payload = <String, dynamic>{'name': name};
      final cap = int.tryParse(capacityCtrl.text.trim());
      if (cap != null) payload['capacity'] = cap;
      final fee = int.tryParse(feeCtrl.text.trim());
      if (fee != null) payload['feeXof'] = fee;
      await CampusApiService.createRoute(payload);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errMsg(e, fallback: 'Création impossible')),
          backgroundColor: dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showCreatePlan() async {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '15000');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle formule cantine'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Libellé *',
                  hintText: 'ex: Demi-pension',
                ),
              ),
              TextField(
                controller: feeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tarif FCFA *',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le libellé est obligatoire'),
          backgroundColor: dangerRed,
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await CampusApiService.createPlan({
        'name': name,
        'feeXof': int.tryParse(feeCtrl.text.trim()) ?? 0,
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errMsg(e, fallback: 'Création impossible')),
          backgroundColor: dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _errorBanner(String msg) {
    return Card(
      color: dangerLight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(msg, style: const TextStyle(color: dangerRed)),
      ),
    );
  }

  Widget _overviewChips() {
    final o = _overview;
    final chips = [
      ('Ouvrages', o?['books']),
      ('Prêts ouverts', o?['openLoans']),
      ('Circuits', o?['routes']),
      ('Formules', o?['plans']),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) {
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: primaryBlue.withValues(alpha: 0.12),
            child: const Icon(Icons.circle, size: 8, color: primaryBlue),
          ),
          label: Text(
            '${c.$1} · ${c.$2 ?? '—'}',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: surfaceWhite,
          side: const BorderSide(color: border),
        );
      }).toList(),
    );
  }

  Widget _empty(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(msg, style: const TextStyle(color: textGrey)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canWrite =
        auth.isOwner || auth.isDirector || auth.isSecretary;
    final canWriteCanteen = canWrite || auth.isAccountant;

    VoidCallback? fabAction;
    if (!_loading && !_busy) {
      switch (_tabs.index) {
        case 0:
          if (canWrite) fabAction = _showCreateBook;
          break;
        case 1:
          if (canWrite) fabAction = _showCreateRoute;
          break;
        case 2:
          if (canWriteCanteen) fabAction = _showCreatePlan;
          break;
      }
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Campus'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Bibliothèque'),
            Tab(text: 'Transport'),
            Tab(text: 'Cantine'),
          ],
        ),
      ),
      floatingActionButton: fabAction == null
          ? null
          : FloatingActionButton(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              onPressed: fabAction,
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            _errorBanner(_error!),
                            const SizedBox(height: 12),
                          ],
                          if (_overview != null) ...[
                            _overviewChips(),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabs,
                  children: [
                    _booksList(canWrite),
                    _routesList(canWrite),
                    _plansList(canWriteCanteen),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _booksList(bool canWrite) {
    if (_books.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _empty('Aucun ouvrage'),
          if (canWrite)
            Center(
              child: TextButton.icon(
                onPressed: _busy ? null : _showCreateBook,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un ouvrage'),
              ),
            ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _books.length,
      itemBuilder: (_, i) {
        final b = Map<String, dynamic>.from(_books[i] as Map);
        final author = b['author']?.toString();
        return Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_outlined, color: primaryBlue),
            title: Text(
              b['title']?.toString() ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                if (author != null && author.isNotEmpty) author,
                'Dispo ${b['available'] ?? '—'}/${b['quantity'] ?? '—'}',
              ].join(' · '),
            ),
          ),
        );
      },
    );
  }

  Widget _routesList(bool canWrite) {
    if (_routes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _empty('Aucun circuit'),
          if (canWrite)
            Center(
              child: TextButton.icon(
                onPressed: _busy ? null : _showCreateRoute,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un circuit'),
              ),
            ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _routes.length,
      itemBuilder: (_, i) {
        final r = Map<String, dynamic>.from(_routes[i] as Map);
        final count = r['_count'] is Map
            ? (r['_count'] as Map)['assignments']
            : null;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.directions_bus_outlined,
                color: primaryBlue),
            title: Text(
              r['name']?.toString() ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                if (count != null) '$count élève(s)',
                if (r['capacity'] != null) 'Cap. ${r['capacity']}',
                _fmtXof(r['feeXof'] ?? 0),
              ].join(' · '),
            ),
          ),
        );
      },
    );
  }

  Widget _plansList(bool canWrite) {
    if (_plans.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _empty('Aucune formule'),
          if (canWrite)
            Center(
              child: TextButton.icon(
                onPressed: _busy ? null : _showCreatePlan,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une formule'),
              ),
            ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (_, i) {
        final p = Map<String, dynamic>.from(_plans[i] as Map);
        return Card(
          child: ListTile(
            leading:
                const Icon(Icons.restaurant_outlined, color: primaryBlue),
            title: Text(
              p['name']?.toString() ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                _fmtXof(p['feeXof'] ?? 0),
                if (p['mealsPerWeek'] != null)
                  '${p['mealsPerWeek']} repas/sem',
              ].join(' · '),
            ),
          ),
        );
      },
    );
  }
}
