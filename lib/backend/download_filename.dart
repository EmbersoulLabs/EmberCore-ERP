/// Makes a download name safe on Android/iOS/Windows.
String sanitizeDownloadFilename(String filename) {
  var name = filename.trim();
  if (name.isEmpty) {
    return 'download';
  }
  name = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
  name = name.replaceAll(RegExp(r'_+'), '_');
  name = name.replaceAll(RegExp(r'^[. ]+|[. ]+$'), '');
  return name.isEmpty ? 'download' : name;
}

/// file_saver Android plugin returns error text via success instead of throwing.
bool isFileSaverFailurePath(String? path) {
  if (path == null || path.trim().isEmpty) {
    return true;
  }
  final lower = path.toLowerCase();
  return lower.startsWith('error') ||
      lower.contains('something went wrong') ||
      lower.contains('the path was found null');
}
