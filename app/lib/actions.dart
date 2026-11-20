import 'package:material_ui/material_ui.dart';

import 'domain.dart';
import 'store.dart';

Future<bool> perform(
  BuildContext context,
  MeetStore store,
  Future<void> Function() action, {
  String? message,
}) async {
  if (store.busy) return false;
  store.setBusy(true);
  try {
    await action();
    if (context.mounted && message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
    return false;
  } finally {
    store.setBusy(false);
  }
}

String readableDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

Future<bool> cloudConsent(BuildContext context, {required bool note}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          note ? 'Let AI prepare a draft?' : 'Explain your common ground?',
        ),
        content: Text(
          note
              ? 'Your note and current preference card will be sent to Google’s cloud AI through Firebase. MeetHalfway won’t save the raw note. You can edit the draft and review exactly what your group sees before sharing.'
              : 'The group’s approved preference cards and the top eligible activities will be sent to Google’s cloud AI through Firebase. It will explain the fit and tradeoffs. It cannot change anyone’s limits or add an activity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(note ? 'Send and draft' : 'Send and explain'),
          ),
        ],
      ),
    ) ??
    false;

Widget cardSummary(PreferenceCard card, MeetStore store) {
  final area =
      store.data.areas.firstWhere((a) => a['id'] == card.areaId)['name']
          as String;
  final entries = [
    ('Starting area', area),
    ('Spending limit', '\$${card.maxSpend} CAD'),
    ('Travel limit', '${card.maxTravel} min · ${card.mode}'),
    ('Available', '${timeLabel(card.earliest)}–${timeLabel(card.latest)}'),
    (
      'Interests',
      card.interests
          .map(
            (id) =>
                store.data.interests.firstWhere((i) => i['id'] == id)['name'],
          )
          .join(', '),
    ),
    ('Quiet setting', card.quiet ? 'Required' : 'Flexible'),
    ('Indoors', card.indoors ? 'Required' : 'Flexible'),
    ('Confirmed step-free access', card.stepFree ? 'Required' : 'Flexible'),
  ];
  return Column(
    children: [
      for (final (label, value) in entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
