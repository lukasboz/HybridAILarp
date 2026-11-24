import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import 'actions.dart';
import 'design.dart';
import 'dialogs.dart';
import 'domain.dart';
import 'feature_screens.dart' show confirmAction;
import 'firebase_accounts.dart';
import 'screens.dart' show PageBody;
import 'social_service.dart';
import 'store.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key, required this.store});
  final MeetStore store;
  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late final link = TextEditingController(
    text: widget.store.pendingFriendLink ?? '',
  );
  @override
  void dispose() {
    link.dispose();
    super.dispose();
  }

  Future<void> share() async {
    final store = widget.store;
    await perform(context, store, () async {
      final value = await store.cloud.friendInvitation(store.name);
      await Clipboard.setData(ClipboardData(text: value));
      await SharePlus.instance.share(
        ShareParams(
          text: 'Add me on MeetHalfway: $value',
          sharePositionOrigin: const Rect.fromLTWH(20, 80, 200, 50),
        ),
      );
    }, message: 'Friendship link copied. It expires in seven days.');
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return PageBody(
      maxWidth: 850,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'Keep your people close.',
            subtitle:
                'Share a friendship link, then invite each other to plans.',
          ),
          const SizedBox(height: 22),
          if (!store.cloud.hasAccount) ...[
            const Text(
              'An account keeps your people available across devices. Your email and private preferences are never part of your friendship link.',
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => store.navigate('account'),
              child: const Text('Create an account or sign in'),
            ),
          ] else ...[
            GlassSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Your name is shared when someone accepts your link. Being friends does not reveal preference cards or grant access to any plan.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: store.busy ? null : share,
                    icon: const Icon(Icons.person_add_alt_rounded),
                    label: const Text('Share my friendship link'),
                  ),
                  const SizedBox(height: 18),
                  sharedTextField(
                    controller: link,
                    maxLength: 1500,
                    decoration: const InputDecoration(
                      labelText: 'A friend’s link or code',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: store.busy
                        ? null
                        : () async {
                            final ok = await perform(
                              context,
                              store,
                              () =>
                                  store.cloud.addFriend(link.text, store.name),
                              message: 'Added to your people.',
                            );
                            if (ok) {
                              store.pendingFriendLink = null;
                              link.clear();
                            }
                          },
                    child: const Text('Add this person'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (store.friends.isEmpty)
              const Text(
                'No people added yet. Share a link with someone you’d like to plan with.',
              ),
            for (final friendship in store.friends)
              Builder(
                builder: (context) {
                  final other = (friendship['members'] as List)
                      .cast<String>()
                      .firstWhere((id) => id != store.cloud.uid);
                  final name = (friendship['names'] as Map)[other] as String;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(name),
                    subtitle: const Text(
                      'Invite from a live plan to share approved preferences.',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove person',
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: store.busy
                          ? null
                          : () async {
                              if (!await confirmAction(
                                    context,
                                    'Remove $name from your people?',
                                    'Existing shared plans stay intact. You can reconnect with a new link.',
                                    'Remove',
                                  ) ||
                                  !context.mounted) {
                                return;
                              }
                              await perform(
                                context,
                                store,
                                () => store.cloud.db
                                    .doc('friendships/${friendship['id']}')
                                    .delete(),
                              );
                            },
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: store.busy
                  ? null
                  : () async {
                      if (!await confirmAction(
                            context,
                            'Revoke old friendship links?',
                            'Existing friendships stay. Nobody else can use the old links.',
                            'Revoke links',
                          ) ||
                          !context.mounted) {
                        return;
                      }
                      await perform(
                        context,
                        store,
                        store.cloud.revokeFriendLinks,
                        message: 'Old friendship links revoked.',
                      );
                    },
              child: const Text('Revoke my old friendship links'),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showInvitePeople(BuildContext context, MeetStore store) =>
    showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) => PlanDialog(
          title: 'Bring your people.',
          subtitle: 'An invitation lets this person join and see the plan’s approved cards.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!store.cloud.hasAccount || store.friends.isEmpty) ...[
                const Text(
                  'Add your people first, or use the plan’s shareable invitation link.',
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    store.navigate('people');
                  },
                  child: const Text('Open People'),
                ),
              ],
              for (final friendship in store.friends)
                Builder(
                  builder: (context) {
                    final other = (friendship['members'] as List)
                        .cast<String>()
                        .firstWhere((id) => id != store.cloud.uid);
                    return ListTile(
                      title: Text(
                        (friendship['names'] as Map)[other] as String,
                      ),
                      trailing: OutlinedButton(
                        onPressed: store.busy || store.room == null
                            ? null
                            : () => perform(
                                context,
                                store,
                                () => store.cloud.inviteFriendToPlan(
                                  store.room!,
                                  friendship,
                                ),
                                message: 'Invitation added to their Updates.',
                              ),
                        child: const Text('Invite'),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.store});
  final MeetStore store;
  Future<void> exportCalendar(BuildContext context, Json entry) =>
      perform(context, store, () async {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                Uint8List.fromList(utf8.encode(entry['calendar'] as String)),
                mimeType: 'text/calendar',
              ),
            ],
            fileNameOverrides: ['meethalfway-plan.ics'],
            sharePositionOrigin: const Rect.fromLTWH(20, 80, 200, 50),
          ),
        );
      }).then((_) {});
  @override
  Widget build(BuildContext context) {
    final entries = [...store.history]
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'Good times, remembered.',
            subtitle: 'Confirmed plans and your private ratings. Only you can read your history.',
          ),
          const SizedBox(height: 24),
          if (entries.isEmpty)
            const Text(
              'Confirm a plan to save it here. Your live confirmed plans are archived when they load.',
            ),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GlassSurface(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      entry['title'] as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${readableDate(entry['date'] as String)} · \$${entry['totalCost']} per person',
                    ),
                    Text(
                      (entry['activities'] as List).join(' → '),
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                    Text(
                      entry['cloud'] == true
                          ? 'Saved privately to your account'
                          : 'Saved on this device',
                      style: const TextStyle(fontSize: 11, color: MH.secondary),
                    ),
                    const SizedBox(height: 14),
                    if ((entry['date'] as String).compareTo(
                          isoDate(DateTime.now()),
                        ) <=
                        0) ...[
                      const Text('How was it?'),
                      Wrap(
                        children: [
                          for (var rating = 1; rating <= 5; rating++)
                            IconButton(
                              tooltip: '$rating stars',
                              onPressed: store.busy
                                  ? null
                                  : () => perform(
                                      context,
                                      store,
                                      () => store.rateHistory(
                                        entry,
                                        rating,
                                        entry['again'] == true,
                                      ),
                                    ),
                              icon: Icon(
                                (entry['rating'] as int? ?? 0) >= rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: MH.accent,
                              ),
                            ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('I’d do this again'),
                        value: entry['again'] == true,
                        onChanged: store.busy
                            ? null
                            : (value) => perform(
                                context,
                                store,
                                () => store.rateHistory(
                                  entry,
                                  entry['rating'] as int? ?? 0,
                                  value,
                                ),
                              ),
                      ),
                    ] else
                      const Text(
                        'You can rate this outing after its planned date.',
                        style: TextStyle(fontSize: 11, color: MH.secondary),
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: store.busy
                              ? null
                              : () => exportCalendar(context, entry),
                          icon: const Icon(Icons.event_outlined),
                          label: const Text('Calendar file'),
                        ),
                        TextButton(
                          onPressed: store.busy
                              ? null
                              : () async {
                                  if (await confirmAction(
                                        context,
                                        'Delete this history entry?',
                                        'This removes only your private history, not the shared plan.',
                                        'Delete',
                                      ) &&
                                      context.mounted) {
                                    await perform(
                                      context,
                                      store,
                                      () => store.deleteHistory(entry),
                                    );
                                  }
                                },
                          child: const Text('Delete private entry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget planInvitations(BuildContext context, MeetStore store) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    for (final invite in store.planInvites)
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GlassSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${invite['fromName']} invited you to ${invite['title']}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                (invite['expiresAt'] as Timestamp).toDate().isBefore(
                      DateTime.now(),
                    )
                    ? 'This invitation expired.'
                    : 'Joining shares your name. You review preferences before sharing them.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  if ((invite['expiresAt'] as Timestamp).toDate().isAfter(
                    DateTime.now(),
                  ))
                    FilledButton(
                      onPressed: store.busy
                          ? null
                          : () async {
                              await showJoinPlan(
                                context,
                                store,
                                invitation: invite['inviteId'] as String,
                              );
                              if (store.room?.id == invite['roomId']) {
                                await store.cloud.db
                                    .doc(
                                      'users/${store.cloud.uid}/planInvites/${invite['id']}',
                                    )
                                    .delete();
                              }
                            },
                      child: const Text('Review and join'),
                    ),
                  TextButton(
                    onPressed: store.busy
                        ? null
                        : () => perform(
                            context,
                            store,
                            () => store.cloud.db
                                .doc(
                                  'users/${store.cloud.uid}/planInvites/${invite['id']}',
                                )
                                .delete(),
                          ),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
  ],
);
