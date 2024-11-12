// import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

import 'package:logging/logging.dart';

// ロガーのインスタンスを作成
final logger = Logger('MyAppLogger');

// void main() => runApp(MyApp());

void main() {
  // ログレベルを設定
  Logger.root.level = Level.ALL;  // 出力するログのレベルを設定

  // ログの出力形式を設定
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // ログを出力
  final logger = Logger('MyAppLogger');
  logger.info('App started');

  // アプリの起動
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TimerPage(),
    );
  }
}

class TimerPage extends StatefulWidget {
  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Duration _duration = Duration(hours: 0, minutes: 0, seconds: 0);
  Timer? _timer;

  // late Timer _timer;
  late AudioPlayer _audioPlayer;
  // int _seconds = 0;
  bool _isRunning = false;

  // SEを鳴らす時間の選択肢とデフォルトの設定
  int _selectedPlayDuration = 3; // デフォルトは3分

  @override
  void initState() {
    super.initState();
    final _audioPlayer = AudioPlayer();
    // _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playClickSound() async {
    try {
      int playDuration = _selectedPlayDuration * 60; // 秒単位に変換
      int elapsed = 0;

      await _audioPlayer.play(AssetSource('sounds/se.mp3'));
      await Future.delayed(Duration(seconds: 3)); // 再生が終わるまで待機
      while (elapsed < playDuration) {
        _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play(AssetSource('sounds/se.mp3'));
        await Future.delayed(Duration(seconds: 3)); // 再生が終わるまで待機
        elapsed += 3;
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_duration.inSeconds > 0) {
          _duration -= Duration(seconds: 1);
          _isRunning = true;
        } else {
          _timer!.cancel();
          if (_isRunning != false) {
            _playClickSound(); // タイマーがゼロになったらアラームを再生
          }
        }
      });
    });
  }

  void _showTimePicker() {
    Duration tempDuration = _duration; // 選択された時間を一時保存
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // キャンセルボタン
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text('キャンセル'),
                  ),
                  // タイトル
                  Center(
                    child: Text(
                      'タイマー設定',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // OKボタン
                  ElevatedButton(
                    onPressed: () {
                      if (tempDuration.inHours < 0 ||
                          tempDuration.inMinutes < 0 ||
                          tempDuration.inSeconds < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            // content: Text('不正な値が設定されました'),
                            content: Text('Value: ${tempDuration.inMinutes}'),
                          ),
                        );
                      } else {
                        setState(() {
                          _duration = tempDuration;
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text('OK'),
                  ),
                ],
              ),
            ),
            Divider(),
            // ダイアル
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width, // 画面いっぱいの幅
                height: MediaQuery.of(context).size.height * 0.5, // 画面高さの50%を指定
                child: CupertinoTimerPicker(
                  initialTimerDuration: _duration,
                  mode: CupertinoTimerPickerMode.hms,
                  onTimerDurationChanged: (Duration newDuration) {
                    tempDuration = newDuration;
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _stopTimer() {
    //TODO

    // if (_timer != null) {
    //   _timer!.cancel();
    // }
    // _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    //   setState(() {
    //     if (_duration.inSeconds > 0) {
    //       _duration -= Duration(seconds: 1);
    //     } else {
    //       _timer!.cancel();
    //     }
    //   });
    // });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // 画面に合わせたフォントサイズ
    // タイトル
    double fontSize_title = MediaQuery.of(context).size.width * 0.15;
    // タイマー
    double fontSize_timer = MediaQuery.of(context).size.width * 0.25;
    // ボタン
    double fontSize_timer_button = MediaQuery.of(context).size.width * 0.10;
    // 画面に合わせた配置
    // ボタン幅と高さ
    double widthsize_button = MediaQuery.of(context).size.width * 0.75;
    // double heightsize_button = MediaQuery.of(context).size.height * 0.10;
    // ボタン配置
    // double widthsize_button_position = MediaQuery.of(context).size.width * 0.75;
    double heightsize_button_position = MediaQuery.of(context).size.height * 0.025;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Center(child: SizedBox(child: Text(
              'タイマー',
              style: TextStyle(fontSize: fontSize_title),  // 画面幅に基づいたフォントサイズ
              ))),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _formatDuration(_duration),
              style: TextStyle(fontSize: fontSize_timer),
            ),
            SizedBox(
              // width: widthsize_button,
              // height: heightsize_button,
              ),
            ElevatedButton(
              onPressed: _showTimePicker,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // 角丸の半径
                ),
                padding: EdgeInsets.all(3.0), // ボタン全体の余白を設定
              ),
              child: SizedBox(
                width: widthsize_button,
                // height: heightsize_button,
                child: Center(
                  child: Text(
                    '時間を設定',
                    style: TextStyle(fontSize: fontSize_timer_button), // 画面幅に基づいたフォントサイズ
                  ),
                ),
              ),
            ),

            SizedBox(
              width: widthsize_button,
              height: heightsize_button_position,
              ),
            ElevatedButton(
              onPressed: _startTimer,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // 角丸の半径
                ),
                padding: EdgeInsets.all(3.0), // ボタン全体の余白を設定
              ),
              child: SizedBox(
                width: widthsize_button,
                // height: heightsize_button,
                child: Center(
                  child: Text(
                    'タイマー開始',
                    style: TextStyle(fontSize: fontSize_timer_button), // 画面幅に基づいたフォントサイズ
                  ),
                ),
              ),
            ),

            SizedBox(
              width: widthsize_button,
              height: heightsize_button_position * 4,
              ),
            ElevatedButton(
              onPressed: _stopTimer,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // 角丸の半径
                ),
                padding: EdgeInsets.all(3.0), // ボタン全体の余白を設定
              ),
              child: SizedBox(
                width: widthsize_button,
                // height: heightsize_button,
                child: Center(
                  child: Text(
                    'タイマー停止',
                    style: TextStyle(fontSize: fontSize_timer_button), // 画面幅に基づいたフォントサイズ
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // SE再生時間の選択UI
            Text("アラーム再生時間を選択", style: TextStyle(fontSize: 18)),
            DropdownButton<int>(
              value: _selectedPlayDuration,
              items: [1, 3, 5, 10].map((value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text("$value 分"),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedPlayDuration = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
        // ),
        //     SizedBox(height: 20),
        //     // SE再生時間の選択UI
        //     Text("アラーム再生時間を選択", style: TextStyle(fontSize: 18)),
        //     DropdownButton<int>(
        //       value: _selectedPlayDuration,
        //       items: [1, 3, 5, 10].map((value) {
        //         return DropdownMenuItem<int>(
        //           value: value,
        //           child: Text("$value 分"),
        //         );
        //       }).toList(),
        //       onChanged: (newValue) {
        //         setState(() {
        //           _selectedPlayDuration = newValue!;
        //         });
        //       },
  }
}
