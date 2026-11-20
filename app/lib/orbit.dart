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
      final compact = box.maxWidth < 520, w = box.maxWidth, h = box.maxHeight;
      final centre = Offset(w / 2, h * .46);
      final radius = math.min(w * .375, math.min(h * .39, 214.0));
      final peopleRadius = math.min(radius * .53, compact ? 79.0 : 109.0);
      final tile = compact ? 52.0 : 70.0, orbSize = compact ? 82.0 : 114.0;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: centre.dx - 160,
            top: centre.dy - 160,
            width: 320,
            height: 320,
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
            _tile(idea, index, centre, radius, tile),
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
          Positioned(
            top: centre.dy + orbSize / 2 + 19,
            left: centre.dx - 100,
            width: 200,
            child: Text(
              home
                  ? 'Find your halfway'
                  : ready
                  ? 'Common ground, found.'
                  : 'Bringing everyone together.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: compact ? 9 : 10, color: MH.muted),
            ),
          ),
          for (final (index, person) in people.take(8).indexed)
            _person(context, person, index, centre, peopleRadius, compact),
        ],
      );
    },
  );
  Widget _tile(
    Activity idea,
    int index,
    Offset centre,
    double radius,
    double size,
  ) {
    final angle = index / activities.length * 2 * math.pi - math.pi / 2;
    final fit = ranked.where((p) => p.candidate.id == idea.id).firstOrNull;
    final eligible = home || !ready || fit != null;
    return Positioned(
      left: centre.dx + math.cos(angle) * radius - size / 2,
      top: centre.dy + math.sin(angle) * radius - (size + 4) / 2,
      width: size,
      height: size + 4,
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
    BuildContext context,
    Person person,
    int index,
    Offset centre,
    double radius,
    bool compact,
  ) {
    final angle = index / people.length * 2 * math.pi - math.pi / 2;
    return Positioned(
      left: centre.dx + math.cos(angle) * radius - 43,
      top: centre.dy + math.sin(angle) * radius - 29,
      width: 86,
      height:
          73 + (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2) * 32,
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
          child: Column(
            children: [
              PersonAvatar(person, index: index, size: compact ? 31 : 38),
              const SizedBox(height: 5),
              Text(
                person.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w500,
                  color: MH.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                home
                    ? 'Sample'
                    : person.card != null
                    ? 'Ready'
                    : 'Adding preferences',
                style: const TextStyle(fontSize: 8, color: MH.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
