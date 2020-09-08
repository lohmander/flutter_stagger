library stagger;

import 'package:flutter/material.dart';

typedef StaggeredAnimationBuilder = Widget Function(
    BuildContext, List<Animation>);

class StaggerControllerRef {
  AnimationController controller;
}

class Stagger extends StatefulWidget {
  final Duration duration;
  final Curve curve;
  final int count;
  final double overlap;
  final bool forwardOnInit;
  final StaggeredAnimationBuilder builder;
  final StaggerControllerRef controllerRef;

  Stagger({
    this.duration = const Duration(seconds: 1),
    this.curve = Curves.linear,
    this.overlap = 0,
    this.forwardOnInit = true,
    this.controllerRef,
    @required this.count,
    @required this.builder,
  });

  @override
  _StaggerState createState() => _StaggerState();
}

class _StaggerState extends State<Stagger> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  List<Animation> _animations;

  @override
  void initState() {
    super.initState();

    assert(widget.overlap >= 0 && widget.overlap <= 1,
        "Overlap has to be between 0 and 1");

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Calculate the step size for each item
    final stepSize = 1 / widget.count;

    // If overlap is >0 use it as the fraction of the step size to overlap with
    // the previous animated item
    final overlapSize = stepSize * widget.overlap;

    // If there's an overlap we need to extend each animation with the remainder, so we
    // first check what the last index of the animations will be
    final lastIndex = widget.count - 1;

    // Then calculate what the current ending point for the last animation is
    final lastEnd = stepSize * lastIndex - (lastIndex * overlapSize);

    // Calculate the remainder to hit 1, i.e., the end of the animation
    final lastRemainder = 1 - lastEnd - stepSize;

    _animations = List.generate(
      widget.count,
      (i) {
        final begin = stepSize * i - (i * overlapSize);
        final end = begin + stepSize + lastRemainder;

        return CurvedAnimation(
          parent: _controller.view,
          curve: Interval(begin, end, curve: widget.curve),
        );
      },
    );

    if (widget.forwardOnInit) {
      _controller.forward();
    }

    if (widget.controllerRef != null) {
      widget.controllerRef.controller = _controller;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _animations);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
