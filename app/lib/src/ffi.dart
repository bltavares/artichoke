import 'dart:ffi' as ffi; // For FFI
import 'dart:io'; // For Platform.isX
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';
import 'package:toml/decoder.dart';

ffi.DynamicLibrary _loadLib() {
  if (Platform.isIOS) return ffi.DynamicLibrary.process();
  if (Platform.isAndroid) return ffi.DynamicLibrary.open("libartichoke_ffi.so");

  final processLocation = path.split(Platform.resolvedExecutable);
  processLocation.removeLast();

  if (Platform.isLinux) processLocation.add("libartichoke_ffi.so");
  if (Platform.isMacOS) processLocation.add("libartichoke_ffi.dylib");
  if (Platform.isWindows) processLocation.add("artichoke_ffi.dll");
  return ffi.DynamicLibrary.open(path.joinAll(processLocation));
}

final _artichokeLib = _loadLib();

typedef _ArtichokeDownload = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>);
final _artichokeDonwload =
    _artichokeLib.lookupFunction<_ArtichokeDownload, _ArtichokeDownload>(
        'artichoke_download_and_parse');

final _artichokeFreeString = _artichokeLib.lookupFunction<
    ffi.Void Function(ffi.Pointer<Utf8>),
    void Function(ffi.Pointer<Utf8>)>('artichoke_free_string');

String _ffiDownload(String path) {
  final donwloadPath = Utf8.toUtf8(path);
  final content = _artichokeDonwload(donwloadPath);
  if (content == ffi.nullptr) {
    return null;
  }
  final r = Utf8.fromUtf8(content);
  _artichokeFreeString(content);
  return r;
}

class Article {
  final Map<String, dynamic> metadata;
  final String content;

  Article({this.metadata, @required this.content});

  factory Article.download(String path) {
    final content = _ffiDownload(path);
    return Article.parse(content);
  }

  factory Article.parse(String content) {
    if (content == null) {
      return null;
    }

    if (!content.startsWith('+++')) {
      return Article(content: content, metadata: null);
    }

    final closeIndex = content.indexOf('\n+++');
    final metadata = content.substring(3, closeIndex);
    final parser = new TomlParser();
    final parsed = parser.parse(metadata).value;

    return Article(
      metadata: parsed,
      content: content.substring(closeIndex + 4),
    );
  }
}
