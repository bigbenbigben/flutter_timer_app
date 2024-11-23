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

// タイマー画面を管理、状態管理が必要
class TimerPage extends StatefulWidget {
  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Duration _duration = const Duration(hours: 0, minutes: 0, seconds: 0);
  Duration _setDuration = const Duration(hours: 0, minutes: 0, seconds: 0);
  Timer? _timer;

  // late Timer _timer;
  late AudioPlayer _audioPlayer;
  // int _seconds = 0;
  bool _isRunning = false;
  bool _isPause = false;

  // SEを鳴らす時間の選択肢とデフォルトの設定
  int _selectedPlayDuration = 3; // デフォルトは3分

// 初期化処理
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    // _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

// アラーム音の再生
  Future<void> playAlarmSound() async {
    try {
      int playDuration = _selectedPlayDuration * 60; // 秒単位に変換
      int elapsed = 0;

      await _audioPlayer.play(AssetSource('sounds/se.mp3'));
      await Future.delayed(Duration(seconds: 3)); // 再生が終わるまで待機
      while (elapsed < playDuration) {
        _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play(AssetSource('sounds/se.mp3'));
        await Future.delayed(Duration(seconds: 3)); // 再生が終わるまで待機
        if (!_isRunning) break;
        elapsed += 3;
      }
      await _audioPlayer.stop(); // 最終的に完全停止
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

// アラーム音の停止
  Future<void> stopAlarmSound() async {
    await _audioPlayer.stop();

  }

// タイマーの開始と停止
  void _startTimer() {
    if (_timer == null || !_timer!.isActive) {
      // _isPause = false;
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        logger.info('Timer start');
         _isPause = false;
        setState(() {
          if (_duration.inSeconds > 0) {
            _duration -= Duration(seconds: 1);
            _isRunning = true;
          } else {
            logger.info('Timer paused');
            _timer!.cancel();
            if (_isRunning != false) {
              logger.info('Alarm started');
              playAlarmSound(); // タイマーがゼロになったらアラームを再生
            }
            else {
              logger.info('Alarm stopped');
              stopAlarmSound();
            }
          }
        });
      });
    }
    else {
      _timer!.cancel();
      setState(() {
        _isPause = true;
      });
      logger.info('time pause');
    }
  }

// タイマー設定のUI
  void _showTimePicker() {
    Duration tempDuration = _setDuration; // 選択した時間を一時保存
    // tempDuration = _duration;
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
                      if (_setDuration.inHours < 0 ||
                          _setDuration.inMinutes < 0 ||
                          _setDuration.inSeconds < 0) {
                        _setDuration = const Duration(hours: 0, minutes: 0, seconds: 0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            // content: Text('不正な値が設定されました'),
                            content: Text('Value: ${_setDuration.inMinutes}'),
                          ),
                        );
                      } else {
                        // if (_isRunning != true){
                        setState(() {
                            logger.info('Duration set');
                          _duration = tempDuration;
                          _setDuration = tempDuration;
                          if (_duration.inSeconds > 0)
                            _isPause = true;
                          });
                        // }
                        // else if (_timer == null || !_timer!.isActive) {
                        //   setState(() {
                        //     logger.info('Duration check');
                        //     logger.info('Duration: ${_duration.inHours} hours, ${_duration.inMinutes % 60} minutes, ${_duration.inSeconds % 60} seconds');
                        //     _duration = tempDuration;
                        //     _setDuration = tempDuration;
                        //   });
                        // } else {
                        //   setState(() {
                        //     logger.info('Duration active');
                        //     _duration = tempDuration;
                        //     _setDuration = tempDuration;
                        //   });
                        // }
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
                  initialTimerDuration: _setDuration,
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

  void _resetTimer() {
    if (_timer != null && !_timer!.isActive) {
      _timer!.cancel(); // タイマーをキャンセル
      stopAlarmSound();
      logger.info('reset timer');
      setState(() {
        _duration = Duration.zero; // 残り時間をゼロにリセット
        _isRunning = false; // タイマーが動いていない状態にリセット
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

// UIレイアウト
  @override
  Widget build(BuildContext context) {
    // 画面に合わせたフォントサイズ
    // タイトル
    double fontSize_title = MediaQuery.of(context).size.width * 0.15;
    // タイマー
    double fontSize_timer = MediaQuery.of(context).size.width * 0.20;
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _formatDuration(_duration),
              style: TextStyle(fontSize: fontSize_timer),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 設定ボタン
                IconButton(
                  onPressed: _showTimePicker,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 角丸の半径
                    ),
                    padding: EdgeInsets.all(3.0), // ボタン全体の余白を設定
                  ),
                  icon: Icon(Icons.access_alarms),
                  iconSize: 48.0,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 30),
                // 再生／一時停止ボタン
                IconButton(
                  onPressed: (_duration.inSeconds > 0) ? _startTimer : null,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 角丸の半径
                    ),
                    padding: EdgeInsets.all(3.0), // ボタン全体の余白を設定
                  ),
                  icon: Icon(!_isPause ? Icons.pause : Icons.play_arrow),
                  iconSize: 48.0,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 30),
                // 停止／リセットボタン
                IconButton(
                  onPressed: _resetTimer,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 角丸の半径
                    ),
                    padding: EdgeInsets.all(3.0), // ボタン全体の余白を設定
                  ),
                  icon: Icon(_isPause || (_duration.inSeconds > 0) ? Icons.refresh : Icons.stop),
                  iconSize: 48.0,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
