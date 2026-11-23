import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'browser_url.dart';
import 'design.dart';
import 'dialogs.dart';
import 'screens.dart';
import 'store.dart';

class MeetHalfwayApp extends StatelessWidget {
  const MeetHalfwayApp({super.key, required this.store});
  final MeetStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MeetHalfway · Good plans, together.',
    debugShowCheckedModeBanner: false,
    theme: MH.theme(),
    scrollBehavior: const MaterialScrollBehavior().copyWith(
      physics: const ClampingScrollPhysics(),
    ),
    home: MeetShell(store: store),
  );
}

const destinations = [
  ('discover', 'Discover', Icons.auto_awesome_outlined),
  ('plans', 'My plans', Icons.calendar_today_outlined),
  ('preferences', 'Preferences', Icons.tune_rounded),
  ('privacy', 'Privacy', Icons.shield_outlined),
];

class MeetShell extends StatefulWidget {
  const MeetShell({super.key, required this.store});
  final MeetStore store;
  @override
  State<MeetShell> createState() => _MeetShellState();
}

class _MeetShellState extends State<MeetShell> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.store.restoreLive());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final invitation = Uri.base.queryParameters['invite'];
      if (invitation != null && mounted) {
        forgetInvitationInAddressBar();
        showJoinPlan(context, widget.store, invitation: invitation);
      }
      if (widget.store.loadNotice != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(widget.store.loadNotice!)));
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      return LayoutBuilder(
        builder: (context, box) {
          final desktop = box.maxWidth >= 760;
          // System Back leaves a plan, then returns to Discover, before exiting.
          return PopScope(
            canPop: store.room == null && store.tab == 'discover',
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                store.navigate(store.room != null ? 'plans' : 'discover');
              }
            },
            child: Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    if (desktop) _sidebar(),
                    Expanded(
                      child: Column(
                        children: [
                          _header(desktop),
                          if (store.busy)
                            const SizedBox(
                              height: 2,
                              child: LinearProgressIndicator(
                                color: MH.accent,
                                backgroundColor: MH.accentSoft,
                              ),
                            )
                          else
                            const SizedBox(height: 2),
                          Expanded(
                            child: store.room != null
                                ? RoomScreen(
                                    key: ValueKey(store.room!.id),
                                    store: store,
                                  )
                                : switch (store.tab) {
                                    'plans' => PlansScreen(store: store),
                                    'preferences' => PreferencesScreen(
                                      store: store,
                                    ),
                                    'privacy' => PrivacyScreen(store: store),
                                    _ => DiscoverScreen(store: store),
                                  },
                          ),
                          if (!desktop)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 6, 15, 9),
                              child: _bottomBar(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  Widget _header(bool desktop) => Container(
    height: 62,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: MH.border.withValues(alpha: .4)),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: !desktop
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => widget.store.navigate('discover'),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Brand(),
                    ),
                  ),
                )
              : Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 14,
                      color: MH.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.store.room?.title ??
                            destinations
                                .firstWhere((d) => d.$1 == widget.store.tab)
                                .$2,
                        style: const TextStyle(fontSize: 11, color: MH.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(width: 12),
        GlassSurface(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 13, color: MH.muted),
              SizedBox(width: 5),
              Text(
                'Toronto',
                style: TextStyle(fontSize: 10, color: MH.secondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _sidebar() => Container(
    width: 224,
    padding: const EdgeInsets.fromLTRB(18, 25, 18, 23),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [MH.accentSoft, MH.canvas],
      ),
      border: Border(right: BorderSide(color: MH.border.withValues(alpha: .5))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(6, 3, 0, 35),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Brand(large: true),
          ),
        ),
        for (final (id, label, icon) in destinations)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.store.navigate(id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: widget.store.tab == id
                        ? MH.accentSoft.withValues(alpha: .8)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: widget.store.tab == id
                            ? MH.accent
                            : MH.secondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: widget.store.tab == id
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: widget.store.tab == id ? MH.ink : MH.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MH.accentSoft.withValues(alpha: .65),
          ),
          child: const Icon(
            Icons.favorite_border_rounded,
            size: 15,
            color: MH.accent,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your people. Your pace.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MH.secondary,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'A little less planning.\nA little more being together.',
          style: TextStyle(fontSize: 10, color: MH.muted, height: 1.8),
        ),
      ],
    ),
  );
  Widget _bottomBar() => GlassSurface(
    radius: 25,
    blur: true,
    padding: const EdgeInsets.all(5),
    child: Row(
      children: [
        for (final (id, label, icon) in destinations)
          Expanded(
            child: Semantics(
              selected: widget.store.tab == id,
              button: true,
              label: label,
              child: InkWell(
                key: Key('nav-$id'),
                onTap: () => widget.store.navigate(id),
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  height:
                      48 +
                      (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(
                            0,
                            2,
                          ) *
                          32,
                  decoration: BoxDecoration(
                    color: widget.store.tab == id
                        ? MH.accentSoft.withValues(alpha: .7)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: widget.store.tab == id
                            ? MH.accent
                            : MH.secondary,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: widget.store.tab == id ? MH.ink : MH.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
