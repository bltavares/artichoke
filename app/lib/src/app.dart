import 'dart:async';
import 'dart:io';

import 'package:artichoke/src/reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkify/linkify.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'home.dart';

class ShareIntentReceiver extends StatefulWidget {
  @override
  _ShareIntentReceiverState createState() => _ShareIntentReceiverState();
}

class _ShareIntentReceiverState extends State<ShareIntentReceiver>
    with WidgetsBindingObserver {
  String _sharedText;
  StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream()
        .listen((value) => setState(() => _sharedText = value));

    ReceiveSharingIntent.getInitialText()
        .then((value) => setState(() => _sharedText = value));

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
          _sharedText = data.text;
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

class SharedContent {
  final String content;
  SharedContent(this.content);
}

class Application extends StatelessWidget {
  static Widget create() {
    if (Platform.isAndroid) {
      return ShareIntentReceiver();
    }
    return Application();
  }

  List<LinkableElement> initialLinks(String sharedText) {
    if (sharedText == null || sharedText.isEmpty) {
      return [];
    }
    return linkify(sharedText)
        .where((element) => element is LinkableElement)
        .cast<LinkableElement>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final initialText = context.watch<SharedContent>();
    final links = initialLinks(initialText.content);
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
          '/read': (context) => ReaderScreen(),
        },
        home: HomeScreen(),
      ),
    );
  }
}
