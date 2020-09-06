import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'multilinks.dart';
import 'ffi.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<List<ExtractedLink>>(
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'report') {
                    url_launcher.launch(
                        'https://docs.google.com/forms/d/e/1FAIpQLSdxzXRozr9qafH_P_FrhSv-ICaVJ3cAKmWpl51ShrYrq4aaJg/viewform');
                    return;
                  }
                  if (value == 'about') {
                    showAboutDialog(
                        context: context,
                        applicationIcon: Icon(Icons.article_outlined),
                        children: [
                          SelectableText(
                            'Website',
                            style:
                                Theme.of(context).textTheme.bodyText1.copyWith(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                            onTap: () {
                              url_launcher.launch(
                                  'https://github.com/bltavares/artichoke');
                            },
                          )
                        ]);
                    return;
                  }
                },
                icon: Icon(Icons.menu),
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      value: 'report',
                      child: Text('Report article view error'),
                    ),
                    PopupMenuItem(
                      value: 'about',
                      child: Text('About'),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: Builder(builder: (context) {
            if (value.length == 1) {
              Future.microtask(
                () => Navigator.of(context)
                    .pushNamed('/read', arguments: value.first.url),
              );
            }

            if (value.length > 1) {
              multilinkExtract(context, value);
            }

            return FindUrl(
              sharedContent: value.isEmpty ? null : value.first.url,
            );
          }),
        );
      },
    );
  }
}

class FindUrl extends StatefulWidget {
  final String sharedContent;

  const FindUrl({
    Key key,
    @required this.sharedContent,
  }) : super(key: key);

  @override
  _FindUrlState createState() => _FindUrlState();
}

class _FindUrlState extends State<FindUrl> {
  String path;
  TextEditingController controller = TextEditingController();

  _FindUrlState();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.text = widget.sharedContent;
    path = widget.sharedContent;
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Icon(Icons.article_outlined),
                Container(height: 16),
                Text(
                  'Artichoke',
                  style: Theme.of(context).textTheme.headline5,
                ),
                Container(height: 8),
                Text(
                  'The article viewer',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ],
            ),
            Column(
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
                Container(height: 24),
                OutlineButton.icon(
                  onPressed: () {
                    submit(null);
                  },
                  padding: EdgeInsets.symmetric(
                    horizontal: 35.0,
                    vertical: 12,
                  ),
                  label: Text('Read article'),
                  icon: Icon(Icons.chrome_reader_mode),
                ),
                Container(
                  height: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
