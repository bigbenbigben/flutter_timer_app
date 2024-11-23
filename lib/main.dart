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
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // ログを出力
  // final logger = Logger('MyAppLogger');
  logger.info('App started');

  // アプリの起動
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // super.key を直接書くだけ！
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TimerPage(),
    );
  }
}

// タイマー画面を管理、状態管理が必要
class TimerPage extends StatefulWidget {
  const TimerPage({super.key}); // super.key を直接書くだけ！
  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Duration _duration = const Duration(hours: 0, minutes: 0, seconds: 0);
  Duration _setDuration = const Duration(hours: 0, minutes: 0, seconds: 0);
  Timer? _timer;

  final int _selectedPlayDuration = 3; // SEを鳴らす時間、デフォルトは3分

  // 各種状態切替
  bool _isRunning = false;
  bool _isPause = false;
  bool _isAlarm = false;

  late AudioPlayer _audioPlayer;  // SE再生用

// 初期化処理
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
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
      while (elapsed < playDuration) {
        _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play(AssetSource('sounds/se.mp3'));
        await Future.delayed(const Duration(seconds: 3)); // 再生が終わるまで待機
        if (!_isRunning) break;
        elapsed += 3;
      }
      await _audioPlayer.stop(); // 最終的に完全停止
    } catch (e) {
      logger.info('Error playing audio: $e');
    }
  }

// アラーム音の停止
  Future<void> stopAlarmSound() async {
    await _audioPlayer.stop();
    setState(() {
      _isAlarm = false;
    });

  }

// タイマーの開始と停止
  void _startTimer() {
    if (_timer == null || !_timer!.isActive) {
      // _isPause = false;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        logger.info('Timer started');
        _isPause = false;
        setState(() {
          if (_duration.inSeconds > 0) {
            _duration -= const Duration(seconds: 1);
            _isRunning = true;
          } else {
            logger.info('Timer paused');
            _timer!.cancel();
            if (_isRunning != false) {
              logger.info('Alarm started');
              _isAlarm = true;
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
      logger.info('Timer paused');
    }
  }

// タイマー設定のUI
  void _showTimePicker() {
    Duration tempDuration = _setDuration; // 選択した時間を一時保存
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text('キャンセル'),
                  ),
                  // タイトル
                  const Center(
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
                            content: Text('Value: ${_setDuration.inMinutes}'),
                          ),
                        );
                      } else {
                        setState(() {
                            logger.info('Setting Duration');
                          _duration = tempDuration;
                          _setDuration = tempDuration;
                          if (_duration.inSeconds > 0) _isPause = true;
                          });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
            const Divider(),
            // ダイアル
            Expanded(
              child: SizedBox(
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
      logger.info('Resetted timer');
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
    // 画面幅によって変わる要素
    double screenWidth = MediaQuery.of(context).size.width; // 画面幅
    double timerFontSize = screenWidth * 0.20;              // タイマーの数字のフォントサイズ
    double buttonIconSize = screenWidth * 0.15;             // ボタン
    double buttonSpacing = screenWidth * 0.05;              // ボタンの間隔

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _formatDuration(_duration),
              style: TextStyle(fontSize: timerFontSize),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 設定ボタン
                IconButton(
                  onPressed: _timer?.isActive != true && !_isAlarm ? _showTimePicker : null,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 角丸の半径
                    ),
                    padding: const EdgeInsets.all(3.0), // ボタン全体の余白を設定
                  ),
                  icon: const Icon(Icons.access_alarms),
                  iconSize: buttonIconSize,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: buttonSpacing),
                // 再生／一時停止ボタン
                IconButton(
                  onPressed: (_duration.inSeconds > 0) ? _startTimer : null,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 角丸の半径
                    ),
                    padding: const EdgeInsets.all(3.0), // ボタン全体の余白を設定
                  ),
                  icon: Icon(!_isPause ? Icons.pause : Icons.play_arrow),
                  iconSize: buttonIconSize,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: buttonSpacing),
                // 停止／リセットボタン
                IconButton(
                  onPressed: _isAlarm || ((_duration.inSeconds > 0) && _isPause)  ? _resetTimer : null,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 角丸の半径
                    ),
                    padding: const EdgeInsets.all(3.0), // ボタン全体の余白を設定
                  ),
                  icon: Icon(_isPause || (_duration.inSeconds > 0) ? Icons.refresh : Icons.stop),
                  iconSize: buttonIconSize,
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
