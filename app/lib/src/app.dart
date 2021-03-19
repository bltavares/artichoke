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

class _ShareIntentReceiverState extends State<ShareIntentReceiver> {
  String? _sharedText;
  late StreamSubscription _intentDataStreamSubscription;

  String? extractFromPocketShare(String? url) {
    if (url != null && url.startsWith("https://getpocket.com/redirect?url=")) {
      return Uri.decodeFull(Uri.parse(url).queryParameters['url']!).toString();
    }
    return url;
  }

  @override
  void initState() {
    super.initState();

    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream().listen(
      (value) {
        if (value == '') return;
        setState(() => _sharedText = extractFromPocketShare(value));
      },
    );

    ReceiveSharingIntent.getInitialText().then((value) {
      if (value == null || value == '') return;
      setState(() => _sharedText = extractFromPocketShare(value));
    });
  }

  void fetchFromClipboard() {
    Clipboard.getData("text/plain").then((data) {
      if (data == null || data.text == '') return;
      setState(() {
        _sharedText = extractFromPocketShare(data.text);
      });
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
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
  final String? content;
  SharedContent(this.content);
}

class Application extends StatelessWidget {
  static Widget create() {
    if (Platform.isAndroid) {
      return ShareIntentReceiver();
    }
    return Provider.value(
      value: SharedContent(null),
      child: Application(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialText = context.watch<SharedContent>();
    final links = extractLinks(initialText.content);
    return Provider.value(
      value: links,
      child: MaterialApp(
        title: 'Artichoke - Article Viewer',
        theme: ThemeData.from(
          colorScheme: ColorScheme.dark().copyWith(secondary: Colors.purple),
        ).copyWith(
          canvasColor: Colors.black,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: AppBarTheme(color: Colors.black),
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
