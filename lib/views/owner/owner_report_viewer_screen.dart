import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OwnerReportViewerScreen extends StatefulWidget {
  final String url;
  final String periode;

  const OwnerReportViewerScreen({
    super.key,
    required this.url,
    required this.periode,
  });

  @override
  State<OwnerReportViewerScreen> createState() => _OwnerReportViewerScreenState();
}

class _OwnerReportViewerScreenState extends State<OwnerReportViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _progress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _triggerPrint() {
    _controller.runJavaScript('window.print();');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan Keuangan PDF',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Periode: ${widget.periode}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cetak / Simpan PDF',
            icon: const Icon(Icons.print_rounded, color: Color(0xFFF59E0B)),
            onPressed: _triggerPrint,
          ),
          IconButton(
            tooltip: 'Muat Ulang',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress / 100,
                backgroundColor: const Color(0xFF1E293B),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
              ),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(
                  top: BorderSide(color: Color(0xFF334155)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tekan tombol Cetak di atas untuk menyimpan laporan sebagai PDF di HP Anda.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _triggerPrint,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Cetak PDF'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
