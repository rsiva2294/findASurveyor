
extension StringCasingExtension on String {
  String toTitleCaseExt() {
    // Return an empty string if the input is empty to avoid errors.
    if (this.trim().isEmpty) {
      return "";
    }

    // Split the string by spaces, map over each word to capitalize it,
    // and then join them back together with a single space.
    return this.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }
}