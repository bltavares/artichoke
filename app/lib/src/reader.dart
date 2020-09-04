import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import './ffi.dart';

class MarkdownView extends StatefulWidget {
  final String path;

  const MarkdownView({Key key, @required this.path}) : super(key: key);

  @override
  _MarkdownViewState createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  String content;
  bool timedOut = false;

  @override
  void initState() {
    super.initState();
    downloadContent();
    timeoutScreen();
  }

  void timeoutScreen() {
    Future.delayed(Duration(seconds: 5)).then((value) => {
          if (this.content == null)
            {
              setState(() {
                this.timedOut = true;
              })
            }
        });
  }

  void downloadContent() async {
    final result = await compute(download, this.widget.path);
    setState(() {
      this.content = result.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (this.content != null) {
      return Markdown(
        selectable: true,
        data: this.content,
        onTapLink: (link) {
          if (link.startsWith("https://") || link.startsWith("http://")) {
            Navigator.of(context).pushReplacementNamed(
              '/read',
              arguments: link,
            );
          }
        },
        extensionSet: md.ExtensionSet.gitHubWeb,
      );
    }

    if (this.timedOut) {
      return Center(child: Text('Failed to load: ${this.widget.path}'));
    }

    return Center(child: CircularProgressIndicator());
  }
}

class ReaderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            floating: true,
            pinned: false,
            snap: false,
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: MarkdownView(
              path: ModalRoute.of(context).settings.arguments,
            ),
          )
        ],
      ),
    );
  }
}
