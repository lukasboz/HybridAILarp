import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'actions.dart';
import 'design.dart';
import 'domain.dart';
import 'orbit.dart';
import 'store.dart';

class PlanDialog extends StatelessWidget {
  const PlanDialog({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: MH.canvas,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
      side: const BorderSide(color: MH.border),
    ),
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: math.max(220, MediaQuery.sizeOf(context).height - 72),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.8,
                      height: 1.25,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: MH.secondary,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: MH.secondary,
                  height: 1.7,
                ),
              ),
            ],
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    ),
  );
}

Future<void> showCreatePlan(
  BuildContext context,
  MeetStore store, [
  String seed = '',
]) => showDialog<void>(
  context: context,
  builder: (_) => CreatePlanDialog(store: store, seed: seed),
);

class CreatePlanDialog extends StatefulWidget {
  const CreatePlanDialog({super.key, required this.store, this.seed = ''});
  final MeetStore store;
  final String seed;
  @override
  State<CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends State<CreatePlanDialog> {
  late final title = TextEditingController(text: widget.seed);
  late final name = TextEditingController(
    text: widget.store.name == 'You' ? '' : widget.store.name,
  );
  String date = nextSaturday();
  bool live = false, working = false;
  @override
  void dispose() {
    title.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => working = true);
    final success = await perform(
      context,
      widget.store,
      () => widget.store.create(title.text, date, name.text, live: live),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => PlanDialog(
    title: 'Make a little time.',
    subtitle: 'Start with your people. We’ll find the common ground.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sharedTextField(
          key: const Key('plan-title'),
          controller: title,
          maxLength: 70,
          decoration: const InputDecoration(
            labelText: 'What’s the plan?',
            hintText: 'A catch-up, a game night, something new…',
          ),
        ),
        const SizedBox(height: 12),
        sharedTextField(
          key: const Key('your-name'),
          controller: name,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Your first name'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: working
              ? null
              : () async {
                  final chosen = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(date),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (chosen != null && mounted) {
                    setState(() => date = isoDate(chosen));
                  }
                },
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text(readableDate(date)),
        ),
        const SizedBox(height: 16),
        GlassSurface(
          radius: 14,
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 5,
            ),
            title: const Text(
              'Invite people on other devices',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              live
                  ? 'A live plan shared through an invitation link.'
                  : 'Off: this plan stays on this device.',
              style: const TextStyle(fontSize: 11, color: MH.secondary),
            ),
            value: live,
            onChanged: working ? null : (v) => setState(() => live = v),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          key: const Key('create-plan'),
          onPressed: working ? null : submit,
          icon: working
              ? const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_rounded, size: 17),
          label: const Text('Bring the plan together'),
        ),
      ],
    ),
  );
}

Future<void> showJoinPlan(
  BuildContext context,
  MeetStore store, {
  String invitation = '',
}) => showDialog<void>(
  context: context,
  builder: (_) => JoinPlanDialog(store: store, invitation: invitation),
);

class JoinPlanDialog extends StatefulWidget {
  const JoinPlanDialog({super.key, required this.store, this.invitation = ''});
  final MeetStore store;
  final String invitation;
  @override
  State<JoinPlanDialog> createState() => _JoinPlanDialogState();
}

class _JoinPlanDialogState extends State<JoinPlanDialog> {
  late final invite = TextEditingController(text: widget.invitation);
  late final name = TextEditingController(
    text: widget.store.name == 'You' ? '' : widget.store.name,
  );
  bool working = false;
  @override
  void dispose() {
    invite.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlanDialog(
    title: 'There’s room for you.',
    subtitle: 'Paste the invitation your friend shared.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sharedTextField(
          controller: invite,
          maxLength: 1500,
          decoration: const InputDecoration(
            labelText: 'Invitation link or code',
          ),
        ),
        const SizedBox(height: 14),
        sharedTextField(
          controller: name,
          maxLength: 30,
          decoration: const InputDecoration(labelText: 'Your first name'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: working
              ? null
              : () async {
                  setState(() => working = true);
                  final success = await perform(
                    context,
                    widget.store,
                    () => widget.store.join(invite.text, name.text),
                  );
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                  } else {
                    setState(() => working = false);
                  }
                },
          child: Text(working ? 'Joining…' : 'Join the plan'),
        ),
      ],
    ),
  );
}

Future<void> showPreferences(BuildContext context, MeetStore store) =>
    showDialog<void>(
      context: context,
      builder: (_) => PlanDialog(
        title: 'A plan that feels like you.',
        subtitle: 'Your limits matter. Share only what helps the group decide.',
        child: PreferencesEditor(
          store: store,
          onSaved: () => Navigator.pop(context),
        ),
      ),
    );

class PreferencesEditor extends StatefulWidget {
  const PreferencesEditor({super.key, required this.store, this.onSaved});
  final MeetStore store;
  final VoidCallback? onSaved;
  @override
  State<PreferencesEditor> createState() => _PreferencesEditorState();
}

class _PreferencesEditorState extends State<PreferencesEditor> {
  late PreferenceCard card = widget.store.me?.card ?? widget.store.defaultCard!;
  final note = TextEditingController();
  bool working = false;
  @override
  void dispose() {
    note.clear();
    note.dispose();
    super.dispose();
  }

  void change(PreferenceCard value) => setState(() => card = value);
  Future<void> draft() async {
    if (note.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a note first, or use the controls below.'),
        ),
      );
      return;
    }
    if (!await cloudConsent(context, note: true) || !mounted) return;
    setState(() => working = true);
    await perform(context, widget.store, () async {
      final result = await widget.store.extract(note.text, card);
      if (mounted) {
        setState(() {
          card = result;
          note.clear();
        });
      }
    }, message: 'Your draft is ready. Review it before sharing.');
    if (mounted) setState(() => working = false);
  }

  Future<void> review() async {
    try {
      card.validate(widget.store.data);
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      return;
    }
    note.clear();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => PlanDialog(
        title: 'Your card, your call.',
        subtitle: widget.store.room == null
            ? 'Save these as your preferences for future plans.'
            : 'Only the preferences below will be shared with this group. Your note is excluded.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cardSummary(card, widget.store),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('approve-card'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                widget.store.room == null
                    ? 'Save my preferences'
                    : 'Share this card',
              ),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !mounted) return;
    final success = await perform(
      context,
      widget.store,
      () => widget.store.shareCard(card),
      message: 'Your preferences are saved.',
    );
    if (success) widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GlassSurface(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 16, color: MH.accent),
                SizedBox(width: 8),
                Text(
                  'Start in your own words',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            sharedTextField(
              key: const Key('preference-note'),
              controller: note,
              minLines: 3,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Something creative and relaxed, under \$25. I’m coming from The Annex…',
                labelText: 'Optional note',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI uses the cloud only after you agree. Your note stays here until then.',
              style: TextStyle(fontSize: 11, color: MH.secondary, height: 1.6),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: working ? null : draft,
              icon: const Icon(Icons.auto_awesome_outlined, size: 15),
              label: Text(working ? 'Preparing your draft…' : 'Draft with AI'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 25),
      const Eyebrow('Or make it yours with the controls'),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: card.areaId,
        decoration: const InputDecoration(labelText: 'Starting neighbourhood'),
        items: widget.store.data.areas
            .map(
              (a) => DropdownMenuItem(
                value: a['id'] as String,
                child: Text(a['name'] as String),
              ),
            )
            .toList(),
        onChanged: (v) => change(card.copyWith(areaId: v)),
      ),
      const SizedBox(height: 18),
      _slider(
        'Spending limit',
        '\$${card.maxSpend} CAD',
        card.maxSpend.toDouble(),
        0,
        200,
        40,
        (v) => change(card.copyWith(maxSpend: v.round())),
      ),
      _slider(
        'Travel limit',
        '${card.maxTravel} minutes',
        card.maxTravel.toDouble(),
        5,
        120,
        23,
        (v) => change(card.copyWith(maxTravel: v.round())),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: card.mode,
        decoration: const InputDecoration(labelText: 'Getting there'),
        items: const [
          DropdownMenuItem(value: 'transit', child: Text('Public transit')),
          DropdownMenuItem(value: 'walk', child: Text('Walking')),
          DropdownMenuItem(value: 'bike', child: Text('Cycling')),
        ],
        onChanged: (v) => change(card.copyWith(mode: v)),
      ),
      const SizedBox(height: 22),
      const Text(
        'A little of what you love',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: widget.store.data.interests.map((interest) {
          final id = interest['id'] as String;
          return FilterChip(
            label: Text(interest['name'] as String),
            selected: card.interests.contains(id),
            onSelected: (selected) {
              final values = card.interests.toSet();
              selected ? values.add(id) : values.remove(id);
              change(card.copyWith(interests: values.toList()));
            },
          );
        }).toList(),
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: _timeDropdown(
              'From',
              card.earliest,
              (v) => change(card.copyWith(earliest: v)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _timeDropdown(
              'Until',
              card.latest,
              (v) => change(card.copyWith(latest: v)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Allow at least 90 minutes together.',
        style: TextStyle(fontSize: 11, color: MH.secondary),
      ),
      const SizedBox(height: 14),
      _toggle(
        'A quiet setting',
        card.quiet,
        (v) => change(card.copyWith(quiet: v)),
      ),
      _toggle(
        'Keep it indoors',
        card.indoors,
        (v) => change(card.copyWith(indoors: v)),
      ),
      _toggle(
        'Confirmed step-free access',
        card.stepFree,
        (v) => change(card.copyWith(stepFree: v)),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        key: const Key('review-card'),
        onPressed: working ? null : review,
        icon: const Icon(Icons.verified_user_outlined, size: 16),
        label: const Text('Review my preferences'),
      ),
    ],
  );
  Widget _slider(
    String label,
    String value,
    double current,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) => Column(
    children: [
      Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: MH.accent,
            ),
          ),
        ],
      ),
      Slider(
        value: current,
        min: min,
        max: max,
        divisions: divisions,
        label: value,
        onChanged: onChanged,
      ),
    ],
  );
  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      );
  Widget _timeDropdown(
    String label,
    int selected,
    ValueChanged<int> onChanged,
  ) => DropdownButtonFormField<int>(
    key: ValueKey('$label-$selected'),
    initialValue: selected,
    decoration: InputDecoration(labelText: label),
    items: List.generate(37, (i) => 360 + i * 30)
        .map(
          (minute) => DropdownMenuItem(
            value: minute,
            child: Text(
              timeLabel(minute),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        )
        .toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

Future<void> showIdea(
  BuildContext context,
  MeetStore store,
  Activity idea, {
  RankedPlan? rank,
}) => showDialog<void>(
  context: context,
  builder: (context) => PlanDialog(
    title: idea.name,
    subtitle: '${idea.venue} · ${idea.area}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(height: 200, child: ActivityPhoto(idea)),
        ),
        const SizedBox(height: 18),
        Text(
          idea.description,
          style: const TextStyle(fontSize: 13, height: 1.7),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _detail(
              Icons.payments_outlined,
              idea.cost == 0 ? 'Free' : '~\$${idea.cost} / person',
            ),
            _detail(
              Icons.schedule_outlined,
              rank == null ? '90 minutes' : timeLabel(rank.start!),
            ),
            if (rank != null)
              _detail(
                Icons.directions_transit_outlined,
                '~${rank.maxTravel} min max',
              ),
          ],
        ),
        if (rank != null) ...[
          const SizedBox(height: 24),
          const Eyebrow('A fit for each person'),
          const SizedBox(height: 10),
          for (final fit in rank.fits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      store.room!.members
                          .firstWhere((p) => p.id == fit.memberId)
                          .name,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    '${fit.score}/100 · ~${fit.travel} min',
                    style: const TextStyle(fontSize: 12, color: MH.secondary),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 20),
        Text(
          idea.source == 'host'
              ? 'Activity details are host-provided. Travel is approximate. Verify current prices, hours and access before going.'
              : 'Toronto sample idea. Prices, hours, access and travel are fixtures. The photo illustrates the category.',
          style: const TextStyle(
            fontSize: 11,
            color: MH.secondary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 18),
        if (idea.url.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(idea.url),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
            label: const Text('Visit venue website'),
          ),
        const SizedBox(height: 10),
        if (rank != null && store.isHost)
          FilledButton(
            key: const Key('propose-plan'),
            onPressed: store.room!.members.length < 2
                ? null
                : () async {
                    final success = await perform(
                      context,
                      store,
                      () => store.propose(rank),
                    );
                    if (success && context.mounted) Navigator.pop(context);
                  },
            child: const Text('Put this to the group'),
          ),
        if (rank == null)
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              showCreatePlan(context, store, idea.name);
            },
            child: const Text('Make it a plan'),
          ),
      ],
    ),
  ),
);
Widget _detail(IconData icon, String text) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(icon, size: 15, color: MH.secondary),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(fontSize: 11, color: MH.secondary)),
  ],
);

Future<void> showAddOption(BuildContext context, MeetStore store) =>
    showDialog<void>(
      context: context,
      builder: (_) => AddOptionDialog(store: store),
    );

class AddOptionDialog extends StatefulWidget {
  const AddOptionDialog({super.key, required this.store});
  final MeetStore store;
  @override
  State<AddOptionDialog> createState() => _AddOptionDialogState();
}

class _AddOptionDialogState extends State<AddOptionDialog> {
  final name = TextEditingController(),
      venue = TextEditingController(),
      description = TextEditingController(),
      url = TextEditingController(),
      cost = TextEditingController(text: '0');
  String area = 'downtown', interest = 'art';
  int opens = 960, closes = 1320, noise = 2;
  bool indoor = true, stepFree = false, working = false;
  @override
  void dispose() {
    for (final c in [name, venue, description, url, cost]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlanDialog(
    title: 'Bring an idea to the table.',
    subtitle: 'Add an activity your group could actually do.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sharedTextField(
          controller: name,
          maxLength: 70,
          decoration: const InputDecoration(labelText: 'Activity name'),
        ),
        const SizedBox(height: 10),
        sharedTextField(
          controller: venue,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Venue or meeting place',
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: area,
          decoration: const InputDecoration(labelText: 'Neighbourhood'),
          items: widget.store.data.areas
              .map(
                (a) => DropdownMenuItem(
                  value: a['id'] as String,
                  child: Text(a['name'] as String),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => area = v!),
        ),
        const SizedBox(height: 16),
        sharedTextField(
          controller: cost,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Estimated cost per person',
            prefixText: '\$ ',
            suffixText: 'CAD',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: interest,
          decoration: const InputDecoration(labelText: 'Main interest'),
          items: widget.store.data.interests
              .map(
                (i) => DropdownMenuItem(
                  value: i['id'] as String,
                  child: Text(i['name'] as String),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => interest = v!),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _time('Opens', opens, (v) => setState(() => opens = v)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _time('Closes', closes, (v) => setState(() => closes = v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: noise,
          decoration: const InputDecoration(labelText: 'Noise level'),
          items: const [
            DropdownMenuItem(value: 1, child: Text('Quiet')),
            DropdownMenuItem(value: 2, child: Text('Conversational')),
            DropdownMenuItem(value: 3, child: Text('Lively')),
          ],
          onChanged: (v) => setState(() => noise = v!),
        ),
        const SizedBox(height: 16),
        sharedTextField(
          controller: description,
          maxLength: 300,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'What will you do?'),
        ),
        const SizedBox(height: 10),
        sharedTextField(
          controller: url,
          maxLength: 1000,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Source link (optional)',
            hintText: 'https://…',
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Indoor activity', style: TextStyle(fontSize: 12)),
          value: indoor,
          onChanged: (v) => setState(() => indoor = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'I confirmed step-free access',
            style: TextStyle(fontSize: 12),
          ),
          value: stepFree,
          onChanged: (v) => setState(() => stepFree = v),
        ),
        const SizedBox(height: 10),
        const Text(
          'The first activity you add replaces this plan’s sample catalogue. New ideas reopen the group decision.',
          style: TextStyle(fontSize: 11, color: MH.secondary, height: 1.6),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: working
              ? null
              : () async {
                  setState(() => working = true);
                  final success = await perform(
                    context,
                    widget.store,
                    () => widget.store.addOption({
                      'name': name.text.trim(),
                      'venue': venue.text.trim(),
                      'description': description.text.trim(),
                      'url': url.text.trim(),
                      'cost': int.tryParse(cost.text) ?? -1,
                      'areaId': area,
                      'tags': [interest],
                      'noise': noise,
                      'indoor': indoor,
                      'stepFree': stepFree ? true : null,
                      'opens': opens,
                      'closes': closes,
                    }),
                  );
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                  } else {
                    setState(() => working = false);
                  }
                },
          child: Text(working ? 'Adding…' : 'Add this activity'),
        ),
      ],
    ),
  );
  Widget _time(String label, int value, ValueChanged<int> onChanged) =>
      DropdownButtonFormField<int>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: List.generate(37, (i) => 360 + i * 30)
            .map(
              (t) => DropdownMenuItem(
                value: t,
                child: Text(timeLabel(t), style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
        onChanged: (v) => onChanged(v!),
      );
}
