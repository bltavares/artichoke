import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'ffi.dart';

void multilinkExtract(BuildContext context, List<ExtractedLink> links) {
  Future.microtask(() => {
        showModalBottomSheet(
            isScrollControlled: true,
            enableDrag: true,
            isDismissible: true,
            context: context,
            builder: (context) => MultiLinkView(links: links))
      });
}

class MultiLinkView extends StatelessWidget {
  final List<ExtractedLink> links;

  const MultiLinkView({
    Key key,
    @required this.links,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (builder, controller) => ListView.separated(
        controller: controller,
        itemBuilder: (BuildContext context, int index) {
          final itemUrl = links[index].url;

          return ListTile(
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () {
                      Share.share(itemUrl);
                    }),
                IconButton(
                    icon: Icon(Icons.open_in_browser),
                    onPressed: () {
                      url_launcher.launch(itemUrl);
                    }),
                IconButton(
                    icon: Icon(Icons.article_outlined),
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed('/read', arguments: itemUrl);
                    }),
              ],
            ),
            title: Text(itemUrl),
          );
        },
        itemCount: links.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider();
        },
      ),
    );
  }
}
