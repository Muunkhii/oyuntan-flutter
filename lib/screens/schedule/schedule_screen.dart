// lib/screens/schedule/schedule_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override State<ScheduleScreen> createState() => _SchState();
}

class _SchState extends State<ScheduleScreen> {
  int _day = DateTime.now().weekday - 1;
  List<Map<String, dynamic>> _all = [];
  bool _syncing = false;

  static const _days      = ['Даваа','Мягмар','Лхагва','Пүрэв','Баасан','Бямба','Ням'];
  static const _daysShort = ['Да','Мя','Лх','Пү','Ба','Бя','Ня'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    // 1. Try backend first
    final uid = context.read<AuthProvider>().uid;
    if (uid.isNotEmpty) {
      try {
        final list = await ScheduleService().getSchedule(uid);
        if (mounted && list.isNotEmpty) {
          setState(() => _all = list);
          await _saveLocal(); // cache locally
          return;
        }
      } catch (_) {}
    }
    // 2. Fallback to local cache
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('schedule') ?? '[]';
    if (mounted) setState(() => _all = (jsonDecode(raw) as List).cast<Map<String, dynamic>>());
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('schedule', jsonEncode(_all));
  }

  Future<void> _syncBackend() async {
    final uid = context.read<AuthProvider>().uid;
    if (uid.isEmpty) return;
    setState(() => _syncing = true);
    try {
      await ScheduleService().saveSchedule(_all);
    } catch (_) {}
    if (mounted) setState(() => _syncing = false);
  }

  Future<void> _persist() async {
    await _saveLocal();
    await _syncBackend();
  }

  List<Map<String, dynamic>> get _dayEntries {
    final list = _all.where((d) => d['day'] == _day).toList();
    list.sort((a, b) => (a['startHour'] as int).compareTo(b['startHour'] as int));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Хичээлийн хуваарь'),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_done_outlined, size: 22),
              tooltip: 'Синк хийх',
              onPressed: _syncBackend,
            ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            onPressed: () => _showAddSheet(context),
          ),
        ],
      ),
      body: Column(children: [
        // ── Day selector ──────────────────────────────────────
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: List.generate(7, (i) {
            final on = _day == i;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _day = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: on ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text(_daysShort[i], style: TextStyle(fontSize: 9, color: on ? Colors.white70 : AppColors.faint)),
                  const SizedBox(height: 2),
                  Text(_daysShort[i][0], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: on ? AppColors.white : AppColors.muted)),
                ]),
              ),
            ));
          })),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Text(_days[_day], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${_dayEntries.length} хичээл', style: const TextStyle(fontSize: 12, color: AppColors.faint)),
          ]),
        ),

        // ── Schedule list ─────────────────────────────────────
        Expanded(
          child: _dayEntries.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(30)),
                    child: const Icon(Icons.calendar_today_outlined, size: 28, color: AppColors.faint)),
                  const SizedBox(height: 12),
                  Text('${_days[_day]} өдөр хичээл байхгүй', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton.icon(onPressed: () => _showAddSheet(context), icon: const Icon(Icons.add, size: 16), label: const Text('Хичээл нэмэх')),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: _dayEntries.length,
                  itemBuilder: (c, i) {
                    final d     = _dayEntries[i];
                    final color = _subjectColor(d['subject'] as String? ?? '');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: Key('${d['subject']}_${d['startHour']}_${d['day']}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.delete_outline, color: AppColors.red),
                        ),
                        onDismissed: (_) async {
                          setState(() => _all.remove(d));
                          await _persist();
                        },
                        child: GestureDetector(
                          onLongPress: () => _showAddSheet(context, existing: d),
                          child: AppCard(child: Row(children: [
                            Container(width: 4, height: 56, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d['subject'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.access_time, size: 12, color: AppColors.faint),
                                const SizedBox(width: 4),
                                Text('${_fmt(d['startHour'], d['startMin'])} — ${_fmt(d['endHour'], d['endMin'])}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                if (d['room'] != null && (d['room'] as String).isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.faint),
                                  const SizedBox(width: 2),
                                  Text(d['room'] as String, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                ],
                                if (d['teacher'] != null && (d['teacher'] as String).isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  const Icon(Icons.person_outline, size: 12, color: AppColors.faint),
                                  const SizedBox(width: 2),
                                  Text(d['teacher'] as String, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                ],
                              ]),
                            ])),
                            if (d['type'] != null)
                              StatusBadge(d['type'] as String, bg: color.withValues(alpha: 0.15), textColor: color),
                          ])),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text('Хичээл нэмэх', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _fmt(dynamic h, dynamic m) =>
      '${(h as int? ?? 8).toString().padLeft(2, '0')}:${(m as int? ?? 0).toString().padLeft(2, '0')}';

  Color _subjectColor(String s) {
    final colors = [AppColors.primary, AppColors.green, AppColors.purple, AppColors.amber, AppColors.teal, AppColors.red];
    return colors[s.hashCode.abs() % colors.length];
  }

  void _showAddSheet(BuildContext ctx, {Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddScheduleSheet(
        day: _day,
        existing: existing,
        onSave: (data) async {
          setState(() {
            if (existing != null) _all.remove(existing);
            _all.add(data);
          });
          await _persist();
        },
        onDelete: existing == null ? null : () async {
          setState(() => _all.remove(existing));
          await _persist();
        },
      ),
    );
  }
}

class _AddScheduleSheet extends StatefulWidget {
  final int day;
  final Map<String, dynamic>? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback? onDelete;
  const _AddScheduleSheet({required this.day, this.existing, required this.onSave, this.onDelete});
  @override State<_AddScheduleSheet> createState() => _ASSState();
}

class _ASSState extends State<_AddScheduleSheet> {
  final _subject = TextEditingController();
  final _room    = TextEditingController();
  final _teacher = TextEditingController();
  int _startH = 8, _startM = 0, _endH = 9, _endM = 40;
  String _type  = 'Лекц';
  bool _saving  = false;
  static const _types = ['Лекц', 'Семинар', 'Лаборатори', 'Дадлага'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _subject.text = e['subject'] as String? ?? '';
      _room.text    = e['room']    as String? ?? '';
      _teacher.text = e['teacher'] as String? ?? '';
      _startH = e['startHour'] as int? ?? 8;  _startM = e['startMin'] as int? ?? 0;
      _endH   = e['endHour']   as int? ?? 9;  _endM   = e['endMin']   as int? ?? 40;
      _type   = e['type']      as String? ?? 'Лекц';
    }
  }

  @override Widget build(BuildContext c) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(widget.existing == null ? 'Хичээл нэмэх' : 'Хичээл засварлах',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (widget.onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
            onPressed: () { Navigator.pop(c); widget.onDelete!(); },
          ),
      ]),
      const SizedBox(height: 14),

      const FieldLabel('Хичээлийн нэр'),
      TextField(controller: _subject, decoration: const InputDecoration(hintText: 'Програмчлалын хэл...')),

      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('Эхлэх цаг'),
          _TimePicker(_startH, _startM, (h, m) => setState(() { _startH = h; _startM = m; })),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('Дуусах цаг'),
          _TimePicker(_endH, _endM, (h, m) => setState(() { _endH = h; _endM = m; })),
        ])),
      ]),

      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('Өрөө / Байр'),
          TextField(controller: _room, decoration: const InputDecoration(hintText: '301А...')),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('Багш'),
          TextField(controller: _teacher, decoration: const InputDecoration(hintText: 'Б.Болд...')),
        ])),
      ]),

      const FieldLabel('Хичээлийн төрөл'),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
        children: _types.map((t) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _type = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _type == t ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _type == t ? AppColors.primary : AppColors.border, width: _type == t ? 1.5 : 0.5),
              ),
              child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: _type == t ? AppColors.white : AppColors.muted)),
            ),
          ),
        )).toList(),
      )),

      const SizedBox(height: 20),
      PrimaryButton(
        label: widget.existing == null ? 'Хадгалах' : 'Шинэчлэх',
        loading: _saving,
        onTap: () async {
          if (_subject.text.trim().isEmpty) return;
          setState(() => _saving = true);
          await widget.onSave({
            'subject': _subject.text.trim(),
            'room':    _room.text.trim().isEmpty    ? null : _room.text.trim(),
            'teacher': _teacher.text.trim().isEmpty ? null : _teacher.text.trim(),
            'startHour': _startH, 'startMin': _startM,
            'endHour':   _endH,   'endMin':   _endM,
            'type': _type, 'day': widget.day,
          });
          if (mounted) Navigator.pop(context);
        },
      ),
      const SizedBox(height: 20),
    ]),
  );

  @override void dispose() { _subject.dispose(); _room.dispose(); _teacher.dispose(); super.dispose(); }
}

class _TimePicker extends StatelessWidget {
  final int h, m;
  final void Function(int, int) onChange;
  const _TimePicker(this.h, this.m, this.onChange);

  @override Widget build(BuildContext c) => GestureDetector(
    onTap: () async {
      final t = await showTimePicker(
        context: c, initialTime: TimeOfDay(hour: h, minute: m),
        builder: (c, child) => Theme(
          data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
          child: child!),
      );
      if (t != null) onChange(t.hour, t.minute);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(children: [
        const Icon(Icons.access_time, size: 14, color: AppColors.faint),
        const SizedBox(width: 6),
        Text('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}
