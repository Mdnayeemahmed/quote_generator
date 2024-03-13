
class QuranVerse {
  final String text;
  final String surahName;
  final String ayat;

  QuranVerse({required this.text, required this.surahName, required this.ayat});

  factory QuranVerse.fromMap(Map<String, dynamic> map) {
    return QuranVerse(
      text: map['text'] ?? '',
      surahName: map['surahName'] ?? '',
      ayat: map['ayat'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'surahName': surahName,
      'ayat': ayat,
    };
  }
}
