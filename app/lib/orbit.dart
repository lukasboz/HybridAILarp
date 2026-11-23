import 'dart:math' as math;
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'design.dart';
import 'domain.dart';

class ActivityPhoto extends StatelessWidget {
  const ActivityPhoto(this.activity, {super.key});
  final Activity activity;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/activities/${activity.photo}.jpg',
    fit: BoxFit.cover,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => const ColoredBox(
      color: MH.accentSoft,
      child: Center(child: Icon(Icons.auto_awesome_outlined, color: MH.accent)),
    ),
  );
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.person, {super.key, this.index = 0, this.size = 35});
  final Person person;
  final int index;
  final double size;
  static final colors = [
    MH.orb,
    Color.lerp(MH.accent, MH.surface, .75)!,
    Color.lerp(MH.orb, MH.surface, .5)!,
    Color.lerp(MH.accent, MH.orb, .7)!,
  ];
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: colors[index % colors.length],
      border: Border.all(color: Colors.white, width: 2.5),
      boxShadow: [
        BoxShadow(
          color: MH.accent.withValues(alpha: .12),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      person.initials,
      style: TextStyle(
        fontSize: size * .27,
        fontWeight: FontWeight.w600,
        color: MH.secondary,
      ),
    ),
  );
}

class GlassOrb extends StatefulWidget {
  const GlassOrb({super.key, this.animate = true});
  final bool animate;
  @override
  State<GlassOrb> createState() => _GlassOrbState();
}

class _GlassOrbState extends State<GlassOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant GlassOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.animate && !MediaQuery.disableAnimationsOf(context)) {
      controller.repeat(reverse: true);
    } else {
      controller.stop();
      controller.value = .5;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.scale(
        scale: .97 + Curves.easeInOut.transform(controller.value) * .06,
        child: child,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MH.accent.withValues(alpha: .11),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: CustomPaint(
              painter: _OrbPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ),
  );
}

class _OrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size, c = rect.center, r = size.width / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-.45, -.55),
          radius: 1.1,
          colors: [
            Colors.white.withValues(alpha: .95),
            MH.orb.withValues(alpha: .8),
            MH.accent.withValues(alpha: .38),
          ],
        ).createShader(rect),
    );
    canvas.drawCircle(
      c,
      r - .6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .7),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, -r * .04),
        width: r * 1.65,
        height: r * 1.72,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..shader = SweepGradient(
          colors: [
            Colors.white.withValues(alpha: .65),
            Colors.white.withValues(alpha: .02),
            MH.accent.withValues(alpha: .4),
            Colors.white.withValues(alpha: .65),
          ],
        ).createShader(rect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-r * .02, -r * .06),
        width: r * 1.15,
        height: r * 1.5,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..color = Colors.white.withValues(alpha: .35),
    );
    canvas.restore();
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .33, size.height * .23),
        width: r * .75,
        height: r * .2,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: .8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      Offset(size.width * .26, size.height * .22),
      1.6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => false;
}

class ActivityOrbit extends StatelessWidget {
  const ActivityOrbit({
    super.key,
    required this.people,
    required this.activities,
    required this.onActivity,
    required this.onPerson,
    this.onCentre,
    this.home = false,
    this.ranked = const [],
    this.selected = '',
    this.ready = true,
    this.animate = true,
  });
  final List<Person> people;
  final List<Activity> activities;
  final List<RankedPlan> ranked;
  final ValueChanged<Activity> onActivity;
  final ValueChanged<Person> onPerson;
  final VoidCallback? onCentre;
  final bool home, ready, animate;
  final String selected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight, compact = w < 520;
      final centre = Offset(w / 2, h / 2), count = activities.length;
      // The ring stays inside the box, and tiles shrink before they touch.
      final fit = math.min(w, h) / 2 - 4;
      var tile = compact ? 52.0 : 70.0;
      var radius = math.min(fit - (tile + 4) / 2, 214.0);
      if (count > 1) {
        tile = (2 * radius * math.sin(math.pi / count) - 8).clamp(34.0, tile);
        radius = math.min(fit - (tile + 4) / 2, 214.0);
      }
      final orbSize = (radius * .6).clamp(60.0, 114.0);
      final avatar = (radius * .24).clamp(26.0, 38.0);
      final tiles = [
        for (var i = 0; i < count; i++) _tileRect(i, centre, radius, tile),
      ];
      final placed = _layoutPeople(context, centre, orbSize, avatar, tiles);
      final caption = home
          ? 'Find your halfway'
          : ready
          ? 'Common ground, found.'
          : 'Bringing everyone together.';
      final glow = math.min(320.0, radius * 2.5);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: centre.dx - glow / 2,
            top: centre.dy - glow / 2,
            width: glow,
            height: glow,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MH.orb.withValues(alpha: .3),
                    MH.accentSoft.withValues(alpha: .25),
                    MH.canvas.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: centre.dx - radius,
            top: centre.dy - radius,
            width: radius * 2,
            height: radius * 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: MH.accent.withValues(alpha: .035)),
              ),
            ),
          ),
          for (final (index, idea) in activities.indexed)
            _tile(idea, tiles[index]),
          Positioned(
            left: centre.dx - orbSize / 2,
            top: centre.dy - orbSize / 2,
            width: orbSize,
            height: orbSize,
            child: Semantics(
              button: home,
              label: home ? 'Explore the sample group' : 'Common ground',
              child: GestureDetector(
                onTap: onCentre,
                child: MouseRegion(
                  cursor: home
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GlassOrb(animate: animate),
                ),
              ),
            ),
          ),
          // The caption sits inside the orb, where nothing can crowd it.
          Positioned(
            left: centre.dx - orbSize / 2,
            top: centre.dy - orbSize / 2,
            width: orbSize,
            height: orbSize,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(orbSize * .1),
                    // Decorative and repeated elsewhere, so it may cap
                    // scaling rather than break words inside a small orb.
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: 1.15),
                      style: TextStyle(
                        fontSize: orbSize < 76
                            ? 8
                            : orbSize < 90
                            ? 9
                            : 10.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: MH.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          for (final (index, person) in people.take(8).indexed)
            _person(person, index, placed.rects[index], avatar, placed.lines),
        ],
      );
    },
  );

  // A half-step offset keeps the top of the ring free for the first person.
  Rect _tileRect(int index, Offset centre, double radius, double size) {
    final angle = (index + .5) / activities.length * 2 * math.pi - math.pi / 2;
    return Rect.fromCenter(
      center: centre + Offset(math.cos(angle), math.sin(angle)) * radius,
      width: size,
      height: size + 4,
    );
  }

  /// Places each person between the orb and the tiles, dropping the status
  /// line and then the name when they would collide with something.
  ({List<Rect> rects, int lines}) _layoutPeople(
    BuildContext context,
    Offset centre,
    double orbSize,
    double avatar,
    List<Rect> tiles,
  ) {
    final shown = people.take(8).toList();
    if (shown.isEmpty) return (rects: const <Rect>[], lines: 0);
    final scaler = MediaQuery.textScalerOf(context);
    double textWidth(String text, double size, FontWeight weight) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size,
            fontWeight: weight,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final ring = tiles.isEmpty
        ? orbSize * 1.6
        : (tiles.first.center - centre).distance - tiles.first.height / 2;
    final line = scaler.scale(13) + 2;
    List<Rect> place(int lines, double fraction) {
      final low = orbSize / 2 + avatar / 2 + 4, high = ring - avatar / 2 - 4;
      final radius = low + (high - low) * fraction;
      return [
        for (final (i, person) in shown.indexed)
          Rect.fromCenter(
            center:
                centre +
                Offset(
                      math.cos(i / shown.length * 2 * math.pi - math.pi / 2),
                      math.sin(i / shown.length * 2 * math.pi - math.pi / 2),
                    ) *
                    radius,
            width:
                [
                  avatar,
                  if (lines > 0)
                    math.min(textWidth(person.name, 9, FontWeight.w500), 84.0),
                  if (lines > 1) textWidth(_status(person), 8, FontWeight.w400),
                ].reduce(math.max) +
                4,
            height: avatar + lines * line,
          ),
      ];
    }

    bool clear(List<Rect> rects) {
      for (final (i, rect) in rects.indexed) {
        final near = Offset(
          centre.dx.clamp(rect.left, rect.right),
          centre.dy.clamp(rect.top, rect.bottom),
        );
        if ((near - centre).distance < orbSize / 2 + 3) return false;
        if (tiles.any((t) => t.inflate(3).overlaps(rect))) return false;
        if (rects.skip(i + 1).any((o) => o.inflate(2).overlaps(rect))) {
          return false;
        }
      }
      return true;
    }

    for (final lines in [2, 1]) {
      for (final fraction in [.5, .4, .6, .3, .7]) {
        final rects = place(lines, fraction);
        if (clear(rects)) return (rects: rects, lines: lines);
      }
    }
    return (rects: place(0, .5), lines: 0);
  }

  String _status(Person person) => home
      ? 'Sample'
      : person.card != null
      ? 'Ready'
      : 'Adding preferences';

  Widget _tile(Activity idea, Rect rect) {
    final fit = ranked.where((p) => p.candidate.id == idea.id).firstOrNull;
    final eligible = home || !ready || fit != null;
    return Positioned.fromRect(
      rect: rect,
      child: Tooltip(
        message: idea.name,
        child: Semantics(
          label: '${idea.name}${eligible ? '' : ', outside shared limits'}',
          button: true,
          child: Opacity(
            opacity: eligible ? 1 : .25,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: !home && !ready ? null : () => onActivity(idea),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: idea.id == selected
                          ? MH.accent.withValues(alpha: .6)
                          : MH.border.withValues(alpha: .6),
                      width: idea.id == selected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MH.ink.withValues(alpha: .08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ActivityPhoto(idea),
                      ),
                      if (!home && fit != null)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${fit.minFit}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: MH.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _person(
    Person person,
    int index,
    Rect rect,
    double avatar,
    int lines,
  ) => Positioned.fromRect(
    rect: rect,
    child: Semantics(
      button: true,
      label:
          '${person.name}, ${home
              ? 'sample participant'
              : person.card != null
              ? 'preferences shared'
              : 'adding preferences'}',
      child: InkWell(
        onTap: () => onPerson(person),
        borderRadius: BorderRadius.circular(12),
        child: ExcludeSemantics(
          child: Column(
            children: [
              PersonAvatar(person, index: index, size: avatar),
              if (lines > 0) ...[
                const SizedBox(height: 2),
                Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: MH.secondary,
                  ),
                ),
              ],
              if (lines > 1) ...[
                const SizedBox(height: 2),
                Text(
                  _status(person),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    height: 1.3,
                    color: MH.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
