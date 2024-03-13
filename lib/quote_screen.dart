import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quote_generator/quran_verse.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({Key? key}) : super(key: key);

  @override
  _QuoteScreenState createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  bool _isFetching = false;

  Future<void> _fetchAndSaveVerse() async{
    setState(() {
      _isFetching = true; // Start fetching and saving process
    });

    try {
      int randomVerseNumber = Random().nextInt(6237) + 1;
      String apiUrl =
          'http://api.alquran.cloud/ayah/$randomVerseNumber/editions/quran-uthmani,en.pickthall';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        String text = responseData['data'][1]['text'];
        String surahName = responseData['data'][1]['surah']['englishName'];
        String ayat = responseData['data'][1]['number'].toString();

        QuranVerse verse =
            QuranVerse(text: text, surahName: surahName, ayat: ayat);

        // Save the verse to Firestore
        await FirebaseFirestore.instance
            .collection('quran_verses')
            .add(verse.toMap());
      } else {
        throw Exception('Failed to fetch verse');
      }
    } catch (error) {
      print('Error: $error');
    } finally {
      setState(() {
        _isFetching = false; // Finish fetching and saving process
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Verse Generator'),
        backgroundColor: Colors.greenAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('quran_verses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return GestureDetector(
                onLongPress: () {
                  _copyToClipboard(document['text']);
                },
                child: Card(
                  color: Colors.greenAccent,
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document['text'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Surah: ${document['surahName']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Ayat: ${document['ayat']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isFetching ? null : _fetchAndSaveVerse,
        // Disable button when fetching is in progress
        backgroundColor: Colors.greenAccent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.refresh),
            if (_isFetching)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
