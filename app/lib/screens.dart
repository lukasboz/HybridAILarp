import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import 'actions.dart';
import 'design.dart';
import 'dialogs.dart';
import 'domain.dart';
import 'orbit.dart';
import 'store.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, required this.store});
  final MeetStore store;
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final composer = TextEditingController();
  @override
  void dispose() {
    composer.dispose();
    super.dispose();
  }

  void start() {
    showCreatePlan(context, widget.store, composer.text.trim());
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 600;
      final minHeight =
          560.0 +
          (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2) * 220;
      final height = box.maxHeight < minHeight ? minHeight : box.maxHeight;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Center(
            child: SizedBox(
              width: 800,
              height: height,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 18 : 32,
                  compact ? 15 : 22,
                  compact ? 18 : 32,
                  compact ? 15 : 22,
                ),
                child: Column(
                  children: [
                    const Eyebrow('You, them & a little common ground'),
                    const SizedBox(height: 12),
                    Text(
                      'Make time for your people.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 23 : 28,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1.1,
                        color: MH.ink,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Different tastes. Different budgets. One good plan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: MH.muted),
                    ),
                    Expanded(
                      child: ActivityOrbit(
                        people: widget.store.data.samplePeople,
                        activities: widget.store.data.catalog,
                        home: true,
                        onActivity: (idea) =>
                            showIdea(context, widget.store, idea),
                        onPerson: (p) => widget.store.openSample(p.id),
                        onCentre: () => widget.store.openSample(),
                      ),
                    ),
                    const Text(
                      'A world of possibilities. One plan together.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: MH.muted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          key: const Key('explore-sample'),
                          onPressed: () => widget.store.openSample(),
                          icon: const Icon(
                            Icons.people_outline_rounded,
                            size: 15,
                          ),
                          label: const Text('Explore a sample group'),
                        ),
                        TextButton.icon(
                          onPressed: () => showJoinPlan(context, widget.store),
                          icon: const Icon(Icons.link_rounded, size: 15),
                          label: const Text('Join a plan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: GlassSurface(
                        radius: 27,
                        blur: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Create a plan',
                              onPressed: start,
                              icon: const Icon(
                                Icons.add_rounded,
                                color: MH.muted,
                                size: 19,
                              ),
                            ),
                            Expanded(
                              child: sharedTextField(
                                key: const Key('plan-composer'),
                                controller: composer,
                                maxLength: 70,
                                onSubmitted: (_) => start(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: MH.secondary,
                                ),
                                decoration: InputDecoration(
                                  hintText: compact ? 'What’s the plan?' : 'What’s the plan? A catch-up, a game night…',
                                  counterText: '',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                    horizontal: 2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 39,
                              height: 39,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                onPressed: start,
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Toronto sample ideas · Illustrative photos',
                      style: TextStyle(fontSize: 9, color: MH.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key, required this.store});
  final MeetStore store;
  @override
  Widget build(BuildContext context) => PageBody(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          'Your plans, coming together.',
          subtitle: 'Pick up where your people left off.',
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => showCreatePlan(context, store),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New plan'),
            ),
            OutlinedButton.icon(
              onPressed: () => showJoinPlan(context, store),
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text('Join with a link'),
            ),
            TextButton.icon(
              onPressed: () => perform(context, store, store.refreshLive),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh live plans'),
            ),
          ],
        ),
        const SizedBox(height: 30),
        for (final room in [...store.liveRooms, ...store.localRooms])
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: InkWell(
              onTap: () => perform(context, store, () => store.openRoom(room)),
              borderRadius: BorderRadius.circular(20),
              child: GlassSurface(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Eyebrow(
                            room.status == 'confirmed'
                                ? 'All set'
                                : 'Finding your halfway',
                          ),
                        ),
                        Text(
                          room.local
                              ? (room.id == 'sample-toronto'
                                    ? 'Sample group'
                                    : 'On this device')
                              : 'Live plan',
                          style: const TextStyle(
                            fontSize: 10,
                            color: MH.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${readableDate(room.date)} · Toronto',
                      style: const TextStyle(fontSize: 12, color: MH.secondary),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 16,
                          color: MH.secondary,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          room.members.isEmpty
                              ? 'Your group'
                              : '${room.members.length} people',
                          style: const TextStyle(
                            fontSize: 11,
                            color: MH.secondary,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Open plan',
                          style: TextStyle(fontSize: 11, color: MH.ink),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: MH.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key, required this.store});
  final MeetStore store;
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  bool rejected = false;
  Future<void> shareInvite() async {
    final store = widget.store, room = store.room!;
    if (room.local) return;
    String? url;
    final ready = await perform(
      context,
      store,
      () async => url = await store.invitationLink(),
    );
    if (!ready || url == null || !mounted) return;
    // Clipboard always provides a fallback when a desktop/browser has no share target.
    await Clipboard.setData(ClipboardData(text: url!));
    if (!mounted) return;
    await perform(context, store, () async {
      await SharePlus.instance.share(
        ShareParams(
          title: room.title,
          text: 'Join ${room.title}\n$url',
          sharePositionOrigin: const Rect.fromLTWH(20, 80, 200, 50),
        ),
      );
    }, message: 'Invitation copied.');
  }

  Future<void> explain() async {
    if (!await cloudConsent(context, note: false) || !mounted) return;
    await perform(context, widget.store, widget.store.explain);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store,
        room = store.room!,
        ranked = store.ranked,
        selected = store.chosen;
    final activities = store.planner.catalogFor(room);
    final full = room.members.length >= store.cloud.maxGroupSize;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 1040;
        final diagram = GlassSurface(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  const Eyebrow('A little common ground'),
                  const Spacer(),
                  Text(
                    '${ranked.length} ${ranked.length == 1 ? 'idea' : 'ideas'} fit',
                    style: const TextStyle(fontSize: 10, color: MH.muted),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SizedBox(
                height: wide ? 460 : 360,
                child: ActivityOrbit(
                  people: room.members,
                  activities: activities,
                  ranked: ranked,
                  selected: selected?.candidate.id ?? '',
                  ready: room.allReady,
                  onActivity: (idea) {
                    if (ranked.any((p) => p.candidate.id == idea.id)) {
                      store.select(idea.id);
                    } else {
                      setState(() => rejected = true);
                    }
                  },
                  onPerson: (p) => store.switchPerson(p.id),
                ),
              ),
            ],
          ),
        );
        final shortlist = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selected != null)
              PlanCard(rank: selected, store: store, featured: true),
            if (selected == null)
              EmptyState(
                room.allReady
                    ? 'Let’s find a little more room.'
                    : 'Good plans take everyone.',
                room.allReady
                    ? 'No idea meets every limit. Decide together whether to change a preference.'
                    : 'Everyone needs to share a preference card before the shortlist appears.',
                action: OutlinedButton(
                  onPressed: () => showPreferences(context, store),
                  child: const Text('My preferences'),
                ),
              ),
            if (selected != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: store.busy ? null : explain,
                icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                label: const Text('Explain this shortlist'),
              ),
              const SizedBox(height: 12),
              const Text(
                'The lowest individual fit comes first. Every shared limit counts.',
                style: TextStyle(fontSize: 10, color: MH.muted, height: 1.6),
              ),
            ],
          ],
        );
        return PageBody(
          maxWidth: 1320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => store.navigate('plans'),
                icon: const Icon(Icons.arrow_back_rounded, size: 15),
                label: const Text('My plans'),
              ),
              const SizedBox(height: 10),
              SectionTitle(
                room.title,
                subtitle:
                    '${readableDate(room.date)} · ${room.members.length} people · Toronto',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('edit-preferences'),
                    onPressed: () => showPreferences(context, store),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('My preferences'),
                  ),
                  if (store.isHost)
                    OutlinedButton.icon(
                      onPressed: () => showAddOption(context, store),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add an idea'),
                    ),
                  if (!room.local)
                    FilledButton.icon(
                      onPressed: full ? null : shareInvite,
                      icon: const Icon(Icons.link_rounded, size: 16),
                      label: Text(full ? 'This plan is full' : 'Invite people'),
                    ),
                  if (room.local)
                    TextButton.icon(
                      onPressed: () =>
                          perform(context, store, store.addSamplePerson),
                      icon: const Icon(Icons.person_add_alt_rounded, size: 16),
                      label: const Text('Add sample person'),
                    ),
                ],
              ),
              if (room.local) ...[
                const SizedBox(height: 20),
                GlassSurface(
                  radius: 12,
                  color: MH.accentSoft.withValues(alpha: .35),
                  padding: const EdgeInsets.all(13),
                  child: const Text(
                    'ON THIS DEVICE · Switch between sample people to try each perspective. Live plans connect real devices.',
                    style: TextStyle(
                      fontSize: 10,
                      color: MH.secondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
              if (store.streamError != null) ...[
                const SizedBox(height: 16),
                Text(
                  store.streamError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (i, person) in room.members.indexed)
                      Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: InkWell(
                          key: Key('person-${person.id}'),
                          onTap: room.local
                              ? () => store.switchPerson(person.id)
                              : null,
                          borderRadius: BorderRadius.circular(13),
                          child: GlassSurface(
                            radius: 13,
                            color: person.id == store.myId
                                ? MH.accentSoft.withValues(alpha: .65)
                                : Colors.white,
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                PersonAvatar(person, index: i, size: 31),
                                const SizedBox(width: 9),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${person.name}${person.id == store.myId ? ' · you' : ''}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      person.card == null
                                          ? 'Adding preferences'
                                          : 'Preferences shared',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: MH.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (room.proposal != null) ...[
                const SizedBox(height: 22),
                VotingPanel(store: store),
              ] else if (store.reopenedNotice != null) ...[
                const SizedBox(height: 22),
                Semantics(
                  liveRegion: true,
                  child: GlassSurface(
                    radius: 12,
                    color: MH.accentSoft.withValues(alpha: .35),
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: MH.accent,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            store.reopenedNotice!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: MH.secondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('Common ground (${ranked.length})'),
                    selected: !rejected,
                    onSelected: (_) => setState(() => rejected = false),
                  ),
                  ChoiceChip(
                    label: const Text('Outside our limits'),
                    selected: rejected,
                    onSelected: (_) => setState(() => rejected = true),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (rejected) ...[
                for (final idea in activities)
                  if (!store.planner.evaluate(idea, room.members).eligible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassSurface(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              idea.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final reason
                                in store.planner
                                    .evaluate(idea, room.members)
                                    .reasons)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  reason,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: MH.secondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
              ] else ...[
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: diagram),
                      const SizedBox(width: 24),
                      SizedBox(width: 340, child: shortlist),
                    ],
                  )
                else ...[
                  diagram,
                  const SizedBox(height: 20),
                  shortlist,
                ],
                const SizedBox(height: 24),
                for (final rank
                    in ranked
                        .take(3)
                        .where((r) => r.candidate.id != selected?.candidate.id))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PlanCard(rank: rank, store: store),
                  ),
              ],
              const SizedBox(height: 12),
              Text(
                room.options.isEmpty
                    ? 'Toronto sample catalogue · Prices, hours, access and travel are fixtures. Photos are illustrative.'
                    : 'Activities and access are host-provided. Travel is estimated from neighbourhood centres.',
                style: const TextStyle(
                  fontSize: 10,
                  color: MH.muted,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.rank,
    required this.store,
    this.featured = false,
  });
  final RankedPlan rank;
  final MeetStore store;
  final bool featured;
  @override
  Widget build(BuildContext context) {
    final explanation = store.explanationRevision == store.room?.revision
        ? store.explanations.where((e) => e.id == rank.candidate.id).firstOrNull
        : null;
    return GlassSurface(
      color: Colors.white,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: featured ? 155 : 135,
              child: ActivityPhoto(rank.candidate),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Eyebrow('Common ground')),
              Text(
                '${rank.minFit}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: MH.accent,
                ),
              ),
              const Text(
                '/100',
                style: TextStyle(fontSize: 10, color: MH.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rank.candidate.name,
            style: TextStyle(
              fontSize: featured ? 22 : 20,
              fontWeight: FontWeight.w500,
              height: 1.25,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '${rank.candidate.venue} · ${rank.candidate.area}',
            style: const TextStyle(
              fontSize: 11,
              color: MH.secondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 13,
            runSpacing: 8,
            children: [
              _metric(
                Icons.payments_outlined,
                rank.candidate.cost == 0 ? 'Free' : '~\$${rank.candidate.cost}',
              ),
              _metric(Icons.schedule_rounded, timeLabel(rank.start!)),
              _metric(
                Icons.directions_transit_outlined,
                '~${rank.maxTravel} min max',
              ),
            ],
          ),
          if (explanation != null) ...[
            const SizedBox(height: 18),
            Text(
              explanation.reason,
              style: const TextStyle(fontSize: 12, height: 1.7),
            ),
            const SizedBox(height: 8),
            Text(
              'The tradeoff: ${explanation.tradeoff}',
              style: const TextStyle(
                fontSize: 11,
                color: MH.secondary,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 13),
          const Divider(),
          Row(
            children: [
              const Icon(Icons.check_rounded, size: 14, color: MH.accent),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'Within everyone’s limits',
                  style: TextStyle(fontSize: 10, color: MH.secondary),
                ),
              ),
              TextButton(
                key: Key('details-${rank.candidate.id}'),
                onPressed: () =>
                    showIdea(context, store, rank.candidate, rank: rank),
                child: const Text('View plan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: MH.secondary),
      const SizedBox(width: 5),
      Text(value, style: const TextStyle(fontSize: 10, color: MH.secondary)),
    ],
  );
}

class VotingPanel extends StatelessWidget {
  const VotingPanel({super.key, required this.store});
  final MeetStore store;
  Future<void> calendar(BuildContext context) async {
    final room = store.room!,
        idea = store.planner
            .catalogFor(room)
            .firstWhere((a) => a.id == room.proposal!.candidateId);
    await perform(context, store, () async {
      await SharePlus.instance.share(
        ShareParams(
          title: room.title,
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(calendarFile(room, idea))),
              mimeType: 'text/calendar',
            ),
          ],
          fileNameOverrides: ['meethalfway-plan.ics'],
          sharePositionOrigin: const Rect.fromLTWH(20, 80, 200, 50),
        ),
      );
    });
  }

  Future<void> sharePlan(BuildContext context, Activity idea) async {
    final room = store.room!;
    final text = [
      '${room.title}: ${idea.name}',
      '${readableDate(room.date)} · ${timeLabel(room.proposal!.startMinute)} Toronto time',
      '${idea.venue}, ${idea.area}',
      idea.cost == 0 ? 'Free' : 'About \$${idea.cost} per person',
      'Check current hours and booking before you go.',
    ].join('\n');
    // Clipboard always provides a fallback when a desktop/browser has no share target.
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    await perform(context, store, () async {
      await SharePlus.instance.share(
        ShareParams(
          title: room.title,
          text: text,
          sharePositionOrigin: const Rect.fromLTWH(20, 80, 200, 50),
        ),
      );
    }, message: 'Plan details copied.');
  }

  @override
  Widget build(BuildContext context) {
    final room = store.room!,
        proposal = room.proposal!,
        idea = store.planner
            .catalogFor(room)
            .where((a) => a.id == proposal.candidateId)
            .firstOrNull;
    if (idea == null) return const SizedBox.shrink();
    return GlassSurface(
      color: MH.accentSoft.withValues(alpha: .55),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(
            room.status == 'confirmed' ? 'It’s a plan' : 'A plan on the table',
          ),
          const SizedBox(height: 12),
          Text(
            idea.name,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w500,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${readableDate(room.date)} · ${timeLabel(proposal.startMinute)} Toronto time\n'
            '${idea.venue} · ${idea.cost == 0 ? 'Free' : '~\$${idea.cost} per person'}',
            style: const TextStyle(
              fontSize: 12,
              color: MH.secondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          if (room.status == 'confirmed') ...[
            const Text(
              'Everyone agreed, but nothing is booked yet. Check current hours and prices, and reserve ahead if the venue needs it.',
              style: TextStyle(fontSize: 11, color: MH.secondary, height: 1.6),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => calendar(context),
                  icon: const Icon(Icons.event_available_rounded, size: 17),
                  label: const Text('Add to calendar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => sharePlan(context, idea),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Share the plan'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'How did it feel?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => perform(
                    context,
                    store,
                    () => store.feedback(idea, true),
                    message: 'Saved to your preferences for next time.',
                  ),
                  child: const Text('More like this'),
                ),
                TextButton(
                  onPressed: () => perform(
                    context,
                    store,
                    () => store.feedback(idea, false),
                    message: 'We’ll keep that in mind for next time.',
                  ),
                  child: const Text('Something different'),
                ),
              ],
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (choice, label) in [
                  ('yes', 'I’m in'),
                  ('maybe', 'Discuss'),
                  ('no', 'Change it'),
                ])
                  OutlinedButton(
                    key: Key('vote-$choice'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          room.votes[store.myId]?.revision ==
                                  proposal.revision &&
                              room.votes[store.myId]?.choice == choice
                          ? MH.accentSoft
                          : Colors.white,
                    ),
                    onPressed: store.busy
                        ? null
                        : () =>
                              perform(context, store, () => store.vote(choice)),
                    child: Text(label),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                for (final person in room.members)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        room.votes[person.id]?.revision == proposal.revision &&
                                room.votes[person.id]?.choice == 'yes'
                            ? Icons.check_circle_outline_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: MH.accent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${person.name} · ${room.votes[person.id]?.revision == proposal.revision ? {'yes': 'In', 'maybe': 'Discuss', 'no': 'Change it'}[room.votes[person.id]?.choice] ?? 'Waiting' : 'Waiting'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: MH.secondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (store.isHost) ...[
              const SizedBox(height: 18),
              FilledButton(
                key: const Key('confirm-plan'),
                onPressed: room.canConfirm && !store.busy
                    ? () => perform(context, store, store.confirm)
                    : null,
                child: const Text('Everyone’s in. Make it happen.'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key, required this.store});
  final MeetStore store;
  @override
  Widget build(BuildContext context) => PageBody(
    maxWidth: 740,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          'A plan that feels like you.',
          subtitle: 'Your preferences, ready for the next good thing.',
        ),
        const SizedBox(height: 26),
        PreferencesEditor(store: store),
      ],
    ),
  );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, required this.store});
  final MeetStore store;
  @override
  Widget build(BuildContext context) => PageBody(
    maxWidth: 900,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          'Bring yourself.\nChoose what you share.',
          subtitle: 'Good plans start with clear boundaries.',
        ),
        const SizedBox(height: 28),
        for (final (icon, title, body) in [
          (
            Icons.edit_note_rounded,
            'Your words, your choice.',
            'Write a note or use manual controls. Your note is sent to cloud AI only after you explicitly agree. MeetHalfway keeps raw notes out of saved plans and preference history.',
          ),
          (
            Icons.verified_user_outlined,
            'Your card, your call.',
            'Review your neighbourhood, spending limit, travel limit, availability, interests and access requirements before sharing them with the group.',
          ),
          (
            Icons.people_outline_rounded,
            'Everyone’s limits count.',
            'Hard limits filter activities before ranking. Every current participant must accept the same proposal before it can be confirmed.',
          ),
          (
            Icons.location_on_outlined,
            'A neighbourhood is enough.',
            'Travel uses neighbourhood centres. We don’t need a street address or live location. Sample photos, prices and schedules are illustrative.',
          ),
          (
            Icons.cloud_outlined,
            'Cloud explanations are optional.',
            'With your approval, shared cards and eligible ideas go to Google’s cloud AI through Firebase. AI can explain the shortlist; it can’t override your limits. Invitation holders can join and see the shared plan.',
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: GlassSurface(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: MH.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MH.secondary,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 15),
        const Text(
          'AI in this session',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        if (store.receipts.isEmpty)
          const Text(
            'No AI requests yet.',
            style: TextStyle(fontSize: 12, color: MH.secondary),
          ),
        for (final receipt in store.receipts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${receipt.action} · Cloud · ${receipt.model} · ${receipt.milliseconds} ms',
              style: const TextStyle(fontSize: 11, color: MH.secondary),
            ),
          ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () async {
            final clear = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Clear plans on this device?'),
                content: const Text(
                  'This removes local plans and saved preferences, and restores the sample group. Shared live plans are not deleted.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep my plans'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear local data'),
                  ),
                ],
              ),
            );
            if (clear == true && context.mounted) {
              await perform(context, store, store.resetLocal);
            }
          },
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: const Text('Clear local planning data'),
        ),
      ],
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 1080});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 600 ? 20 : 36,
            26,
            MediaQuery.sizeOf(context).width < 600 ? 20 : 36,
            40,
          ),
          child: child,
        ),
      ),
    ),
  );
}
