import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recorder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Recorder Homepage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final recorder = FlutterSoundRecorder();
  bool isRecorderReady = false;
  String _fileName = 'recording';
  String _fileExtension = 'aac';
  String _directoryPath = '/storage/emulated/0/data/sound_recorder';

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }

  Future initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw "Microphone permission not granted";
    }

    await recorder.openRecorder();
    isRecorderReady = true;
    recorder.setSubscriptionDuration(
      const Duration(milliseconds: 500),
    );
  }

  Future record() async {
    if (!isRecorderReady) return;
    await recorder.startRecorder(toFile: _fileName);
  }

  Future stop() async {
    if (!isRecorderReady) return;
    final path = await recorder.stopRecorder();
    final audioFile = File(path!);
    Uint8List bytes = await audioFile.readAsBytes();
    _writeFileToStorage(bytes);
  }

  String _generateFileName(timestamp) {
    return "$_fileName$timestamp.$_fileExtension";
  }

  // File saving
  void _createFile(bytes) async {
    // Timestamp
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String datetime = tsdate.year.toString() +
        "-" +
        tsdate.month.toString() +
        "-" +
        tsdate.day.toString() +
        "-" +
        tsdate.hour.toString() +
        "-" +
        tsdate.minute.toString() +
        "-" +
        tsdate.second.toString();
    String _completeFileName = _generateFileName(datetime);

    File(_directoryPath + '/' + _completeFileName)
        .create(recursive: true)
        .then((File file) async {
      file.writeAsBytes(bytes);
      print(file.path);
    });
  }

  void _createDirectory() async {
    bool isDirectoryCreated = await Directory(_directoryPath).exists();
    if (!isDirectoryCreated) {
      Directory(_directoryPath).create().then((Directory directory) {});
    }
  }

  void _writeFileToStorage(bytes) async {
    // permission for file
    final status = await Permission.storage.request();
    if (status != PermissionStatus.granted) {
      throw "Not granted Permission for storage";
    }
    _createDirectory();
    _createFile(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      StreamBuilder<RecordingDisposition>(
        stream: recorder.onProgress,
        builder: (context, snapshot) {
          final duration =
              snapshot.hasData ? snapshot.data!.duration : Duration.zero;
          return Text("${duration.inSeconds} s");
        },
      ),
      const SizedBox(height: 32),
      ElevatedButton(
        child: Icon(
          recorder.isRecording ? Icons.stop : Icons.mic,
          size: 80,
        ),
        onPressed: () async {
          if (recorder.isRecording) {
            await stop();
          } else {
            await record();
          }

          setState(() {});
        },
      ),
    ])));
  }
}
