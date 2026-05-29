// lib/screens/notes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  bool _creating = false;
  final _createCtrl = TextEditingController();

  @override
  void dispose() {
    _createCtrl.dispose();
    super.dispose();
  }

  void _startCreate() => setState(() {
        _creating = true;
        _createCtrl.clear();
      });

  void _cancelCreate() => setState(() {
        _creating = false;
        _createCtrl.clear();
      });

  void _confirmCreate() {
    final text = _createCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(displayNameProvider) ??
        ref.read(currentUserProvider) ??
        'Гость';
    ref.read(notesProvider.notifier).add(
          Note(
            id: 'note_${DateTime.now().millisecondsSinceEpoch}',
            authorName: user,
            text: text,
            createdAt: DateTime.now(),
            // Своя заметка — сразу подставляем свою аватарку.
            authorAvatarUrl: ref.read(avatarUrlProvider),
          ),
        );
    setState(() {
      _creating = false;
      _createCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: const AppHeader(title: 'Заметки'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Форма создания новой заметки — появляется вверху.
          if (_creating) ...[
            _NewNoteCard(
              controller: _createCtrl,
              onConfirm: _confirmCreate,
              onCancel: _cancelCreate,
            ),
            const SizedBox(height: 12),
          ],

          if (notes.isEmpty && !_creating)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Text(
                'Заметок пока нет.\nНажмите + чтобы добавить.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),

          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NoteCard(note: note),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notesFab',
        onPressed: _startCreate,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Карточка для ввода новой заметки
// ---------------------------------------------------------------------------

class _NewNoteCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _NewNoteCard({
    required this.controller,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Напишите заметку для смены...',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text(
                  'Отмена',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Добавить'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Карточка существующей заметки
// ---------------------------------------------------------------------------

class _NoteCard extends ConsumerStatefulWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  ConsumerState<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<_NoteCard> {
  bool _editing = false;
  late final TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.note.text);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final text = _editCtrl.text.trim();
    if (text.isEmpty) return;
    ref
        .read(notesProvider.notifier)
        .update(widget.note.copyWith(text: text));
    setState(() => _editing = false);
  }

  void _delete() =>
      ref.read(notesProvider.notifier).remove(widget.note.id);

  /// Стабильный цвет аватара по имени автора.
  Color _avatarColor(String name) {
    const colors = [
      AppColors.accent,
      AppColors.primary,
      Color(0xFF6FCF97),
      Color(0xFF56CCF2),
      Color(0xFFEB5757),
    ];
    return colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(displayNameProvider) ??
        ref.watch(currentUserProvider) ??
        'Гость';
    final isOwn = widget.note.authorName == currentUser;
    final initials = widget.note.authorName.isNotEmpty
        ? widget.note.authorName[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка: аватар + имя + кнопки действий
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _avatarColor(widget.note.authorName),
                backgroundImage: widget.note.authorAvatarUrl != null
                    ? NetworkImage(widget.note.authorAvatarUrl!)
                    : null,
                child: widget.note.authorAvatarUrl != null
                    ? null
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.note.authorName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.onCard(context),
                  ),
                ),
              ),
              if (isOwn && !_editing) ...[
                IconButton(
                  onPressed: () => setState(() {
                    _editing = true;
                    _editCtrl.text = widget.note.text;
                  }),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: Colors.grey,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  tooltip: 'Редактировать',
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.warning,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  tooltip: 'Удалить',
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Тело: либо TextField в режиме редактирования, либо текст
          if (_editing) ...[
            TextField(
              controller: _editCtrl,
              maxLines: null,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ] else
            Text(widget.note.text, style: TextStyle(fontSize: 15, color: AppTheme.onCard(context))),

          const SizedBox(height: 8),
          // Дата создания
          Text(
            _fmtDate(widget.note.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${dt.day} ${months[dt.month - 1]}'
        ' ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
