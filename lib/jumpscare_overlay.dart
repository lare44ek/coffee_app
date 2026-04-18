// lib/jumpscare_overlay.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // Импортируем video_player

class JumpscareOverlay extends StatefulWidget {
  final VoidCallback? onDismiss; // Callback на случай, если нужно выполнить код при закрытии

  const JumpscareOverlay({super.key, this.onDismiss});

  @override
  State<JumpscareOverlay> createState() => _JumpscareOverlayState();
}

class _JumpscareOverlayState extends State<JumpscareOverlay> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллер с ассетом видео
    _controller = VideoPlayerController.asset('assets/videos/foxy.mp4')
      ..initialize().then((_) {
        // После инициализации (загрузки метаданных)
        setState(() {});
        // Начинаем воспроизведение
        _controller.play();
      });

    // Добавляем слушатель, чтобы отследить конец воспроизведения
    _controller.addListener(_onVideoEnd);
  }

  // Этот метод будет вызван при каждом обновлении состояния контроллера
  void _onVideoEnd() {
    // Проверяем, достигло ли видео конца
    if (_controller.value.isPlaying == false && _controller.value.isInitialized) {
      // Если видео остановилось и инициализировано, значит, оно закончилось (или было остановлено вручную)
      // Проверим, действительно ли позиция в конце (это более надёжный способ)
      if (_controller.value.position >= _controller.value.duration) {
        // Видео закончилось, закрываем диалог
        _closeOverlay();
      }
    }
  }

  void _closeOverlay() {
    if (mounted) { // Проверяем, что виджет всё ещё в дереве
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      } else {
        Navigator.of(context).pop(); // Закрывает showDialog
      }
    }
  }

  @override
  void dispose() {
    // Обязательно dispose контроллера, чтобы освободить ресурсы
    _controller.removeListener(_onVideoEnd); // Убираем слушатель перед dispose
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope( // Защита от случайного закрытия бэк-кнопкой
      onWillPop: () async => false, // Запрещаем навигацию назад
      child: Stack(
        children: [
          // Полупрозрачный чёрный фон
          Container(
            color: Colors.black.withOpacity(0.95),
          ),
          // Центрированное видео
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(), // Показываем индикатор загрузки, пока видео инициализируется
          ),
        ],
      ),
    );
  }
}