import 'package:material_ui/material_ui.dart';

import 'design.dart';
import 'domain.dart';
import 'orbit.dart';

/// An illustrative Toronto schematic, not a navigation map: dashed arcs join
/// each person's neighbourhood centre to the activity.
class TravelMap extends StatelessWidget {
  const TravelMap({
    super.key,
    required this.people,
    required this.activity,
    required this.areas,
  });
  final List<Person> people;
  final Activity activity;
  final List<Json> areas;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label:
        'Illustrative map of travel from each person’s neighbourhood to ${activity.venue}. Not a navigation map.',
    child: ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.6,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _TravelMapPainter(people, activity, areas),
          ),
        ),
      ),
    ),
  );
}

class _TravelMapPainter extends CustomPainter {
  _TravelMapPainter(this.people, this.activity, this.areas);
  final List<Person> people;
  final Activity activity;
  final List<Json> areas;
  static const width = 600.0, height = 375.0;

  // A fixed projection of central Toronto; the lake sits below y = 345.
  static Offset project(num lat, num lng) => Offset(
    (30 + (lng + 79.48) / .17 * 540).clamp(30, 570).toDouble(),
    (335 - (lat - 43.625) / .09 * 305).clamp(24, 330).toDouble(),
  );

  void label(
    Canvas canvas,
    String text,
    Offset centre,
    TextStyle style, {
    double maxWidth = 160,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / width, size.height / height);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Color.lerp(MH.canvas, MH.surface, .5)!,
    );
    final streets = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    for (final (a, b) in const [
      (Offset(-20, 205), Offset(620, 120)),
      (Offset(-20, 290), Offset(620, 210)),
      (Offset(95, 0), Offset(150, 345)),
      (Offset(300, 0), Offset(345, 345)),
      (Offset(470, 0), Offset(500, 345)),
    ]) {
      canvas.drawLine(a, b, streets);
    }
    final lake = Path()
      ..moveTo(0, 340)
      ..quadraticBezierTo(150, 326, 300, 344)
      ..quadraticBezierTo(450, 360, 600, 338)
      ..lineTo(600, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(lake, Paint()..color = MH.orb.withValues(alpha: .75));
    const quiet = TextStyle(
      fontSize: 10,
      letterSpacing: 1.4,
      color: MH.muted,
      fontFamily: 'Inter',
    );
    label(canvas, 'LAKE ONTARIO', const Offset(420, 360), quiet);
    for (final area in areas) {
      final point = project(area['lat'] as num, area['lng'] as num);
      label(
        canvas,
        (area['name'] as String).toUpperCase(),
        point + const Offset(0, 26),
        quiet.copyWith(fontSize: 9),
      );
    }

    final target = project(activity.lat, activity.lng);
    final arc = Paint()
      ..color = MH.accent.withValues(alpha: .65)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final origins = <Offset>[];
    for (final (i, person) in people.indexed) {
      final card = person.card;
      if (card == null) continue;
      final area = areas.firstWhere((a) => a['id'] == card.areaId);
      // People from the same neighbourhood sit side by side.
      final neighbours = people
          .take(i)
          .where((p) => p.card?.areaId == card.areaId)
          .length;
      final origin =
          project(area['lat'] as num, area['lng'] as num) +
          Offset(neighbours * 26.0, 0);
      origins.add(origin);
      final mid = Offset.lerp(origin, target, .5)!;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..quadraticBezierTo(mid.dx + 30, mid.dy - 34, target.dx, target.dy);
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 10) {
          canvas.drawPath(metric.extractPath(d, d + 5), arc);
        }
      }
    }
    for (final (i, person) in people.where((p) => p.card != null).indexed) {
      final origin = origins[i];
      canvas.drawCircle(origin, 15, Paint()..color = Colors.white);
      canvas.drawCircle(
        origin,
        12.5,
        Paint()
          ..color = PersonAvatar
              .colors[people.indexOf(person) % PersonAvatar.colors.length],
      );
      label(
        canvas,
        person.initials,
        origin,
        const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: MH.ink,
          fontFamily: 'Inter',
        ),
        maxWidth: 24,
      );
    }
    canvas.drawCircle(target, 19, Paint()..color = MH.orb);
    canvas.drawCircle(target, 16, Paint()..color = MH.ink);
    label(
      canvas,
      String.fromCharCode(Icons.place_rounded.codePoint),
      target,
      TextStyle(
        fontSize: 17,
        color: MH.surface,
        fontFamily: Icons.place_rounded.fontFamily,
        package: Icons.place_rounded.fontPackage,
      ),
    );
  }

  @override
  bool shouldRepaint(_TravelMapPainter old) =>
      old.activity != activity || old.people != people || old.areas != areas;
}
