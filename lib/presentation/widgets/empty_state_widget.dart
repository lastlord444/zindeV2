import 'package:flutter/material.dart';

/// x�� Empty State Widget
/// Profesyonel bo_ durum ekranlar1
class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final IconData? customIcon;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.actionLabel,
    this.onActionPressed,
    this.customIcon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon veya Animation
            _buildIllustration(config),
            const SizedBox(height: 24),

            // Ba_lık
            Text(
              title ?? config.defaultTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Mesaj
            Text(
              message ?? config.defaultMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            // Action Button
            if (onActionPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: Icon(config.actionIcon, size: 24),
                label: Text(
                  actionLabel ?? config.defaultActionLabel,
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(_EmptyStateConfig config) {
    // Custom icon kullanılmı_sa
    if (customIcon != null) {
      return _AnimatedIcon(
        icon: customIcon!,
        color: iconColor ?? config.iconColor,
      );
    }

    // Default icon
    return _AnimatedIcon(
      icon: config.icon,
      color: config.iconColor,
    );
  }

  _EmptyStateConfig _getConfig() {
    switch (type) {
      case EmptyStateType.noPlan:
        return _EmptyStateConfig(
          icon: Icons.restaurant_menu,
          iconColor: Colors.purple.shade200,
          defaultTitle: 'Beslenme Plan1 Oluştur',
          defaultMessage:
              'G�nl�k beslenme planınız1 oluşturmak i�in\naşağıdaki butona tıklayın',
          defaultActionLabel: 'Plan Oluştur',
          actionIcon: Icons.add_circle_outline,
          buttonColor: Colors.purple,
        );

      case EmptyStateType.error:
        return _EmptyStateConfig(
          icon: Icons.error_outline,
          iconColor: Colors.red.shade200,
          defaultTitle: 'Bir Hata Oluştu',
          defaultMessage:
              'Beklenmeyen bir sorun oluştu.\nL�tfen tekrar deneyin.',
          defaultActionLabel: 'Yeniden Dene',
          actionIcon: Icons.refresh,
          buttonColor: Colors.red,
        );

      case EmptyStateType.noData:
        return _EmptyStateConfig(
          icon: Icons.inbox_outlined,
          iconColor: Colors.grey.shade300,
          defaultTitle: 'Veri Bulunamad1',
          defaultMessage: 'Bu tarih i�in hen�z bir plan oluşturulmamı_',
          defaultActionLabel: 'Plan Oluştur',
          actionIcon: Icons.add,
          buttonColor: Colors.blue,
        );

      case EmptyStateType.loading:
        return _EmptyStateConfig(
          icon: Icons.hourglass_empty,
          iconColor: Colors.blue.shade200,
          defaultTitle: 'Y�kleniyor...',
          defaultMessage: 'Verileriniz hazırlanıyor',
          defaultActionLabel: 'Bekleyin',
          actionIcon: Icons.pending,
          buttonColor: Colors.blue,
        );

      case EmptyStateType.noInternet:
        return _EmptyStateConfig(
          icon: Icons.wifi_off,
          iconColor: Colors.orange.shade200,
          defaultTitle: '0nternet Balantıs1 Yok',
          defaultMessage:
              'L�tfen internet balantınız1 kontrol edip\ntekrar deneyin',
          defaultActionLabel: 'Tekrar Dene',
          actionIcon: Icons.refresh,
          buttonColor: Colors.orange,
        );

      case EmptyStateType.success:
        return _EmptyStateConfig(
          icon: Icons.check_circle_outline,
          iconColor: Colors.green.shade200,
          defaultTitle: 'Ba_arıl1!',
          defaultMessage: '0_lem ba_arıyla tamamland1',
          defaultActionLabel: 'Devam Et',
          actionIcon: Icons.arrow_forward,
          buttonColor: Colors.green,
        );

      case EmptyStateType.emptyMeals:
        return _EmptyStateConfig(
          icon: Icons.food_bank_outlined,
          iconColor: Colors.orange.shade200,
          defaultTitle: '��n Bulunamad1',
          defaultMessage:
              'Veritabanında bu kriterlere uygun ��n bulunamad1',
          defaultActionLabel: 'Filtre Dei_tir',
          actionIcon: Icons.filter_list,
          buttonColor: Colors.orange,
        );

      case EmptyStateType.noFavorites:
        return _EmptyStateConfig(
          icon: Icons.favorite_border,
          iconColor: Colors.pink.shade200,
          defaultTitle: 'Favori Yemek Yok',
          defaultMessage:
              'Hen�z favori yemek eklemediniz.\nBeendiiniz yemekleri favorilere ekleyerek kolayca eri_ebilirsiniz.',
          defaultActionLabel: 'Yemek Ke_fet',
          actionIcon: Icons.explore,
          buttonColor: Colors.pink,
        );
    }
  }
}

class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedIcon({
    required this.icon,
    required this.color,
  });

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(
              widget.icon,
              size: 80,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyStateConfig {
  final IconData icon;
  final Color iconColor;
  final String defaultTitle;
  final String defaultMessage;
  final String defaultActionLabel;
  final IconData actionIcon;
  final Color buttonColor;

  _EmptyStateConfig({
    required this.icon,
    required this.iconColor,
    required this.defaultTitle,
    required this.defaultMessage,
    required this.defaultActionLabel,
    required this.actionIcon,
    required this.buttonColor,
  });
}

enum EmptyStateType {
  noPlan,
  error,
  noData,
  loading,
  noInternet,
  success,
  emptyMeals,
  noFavorites, // xRx Favori bo_ durum
}

/// = Custom RefreshIndicator with Feedback
class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Haptic feedback
        try {
          await Future.wait([
            onRefresh(),
            Future.delayed(const Duration(milliseconds: 300)),
          ]);

          // Success feedback
          if (context.mounted) {
            _showRefreshFeedback(context, success: true);
          }
        } catch (e) {
          // Error feedback
          if (context.mounted) {
            _showRefreshFeedback(context, success: false);
          }
          rethrow;
        }
      },
      color: color ?? Colors.purple,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      displacement: 40,
      child: child,
    );
  }

  void _showRefreshFeedback(BuildContext context, {required bool success}) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            success ? 'Ba_arıyla g�ncellendi!' : 'G�ncelleme ba_arısız',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
      backgroundColor: success ? Colors.green : Colors.red,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// x�� Success Overlay Animation
class SuccessOverlay extends StatefulWidget {
  final String message;
  final VoidCallback? onComplete;

  const SuccessOverlay({
    super.key,
    required this.message,
    this.onComplete,
  });

  static void show(BuildContext context,
      {required String message, VoidCallback? onComplete}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => SuccessOverlay(
        message: message,
        onComplete: () {
          Navigator.of(context).pop();
          onComplete?.call();
        },
      ),
    );
  }

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
