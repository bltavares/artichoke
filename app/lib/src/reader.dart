import 'package:artichoke/src/multilinks.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  Article content;
  bool timedOut;
  ScrollController controller;

  @override
  void initState() {
    super.initState();
    timedOut = false;
    controller = ScrollController();
    downloadContent();
    timeoutScreen();
  }

  void timeoutScreen() {
    Future.delayed(Duration(seconds: 8)).then((value) => {
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
      this.content = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (this.content != null) {
      final theme = Theme.of(context);
      final readTheme = theme.copyWith(
        textTheme: theme.textTheme.apply(fontSizeFactor: 1.5),
      );

      return Scaffold(
        body: CustomScrollView(
          controller: controller,
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
                      final links = await compute(
                        extractLinks,
                        content.content,
                      );
                      multilinkExtract(context, links);
                    })
              ],
              floating: true,
              pinned: false,
              snap: true,
            ),
            SliverToBoxAdapter(
              child: Center(
                child: Column(
                  children: [
                    Container(height: 12),
                    Text(
                      this.content.metadata['title'],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headline3,
                    ),
                    Text(
                      "${this.content.metadata['word_count']} words",
                      style: theme.textTheme.subtitle2,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Theme(
                data: readTheme,
                child: Markdown(
                  shrinkWrap: true,
                  controller: controller,
                  selectable: true,
                  data: this.content.content,
                  onTapLink: (link) {
                    if (link.startsWith("https://") ||
                        link.startsWith("http://")) {
                      Navigator.of(context).pushReplacementNamed(
                        '/read',
                        arguments: link,
                      );
                    }
                  },
                  imageBuilder: (uri, title, alt) {
                    return Center(
                      child: Column(
                        children: [
                          CachedNetworkImage(
                            imageUrl: uri.toString(),
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) =>
                                    CircularProgressIndicator(
                                        value: downloadProgress.progress),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                          if (title != null)
                            Text(
                              title,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          if (alt != null)
                            Text(
                              alt,
                              style: Theme.of(context).textTheme.caption,
                            )
                        ],
                      ),
                    );
                  },
                  extensionSet: md.ExtensionSet.gitHubWeb,
                ),
              ),
            )
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
              child: Text('Report article view')),
          OutlineButton(
              onPressed: () {
                Navigator.of(context).popAndPushNamed(
                  '/read',
                  arguments: this.path,
                );
              },
              child: Text('Retry'))
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
