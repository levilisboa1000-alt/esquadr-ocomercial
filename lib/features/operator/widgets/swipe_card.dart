import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/lead_model.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_badge.dart';

class SwipeCard extends StatefulWidget {
  final LeadModel lead;
  final bool isFront;
  final Function(SwipeAction action) onSwipeComplete;

  const SwipeCard({
    super.key,
    required this.lead,
    this.isFront = false,
    required this.onSwipeComplete,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  bool _isDragging = false;
  double _angle = 0;
  Size _screenSize = Size.zero;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isFront) return;
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isFront) return;
    setState(() {
      _position += details.delta;
      // Rotação sutil proporcional ao deslocamento horizontal
      _angle = 35 * (_position.dx / _screenSize.width) * (pi / 180);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isFront) return;
    setState(() => _isDragging = false);

    final dx = _position.dx;
    final dy = _position.dy;
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final velocityY = details.velocity.pixelsPerSecond.dy;

    const threshold = 90.0;
    const velocityThreshold = 450.0;

    SwipeAction? action;

    // Determina a direção dominante do swipe
    if (dx.abs() > dy.abs()) {
      if (dx > threshold || velocityX > velocityThreshold) {
        action = SwipeAction.callRight;
      } else if (dx < -threshold || velocityX < -velocityThreshold) {
        action = SwipeAction.voicemailLeft;
      }
    } else {
      if (dy < -threshold || velocityY < -velocityThreshold) {
        action = SwipeAction.scheduleUp;
      } else if (dy > threshold || velocityY > velocityThreshold) {
        action = SwipeAction.rejectDown;
      }
    }

    if (action != null) {
      _animateOut(action);
    } else {
      _animateBack();
    }
  }

  void _animateOut(SwipeAction action) {
    double endX = 0, endY = 0;
    switch (action) {
      case SwipeAction.callRight:
        endX = _screenSize.width * 1.8;
        break;
      case SwipeAction.voicemailLeft:
        endX = -_screenSize.width * 1.8;
        break;
      case SwipeAction.scheduleUp:
        endY = -_screenSize.height * 1.8;
        break;
      case SwipeAction.rejectDown:
        endY = _screenSize.height * 1.8;
        break;
    }

    final tween = Tween<Offset>(begin: _position, end: Offset(endX, endY));
    final anim = tween.animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    anim.addListener(() {
      setState(() => _position = anim.value);
    });

    _animationController.forward(from: 0).then((_) {
      widget.onSwipeComplete(action);
    });
  }

  void _animateBack() {
    final tween = Tween<Offset>(begin: _position, end: Offset.zero);
    final anim = tween.animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    anim.addListener(() {
      setState(() {
        _position = anim.value;
        _angle = 35 * (_position.dx / _screenSize.width) * (pi / 180);
      });
    });

    _animationController.forward(from: 0);
  }

  Widget _buildIndicators() {
    if (!_isDragging) return const SizedBox.shrink();

    Widget? badge;
    final dist = _position.distance;
    final opacity = min(dist / 80.0, 1.0);

    if (_position.dx.abs() > _position.dy.abs()) {
      if (_position.dx > 40) {
        badge = _badgeWidget("📞 LIGAR", AppColors.actionRight);
      } else if (_position.dx < -40) {
        badge = _badgeWidget("📭 CAIXA POSTAL", AppColors.actionLeft);
      }
    } else {
      if (_position.dy < -40) {
        badge = _badgeWidget("📅 AGENDAR", AppColors.actionUp);
      } else if (_position.dy > 40) {
        badge = _badgeWidget("✕ NÃO INTERESSADO", AppColors.actionDown);
      }
    }

    if (badge == null) return const SizedBox.shrink();

    return Positioned(
      top: 40,
      left: _position.dx > 0 ? 24 : null,
      right: _position.dx < 0 ? 24 : null,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: _position.dx > 0 ? -0.15 : 0.15,
          child: badge,
        ),
      ),
    );
  }

  Widget _badgeWidget(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundStart.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = _screenSize.width > 500 ? 440.0 : _screenSize.width * 0.90;
    final height = _screenSize.height * 0.62;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedContainer(
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 250),
        transform: Matrix4.identity()
          ..translate(_position.dx, _position.dy)
          ..rotateZ(_angle)
          ..scale(widget.isFront ? 1.0 : 0.94),
        alignment: Alignment.center,
        child: Stack(
          children: [
            GlassContainer(
              width: width,
              height: height,
              padding: const EdgeInsets.all(26),
              borderRadius: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassBadge(
                        text: widget.lead.source,
                        color: AppColors.actionUp,
                        icon: Icons.tag,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.history_toggle_off, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            "${widget.lead.attemptCount}x tent.",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Avatar / Ícone de perfil com anel Liquid Glass
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.glassBackgroundLight,
                        border: Border.all(color: AppColors.glassBorderLight, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 42,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nome do Lead
                  Center(
                    child: Text(
                      widget.lead.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Localização
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.textSecondary, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          "${widget.lead.city.isNotEmpty ? widget.lead.city : 'Cidade'} - ${widget.lead.state.isNotEmpty ? widget.lead.state : 'UF'}",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18.0),
                    child: Divider(color: Colors.white12, height: 1),
                  ),

                  // Dados do Negócio (Interesse e Valor)
                  _infoTile(
                    Icons.real_estate_agent_outlined,
                    "Interesse Principal",
                    widget.lead.interest.isNotEmpty ? widget.lead.interest : "Imóvel / Produto",
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    Icons.payments_outlined,
                    "Valor Estimado",
                    widget.lead.propertyValue > 0
                        ? Formatters.formatCurrency(widget.lead.propertyValue)
                        : "A consultar",
                  ),

                  if (widget.lead.notes != null && widget.lead.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoTile(
                      Icons.notes_rounded,
                      "Observação",
                      widget.lead.notes!,
                    ),
                  ],

                  const Spacer(flex: 2),
                ],
              ),
            ),

            // Badges flutuantes durante o arrasto
            _buildIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
