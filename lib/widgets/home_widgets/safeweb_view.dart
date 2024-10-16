import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SafeWebView extends StatefulWidget {
  final String url;

  const SafeWebView({Key? key, required this.url}) : super(key: key);

  @override
  State<SafeWebView> createState() => _SafeWebViewState();
}

class _SafeWebViewState extends State<SafeWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}