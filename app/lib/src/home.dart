import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkify/linkify.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<List<LinkableElement>>(
      builder: (context, value, child) {
        if (value.length == 1) {
          Future.microtask(
            () => Navigator.of(context)
                .pushNamed('/read', arguments: value.first.url),
          );
        }
        return Scaffold(
          body: FindUrl(sharedContent: value.isEmpty ? null : value.first.url),
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
