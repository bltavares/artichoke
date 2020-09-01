import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './src/reader.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artichoke - Article Viewer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {
        '/read': (context) => ReaderScreen(),
      },
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FindUrl(),
    );
  }
}

class FindUrl extends StatefulWidget {
  @override
  _FindUrlState createState() => _FindUrlState();
}

class _FindUrlState extends State<FindUrl> {
  String path;
  TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  void initState() {
    super.initState();
    Clipboard.getData("text/plain").then((data) {
      if (data.text.startsWith("http://") || data.text.startsWith("https://")) {
        controller.text = data.text;
        setState(() {
          path = data.text;
        });
      }
    });
  }

  void submit(String input) {
    final data = input ?? this.path;
    if (data == null) {
      return;
    }
    final url = Uri.parse(data);
    if (url.scheme == "http" || url.scheme == "https") {
      Navigator.of(context).pushNamed(
        '/read',
        arguments: this.path,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: controller,
              onSubmitted: submit,
              decoration: InputDecoration(
                hintText: "website",
                suffixIcon: IconButton(
                  onPressed: () {
                    controller.clear();
                  },
                  icon: Icon(Icons.clear),
                ),
              ),
              onChanged: (input) {
                setState(() {
                  this.path = input;
                });
              },
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter,
              ],
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
            ),
            OutlineButton.icon(
              onPressed: () {
                submit(null);
              },
              label: Text('Read'),
              icon: Icon(Icons.chrome_reader_mode),
            )
          ],
        ),
      ),
    );
  }
}
