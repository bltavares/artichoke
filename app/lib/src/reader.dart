import 'package:artichoke/src/multilinks.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import './ffi.dart';

class ArticleView extends StatefulWidget {
  const ArticleView({
    Key key,
    @required this.url,
    @required this.article,
  }) : super(key: key);

  final String url;
  final Article article;

  @override
  _ArticleViewState createState() => _ArticleViewState();
}

class _ArticleViewState extends State<ArticleView> {
  ScrollController controller;
  MarkdownStyleSheet styleSheet;

  @override
  void initState() {
    super.initState();
    controller = new ScrollController();
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    styleSheet = stylesheetTheme();
  }

  MarkdownStyleSheet stylesheetTheme() {
    final theme = Theme.of(context);
    final readTheme = theme.copyWith(
      textTheme: theme.textTheme.apply(fontSizeFactor: 1.5),
    );
    return MarkdownStyleSheet.fromTheme(readTheme).copyWith(
        blockquoteDecoration: BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(2.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
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
                    Share.share(widget.url);
                  }),
              IconButton(
                  icon: Icon(Icons.open_in_browser),
                  onPressed: () {
                    url_launcher.launch(widget.url);
                  }),
              IconButton(
                  icon: Icon(Icons.book),
                  onPressed: () async {
                    final links = await compute(
                      extractLinks,
                      widget.article.content,
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
                    this.widget.article.metadata['title'],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline3,
                  ),
                  Text(
                    "${this.widget.article.metadata['word_count']} words",
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Markdown(
              controller: controller,
              shrinkWrap: true,
              selectable: true,
              styleSheet: styleSheet,
              data: this.widget.article.content,
              onTapLink: (link) {
                if (link.startsWith("https://") || link.startsWith("http://")) {
                  Navigator.of(context).pushReplacementNamed(
                    '/read',
                    arguments: link,
                  );
                }
              },
              imageBuilder: (uri, title, alt) {
                if (!uri.hasScheme) {
                  uri = Uri.parse("https:$uri");
                }
                return Center(
                  child: Column(
                    children: [
                      CachedNetworkImage(
                        imageUrl: uri.toString(),
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) =>
                                CircularProgressIndicator(
                                    value: downloadProgress.progress),
                        errorWidget: (context, url, error) => Icon(Icons.error),
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
          )
        ],
      ),
    );
  }
}

class LoadingArticleView extends StatelessWidget {
  const LoadingArticleView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
    final url = ModalRoute.of(context).settings.arguments;
    return FutureBuilder(
      future: download(url).timeout(Duration(seconds: 10)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return LoadingArticleView();
        }

        if (snapshot.data == null || snapshot.hasError) {
          return ArticleViewFailed(path: url);
        }

        return ArticleView(
          url: url,
          article: snapshot.data,
        );
      },
    );
  }
}
