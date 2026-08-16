void downloadFileWeb(
  List<int> bytes,
  String filename, {
  String mimeType = 'application/octet-stream',
}) {
  // No-op on non-web platforms where saving is handled via SharePlus or temporary file.
}
