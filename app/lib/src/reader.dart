import 'package:artichoke/src/multilinks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

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
    final result = await download(this.widget.path);
    setState(() {
      this.content = result?.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (this.content != null) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              actions: [
                IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () {
                      Share.share(widget.path);
                    }),
                IconButton(
                    icon: Icon(Icons.open_in_browser),
                    onPressed: () {
                      url_launcher.launch(widget.path);
                    }),
                IconButton(
                    icon: Icon(Icons.book),
                    onPressed: () async {
                      final links = await compute(extractLinks, content);
                      multilinkExtract(context, links);
                    })
              ],
              floating: true,
              pinned: false,
              snap: false,
            ),
            SliverFillRemaining(
                hasScrollBody: true,
                child: Markdown(
                  selectable: true,
                  data: this.content,
                  onTapLink: (link) {
                    if (link.startsWith("https://") ||
                        link.startsWith("http://")) {
                      Navigator.of(context).pushReplacementNamed(
                        '/read',
                        arguments: link,
                      );
                    }
                  },
                  extensionSet: md.ExtensionSet.gitHubWeb,
                ))
          ],
        ),
      );
    }

    if (this.timedOut) {
      return ArticleViewFailed(path: widget.path);
    }

    return Center(child: CircularProgressIndicator());
  }
}

class ArticleViewFailed extends StatelessWidget {
  const ArticleViewFailed({
    Key key,
    @required this.path,
  }) : super(key: key);

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning),
          Container(height: 8.0),
          Text('Failed to load article view'),
          Container(height: 24.0),
          SelectableText(
            this.path,
            textAlign: TextAlign.center,
          ),
          Container(height: 24.0),
          OutlineButton(
              onPressed: () {
                url_launcher.launch(this.path);
              },
              child: Text('Open in browser')),
          OutlineButton(
              onPressed: () {
                url_launcher.launch(
                    'https://docs.google.com/forms/d/e/1FAIpQLSdxzXRozr9qafH_P_FrhSv-ICaVJ3cAKmWpl51ShrYrq4aaJg/viewform?entry.211949886=${this.path}');
              },
              child: Text('Report article'))
        ],
      )),
    );
  }
}

class ReaderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MarkdownView(path: ModalRoute.of(context).settings.arguments);
  }
}
