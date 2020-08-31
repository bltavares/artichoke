import 'dart:ffi' as ffi; // For FFI
import 'dart:io'; // For Platform.isX
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';

ffi.DynamicLibrary _loadLib() {
  final processLocation = path.split(Platform.resolvedExecutable);
  processLocation.removeLast();

  if (Platform.isIOS) return ffi.DynamicLibrary.process();
  if (Platform.isLinux) processLocation.add("libartichoke_ffi.so");
  if (Platform.isMacOS) processLocation.add('libartichoke_ffi.dylib');
  if (Platform.isWindows) processLocation.add('artichoke_ffi.dll');
  return ffi.DynamicLibrary.open(path.joinAll(processLocation));
}

final _artichokeLib = _loadLib();

typedef _ArtichokeDownload = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>);
final _ArtichokeDownload _artichokeDonwload = _artichokeLib
    .lookup<ffi.NativeFunction<_ArtichokeDownload>>(
      'artichoke_download_and_parse',
    )
    .asFunction();

String download(String path) {
  final donwloadPath = Utf8.toUtf8(path);
  final content = _artichokeDonwload(donwloadPath);
  if (content == ffi.nullptr) {
    return null;
  }
  return Utf8.fromUtf8(content);
}
