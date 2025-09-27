import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Smooth fade transition widget
class SmoothFadeTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool visible;
  final Curve curve;

  const SmoothFadeTransition({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.visible = true,
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  State<SmoothFadeTransition> createState() => _SmoothFadeTransitionState();
}

class _SmoothFadeTransitionState extends State<SmoothFadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    
    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SmoothFadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// Smooth slide transition widget
class SmoothSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset begin;
  final Offset end;
  final bool visible;
  final Curve curve;

  const SmoothSlideTransition({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.begin = const Offset(0.0, 1.0),
    this.end = Offset.zero,
    this.visible = true,
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  State<SmoothSlideTransition> createState() => _SmoothSlideTransitionState();
}

class _SmoothSlideTransitionState extends State<SmoothSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _slideAnimation = Tween<Offset>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    
    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SmoothSlideTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Smooth scale transition widget
class SmoothScaleTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double begin;
  final double end;
  final bool visible;
  final Curve curve;

  const SmoothScaleTransition({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.begin = 0.0,
    this.end = 1.0,
    this.visible = true,
    this.curve = Curves.elasticOut,
  }) : super(key: key);

  @override
  State<SmoothScaleTransition> createState() => _SmoothScaleTransitionState();
}

class _SmoothScaleTransitionState extends State<SmoothScaleTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    
    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SmoothScaleTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Animated counter widget
class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? textStyle;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    Key? key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.textStyle,
    this.prefix = '',
    this.suffix = '',
  }) : super(key: key);

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    _previousValue = widget.value;
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      
      _previousValue = widget.value;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value.round()}${widget.suffix}',
          style: widget.textStyle,
        );
      },
    );
  }
}

/// Animated progress bar
class AnimatedProgressBar extends StatefulWidget {
  final double value;
  final Duration duration;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;
  final BorderRadius? borderRadius;

  const AnimatedProgressBar({
    Key? key,
    required this.value,
    this.duration = const Duration(milliseconds: 600),
    this.backgroundColor,
    this.valueColor,
    this.height = 8.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.grey[300],
            borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: widget.valueColor ?? Theme.of(context).primaryColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Staggered animation list
class StaggeredAnimationList extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Curve curve;

  const StaggeredAnimationList({
    Key? key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  State<StaggeredAnimationList> createState() => _StaggeredAnimationListState();
}

class _StaggeredAnimationListState extends State<StaggeredAnimationList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(duration: widget.itemDuration, vsync: this),
    );

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: widget.curve));
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: widget.curve));
    }).toList();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return SlideTransition(
          position: _slideAnimations[index],
          child: FadeTransition(
            opacity: _fadeAnimations[index],
            child: widget.children[index],
          ),
        );
      }),
    );
  }
}

/// Pulse animation widget
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool repeat;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.repeat = true,
  }) : super(key: key);

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerLoading({
    Key? key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                math.max(0.0, _animation.value - 0.3),
                _animation.value,
                math.min(1.0, _animation.value + 0.3),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Bounce animation widget
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double bounceHeight;
  final bool repeat;

  const BounceAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.bounceHeight = 20.0,
    this.repeat = true,
  }) : super(key: key);

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0.0,
      end: -widget.bounceHeight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));

    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}