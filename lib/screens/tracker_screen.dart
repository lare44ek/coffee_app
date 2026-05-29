import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/api_service.dart';
import '../services/tracker_service.dart';

const _bg = Color(0xFF0E0E12);
const _panel = Color(0xFF17171E);
const _accent = Color(0xFF35E07F); // «хакерский» зелёный
const _danger = Color(0xFFFF4D4D);

// ───────────────────────────────────────────────────────────────────────────
// Экран-досье: собирает данные и драматично показывает их пользователю.
// ───────────────────────────────────────────────────────────────────────────

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  Map<String, dynamic>? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final username =
        ref.read(displayNameProvider) ?? ref.read(currentUserProvider);
    try {
      final data = await TrackerService.collect(username: username);
      if (!mounted) return;
      setState(() => _data = data);
      // Фоном фиксируем визит в БД (фид).
      ApiService.sendVisit(data).ignore();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _accent,
        elevation: 0,
        title: const Text(
          'СБОР ДАННЫХ',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Кто заходил',
            icon: const Icon(Icons.dns_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VisitsFeedScreen()),
            ),
          ),
        ],
      ),
      body: _failed
          ? const _Centered(
              text: '> ОШИБКА СВЯЗИ\n> цель ускользнула...',
            )
          : _data == null
              ? const _Centered(text: '> СКАНИРОВАНИЕ ЦЕЛИ...')
              : _Dossier(data: _data!),
    );
  }
}

class _Centered extends StatelessWidget {
  final String text;
  const _Centered({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
          ),
          const SizedBox(height: 20),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _accent,
              fontFamily: 'monospace',
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dossier extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Dossier({required this.data});

  String? _str(String key) {
    final v = data[key];
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  @override
  Widget build(BuildContext context) {
    final coords = (data['lat'] != null && data['lon'] != null)
        ? '${data['lat']}, ${data['lon']}'
        : null;

    final rows = <(IconData, String, String?)>[
      (Icons.person_outline, 'ЦЕЛЬ', _str('username') ?? 'неизвестна'),
      (Icons.lan_outlined, 'IP-АДРЕС', _str('ip')),
      (Icons.location_city_outlined, 'ГОРОД', _str('city')),
      (Icons.map_outlined, 'РЕГИОН', _str('region')),
      (Icons.public, 'СТРАНА', _str('country')),
      (Icons.router_outlined, 'ПРОВАЙДЕР', _str('isp')),
      (Icons.my_location_outlined, 'КООРДИНАТЫ', coords),
      (Icons.schedule_outlined, 'ТАЙМЗОНА', _str('timezone')),
      (Icons.smartphone_outlined, 'УСТРОЙСТВО', _str('device')),
      (Icons.memory_outlined, 'ОС', _str('os')),
      (Icons.battery_full_outlined, 'БАТАРЕЯ',
          data['battery'] != null ? '${data['battery']}%' : null),
      (Icons.wifi_outlined, 'СЕТЬ', _str('network')),
      (Icons.translate_outlined, 'ЯЗЫК', _str('locale')),
      (Icons.tag_outlined, 'ВЕРСИЯ ПО', _str('app_version')),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _danger.withAlpha(120)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Привет дружище, жди докс',
                  style: TextStyle(
                    color: _danger,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1,
                  )),
              SizedBox(height: 6),
              Text('Шалость удалась',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...rows.map((r) => _DossierRow(icon: r.$1, label: r.$2, value: r.$3)),
        const SizedBox(height: 20),
        const Text(
          '// данные сохранены на сервер. шутка. (нет)',
          style: TextStyle(
            color: Colors.white24,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DossierRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _DossierRow({required this.icon, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final known = value != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: known ? _accent : Colors.white24),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontFamily: 'monospace',
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '—',
              style: TextStyle(
                color: known ? Colors.white : Colors.white24,
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Лента визитов: кто и откуда открывал приложение.
// ───────────────────────────────────────────────────────────────────────────

class VisitsFeedScreen extends StatefulWidget {
  const VisitsFeedScreen({super.key});

  @override
  State<VisitsFeedScreen> createState() => _VisitsFeedScreenState();
}

class _VisitsFeedScreenState extends State<VisitsFeedScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getVisits();
  }

  void _refresh() => setState(() => _future = ApiService.getVisits());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _accent,
        elevation: 0,
        title: const Text(
          'КТО ЗАХОДИЛ',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const _Centered(text: '> ЗАГРУЗКА ЛЕНТЫ...');
          }
          if (snap.hasError) {
            return const _Centered(text: '> ОШИБКА ЗАГРУЗКИ');
          }
          final visits = snap.data ?? [];
          if (visits.isEmpty) {
            return const Center(
              child: Text(
                '> записей пока нет',
                style: TextStyle(color: Colors.white38, fontFamily: 'monospace'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: visits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _VisitCard(v: visits[i]),
          );
        },
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Map<String, dynamic> v;
  const _VisitCard({required this.v});

  String _line() {
    final parts = <String>[];
    if (v['city'] != null) parts.add('${v['city']}');
    if (v['country'] != null) parts.add('${v['country']}');
    return parts.isEmpty ? 'локация неизвестна' : parts.join(', ');
  }

  String _when() {
    final raw = v['created_at'];
    if (raw == null) return '';
    final dt = DateTime.tryParse('$raw')?.toLocal();
    if (dt == null) return '$raw';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_circle_outlined,
                  size: 18, color: _accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${v['username'] ?? 'аноним'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                _when(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _kv('IP', '${v['ip'] ?? '—'}'),
          _kv('МЕСТО', _line()),
          if (v['isp'] != null) _kv('ПРОВАЙДЕР', '${v['isp']}'),
          if (v['device'] != null) _kv('УСТР-ВО', '${v['device']}'),
        ],
      ),
    );
  }

  Widget _kv(String k, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              k,
              style: const TextStyle(
                color: Colors.white38,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
