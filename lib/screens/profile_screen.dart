// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_providers.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../login_page.dart';
import 'tracker_screen.dart';

/// Идёт ли сейчас загрузка аватарки — для индикатора поверх аватара.
final _avatarUploadingProvider = StateProvider<bool>((ref) => false);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('display_name');
    await prefs.remove('avatar_url');
    ref.read(currentUserProvider.notifier).state = null;
    ref.read(displayNameProvider.notifier).state = null;
    ref.read(avatarUrlProvider.notifier).state = null;
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final login   = ref.read(currentUserProvider);
    final current = ref.read(displayNameProvider) ?? '';
    if (login == null) return;

    final ctrl = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить имя'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Фамилия Имя',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == current) return;

    try {
      final saved = await ApiService.updateDisplayName(login, newName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('display_name', saved);
      ref.read(displayNameProvider.notifier).state = saved;
    } on DioException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить имя')),
        );
      }
    }
  }

  /// Показывает выбор источника (галерея/камера) и грузит выбранное фото.
  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Выбрать из галереи',
                  style: TextStyle(color: AppTheme.onCard(ctx))),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Сделать фото',
                  style: TextStyle(color: AppTheme.onCard(ctx))),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final login = ref.read(currentUserProvider);
    if (login == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    ref.read(_avatarUploadingProvider.notifier).state = true;
    try {
      final url = await ApiService.uploadAvatar(login, picked.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar_url', url);
      ref.read(avatarUrlProvider.notifier).state = url;
      // Сбрасываем кэш картинки на случай повторной загрузки.
      if (context.mounted) {
        await NetworkImage(url).evict();
      }
    } on DioException catch (e) {
      // Показываем причину от сервера, если она есть (напр. слишком большой файл).
      final serverMsg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      final msg = serverMsg == 'file too large (max 15MB)'
          ? 'Файл слишком большой (макс. 15 МБ)'
          : 'Не удалось загрузить фото';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      ref.read(_avatarUploadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final login       = ref.watch(currentUserProvider) ?? '';
    final displayName = ref.watch(displayNameProvider) ?? login;
    final avatarUrl   = ref.watch(avatarUrlProvider);
    final uploading   = ref.watch(_avatarUploadingProvider);
    final isDark      = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: const AppHeader(title: 'Профиль'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: uploading ? null : () => _changeAvatar(context, ref),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: uploading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : (avatarUrl == null
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null),
                  ),
                  // Бейдж камеры в углу — подсказывает, что можно сменить фото.
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppTheme.bg(context), width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onCard(context),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _editName(context, ref),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.primary,
                  tooltip: 'Изменить имя',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '@$login',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 40),

            // Переключатель темы
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: SwitchListTile(
                title: Text(
                  isDark ? 'Тёмная тема' : 'Светлая тема',
                  style: TextStyle(
                    color: AppTheme.onCard(context),
                    fontSize: 16,
                  ),
                ),
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: AppColors.primary,
                ),
                value: isDark,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withAlpha(120),
                onChanged: (_) =>
                    ref.read(themeModeProvider.notifier).toggle(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrackerScreen()),
                ),
                icon: const Icon(Icons.travel_explore, color: AppColors.primary),
                label: const Text(
                  'Бурмалда',
                  style: TextStyle(color: AppColors.primary, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(Icons.logout, color: AppColors.warning),
                label: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(color: AppColors.warning, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.warning),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
