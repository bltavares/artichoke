import 'dart:async';
import 'dart:io';

import 'package:artichoke/src/reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'ffi.dart';
import 'home.dart';

class ShareIntentReceiver extends StatefulWidget {
  @override
  _ShareIntentReceiverState createState() => _ShareIntentReceiverState();
}

class _ShareIntentReceiverState extends State<ShareIntentReceiver>
    with WidgetsBindingObserver {
  String _sharedText;
  StreamSubscription _intentDataStreamSubscription;

  String extractFromPocketShare(String url) {
    if (url != null && url.startsWith("https://getpocket.com/redirect?url=")) {
      return Uri.parse(url.substring(35)).toString();
    }
    return url;
  }

  @override
  void initState() {
    super.initState();

    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream().listen(
        (value) => setState(() => _sharedText = extractFromPocketShare(value)));

    ReceiveSharingIntent.getInitialText().then(
        (value) => setState(() => _sharedText = extractFromPocketShare(value)));

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      fetchFromClipboard();
    }
  }

  void fetchFromClipboard() {
    Clipboard.getData("text/plain").then((data) {
      if (data == null) return;
      if (data.text.startsWith("http://") || data.text.startsWith("https://")) {
        setState(() {
          _sharedText = extractFromPocketShare(data.text);
        });
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: SharedContent(_sharedText),
      child: Application(),
    );
  }
}

class ClipboardOnOpen extends StatefulWidget {
  @override
  _ClipboardOnOpenState createState() => _ClipboardOnOpenState();
}

class _ClipboardOnOpenState extends State<ClipboardOnOpen> {
  String _sharedText;

  @override
  void initState() {
    super.initState();
    fetchFromClipboard();
  }

  void fetchFromClipboard() {
    Clipboard.getData("text/plain").then((data) {
      if (data == null) return;
      if (data.text.startsWith("http://") || data.text.startsWith("https://")) {
        setState(() {
          _sharedText = data.text;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: SharedContent(_sharedText),
      child: Application(),
    );
  }
}

class SharedContent {
  final String content;
  SharedContent(this.content);
}

class Application extends StatelessWidget {
  static Widget create() {
    if (Platform.isAndroid) {
      return ShareIntentReceiver();
    }
    return ClipboardOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final initialText = context.watch<SharedContent>();
    final links = extractLinks(initialText.content);
    return Provider.value(
      value: links,
      child: MaterialApp(
        title: 'Artichoke - Article Viewer',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {
          '/': (context) => HomeScreen(),
          '/read': (context) => ReaderScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}
