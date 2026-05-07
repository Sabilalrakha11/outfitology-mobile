import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../main.dart';

// ============================================================
// PAYMENT WEBVIEW SCREEN — Midtrans Snap langsung di dalam app
// Perlu tambah di pubspec.yaml:
//   webview_flutter: ^4.7.0
// ============================================================
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final int orderId;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailed;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.orderId,
    this.onSuccess,
    this.onFailed,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _title = 'PAYMENT';
  double _progress = 0;

  // URL patterns dari Midtrans untuk deteksi status
  static const _successPatterns = [
    'transaction_status=capture',
    'transaction_status=settlement',
    'status_code=200',
    '/finish',
    'payment_type=',
  ];
  static const _failedPatterns = [
    'transaction_status=deny',
    'transaction_status=cancel',
    'transaction_status=expire',
    '/error',
    'status_code=202',
  ];
  static const _pendingPatterns = [
    'transaction_status=pending',
    '/pending',
  ];

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.canvas)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() { _progress = progress / 100; });
          },
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _checkPaymentStatus(url);
          },
          onPageFinished: (url) async {
            setState(() {
              _isLoading = false;
              _progress = 0;
            });
            // Ambil title halaman
            final title = await _controller.getTitle();
            if (mounted) setState(() => _title = title ?? 'PAYMENT');
            _checkPaymentStatus(url);
          },
          onWebResourceError: (error) {
            debugPrint('WebView Error: ${error.description}');
          },
          onNavigationRequest: (request) {
            // Blok deeplink non-http agar tidak crash
            final url = request.url;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentStatus(String url) {
    final lower = url.toLowerCase();

    if (_successPatterns.any((p) => lower.contains(p))) {
      _handleSuccess();
    } else if (_failedPatterns.any((p) => lower.contains(p))) {
      _handleFailed();
    } else if (_pendingPatterns.any((p) => lower.contains(p))) {
      _handlePending();
    }
  }

  void _handleSuccess() {
    if (!mounted) return;
    _showStatusSheet(
      icon: Icons.check_circle_outline_rounded,
      color: Colors.green,
      title: 'Payment Successful!',
      subtitle: 'Your order is being processed.\nYou\'ll receive a confirmation shortly.',
      primaryLabel: 'VIEW ORDER',
      onPrimary: () {
        Navigator.popUntil(context, (r) => r.isFirst);
        widget.onSuccess?.call();
      },
    );
  }

  void _handleFailed() {
    if (!mounted) return;
    _showStatusSheet(
      icon: Icons.cancel_outlined,
      color: Colors.red,
      title: 'Payment Failed',
      subtitle: 'Your payment was not completed.\nPlease try again.',
      primaryLabel: 'TRY AGAIN',
      secondaryLabel: 'BACK TO CART',
      onPrimary: () {
        Navigator.pop(context); // tutup sheet
        _controller.loadRequest(Uri.parse(widget.paymentUrl)); // reload
      },
      onSecondary: () {
        Navigator.popUntil(context, (r) => r.isFirst);
        widget.onFailed?.call();
      },
    );
  }

  void _handlePending() {
    if (!mounted) return;
    _showStatusSheet(
      icon: Icons.access_time_rounded,
      color: Colors.orange,
      title: 'Payment Pending',
      subtitle: 'Your payment is being processed.\nPlease complete within the time limit.',
      primaryLabel: 'CONTINUE PAYMENT',
      secondaryLabel: 'CHECK LATER',
      onPrimary: () => Navigator.pop(context),
      onSecondary: () {
        Navigator.popUntil(context, (r) => r.isFirst);
      },
    );
  }

  void _showStatusSheet({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String primaryLabel,
    String? secondaryLabel,
    required VoidCallback onPrimary,
    VoidCallback? onSecondary,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (_) => Container(
        color: AppTheme.canvas,
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 20),
            Text(title, style: AppTheme.displayMedium.copyWith(fontSize: 20),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(subtitle, style: AppTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity,
                child: PrimaryButton(label: primaryLabel, onPressed: onPrimary)),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onSecondary,
                child: Center(
                  child: Text(secondaryLabel,
                    style: AppTheme.labelCaps.copyWith(
                      decoration: TextDecoration.underline,
                      color: AppTheme.stone,
                    )),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    // Konfirmasi keluar dari payment
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Leave Payment?', style: AppTheme.headingBold),
        content: Text('Are you sure you want to cancel this payment?', style: AppTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('STAY', style: AppTheme.labelCaps)),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('LEAVE', style: AppTheme.labelCaps.copyWith(color: Colors.red))),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: AppTheme.canvas,
        appBar: AppBar(
          title: Text(_title.toUpperCase()),
          leading: GestureDetector(
            onTap: () async {
              if (await _onBackPressed()) Navigator.pop(context);
            },
            child: const Icon(Icons.close_rounded),
          ),
          actions: [
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _controller.reload(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: _progress > 0
                ? LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AppTheme.mist,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.ink),
                    minHeight: 2,
                  )
                : const SizedBox.shrink(),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading && _progress == 0)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.ink, strokeWidth: 2),
              ),
          ],
        ),
        // Lock screen saat loading
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          color: AppTheme.canvas,
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.stone),
              const SizedBox(width: 6),
              Text('Secured by Midtrans', style: AppTheme.bodySmall),
              const Spacer(),
              // SSL indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.green.shade50,
                child: Text('SSL', style: AppTheme.labelCaps.copyWith(
                    color: Colors.green.shade700, fontSize: 9)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}