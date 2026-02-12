import 'dart:typed_data';
import 'dart:ui' as ui;

Future<Uint8List> imageToBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
