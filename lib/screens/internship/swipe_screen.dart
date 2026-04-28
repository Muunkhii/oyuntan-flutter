// lib/screens/internship/swipe_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class SwipeScreen extends StatefulWidget {
  final String postId;
  const SwipeScreen({super.key, required this.postId});
  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final _service = InternshipService();
  List<Map<String, dynamic>> _candidates = [];
  int _idx = 0;
  bool _loading = true;
  Offset _dragOffset = Offset.zero;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    final list = await _service.getCandidates(widget.postId);
    setState(() { _candidates = list; _loading = false; });
  }

  void _accept() => _swipe('accepted');
  void _reject() => _swipe('rejected');

  Future<void> _swipe(String status) async {
    if (_idx >= _candidates.length) return;
    final app = _candidates[_idx];
    try {
      if (status == 'accepted') {
        final post = await ApiClient.get('/posts/${widget.postId}') as Map<String, dynamic>;
        await _service.acceptApplication(
          applicationId: app['id'] as String,
          studentId:     app['student_id'] as String,
          postId:        widget.postId,
          durationDays:  (post['duration_days'] as num?)?.toInt() ?? 30,
        );
      } else {
        await _service.rejectApplication(app['id'] as String);
      }
    } catch (_) {}
    setState(() {
      _dragOffset = Offset.zero;
      _dragging   = false;
      _idx++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CV харах'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2))
          : _candidates.isEmpty || _idx >= _candidates.length
              ? _EmptyState(count: _candidates.length)
              : Column(children: [
                  // Counter
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('${_idx + 1} / ${_candidates.length}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ),

                  // Card stack
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(alignment: Alignment.center, children: [
                        // Background card
                        if (_idx + 1 < _candidates.length)
                          Positioned(
                            top: 8, left: 10, right: 10,
                            child: _buildCard(_candidates[_idx + 1], 0.95, false),
                          ),
                        // Main draggable card
                        GestureDetector(
                          onPanStart: (_) => setState(() => _dragging = true),
                          onPanUpdate: (d) => setState(() => _dragOffset += d.delta),
                          onPanEnd: (_) {
                            if (_dragOffset.dx > 80) {
                              _accept();
                            } else if (_dragOffset.dx < -80) {
                              _reject();
                            } else {
                              setState(() { _dragOffset = Offset.zero; _dragging = false; });
                            }
                          },
                          child: AnimatedContainer(
                            duration: _dragging ? 0.ms : 200.ms,
                            transform: Matrix4.identity()
                              ..translateByDouble(_dragOffset.dx, _dragOffset.dy * 0.3, 0, 1)
                              ..rotateZ(_dragOffset.dx * 0.0008),
                            child: _buildCard(_candidates[_idx], 1.0, true),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reject,
                          child: const Text('Үгүй'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _accept,
                          child: const Text('Урих ✓'),
                        ),
                      ),
                    ]),
                  ),
                ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> app, double scale, bool showOverlay) {
    final studentId = app['student_id'] as String? ?? '';

    return FutureBuilder<Map<String, dynamic>>(
      future: ApiClient.get('/students/$studentId').then((v) => v as Map<String, dynamic>),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 420,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final s = snap.data!;
        final name       = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
        final university = s['university'] as String? ?? '';
        final major      = s['major']      as String? ?? '';
        final year       = s['year']       ?? '';
        final skills     = (s['skills']    as List?)?.cast<String>() ?? [];
        final bio        = s['bio']        as String? ?? '';

        return Transform.scale(
          scale: scale,
          child: AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Overlay hint
              if (showOverlay) ...[
                if (_dragOffset.dx > 30)
                  _OverlayBadge('УРИХ', AppColors.teal, true),
                if (_dragOffset.dx < -30)
                  _OverlayBadge('ҮГҮЙ', AppColors.red, false),
              ],
              // Avatar
              _Avatar(name: name, index: 0),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('$university · $major', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('$year-р курс', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              const SizedBox(height: 14),
              // Skills
              if (skills.isNotEmpty) Wrap(
                spacing: 6, runSpacing: 6,
                children: skills.take(5).map((sk) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(sk, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                )).toList(),
              ),
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
              ],
              // Psych profile
              if (s['psych_profile'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('СЭТГЭЛЗҮЙН ТЕСТ', style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text((s['psych_profile'] as Map).values.take(3).join(' · '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ),
              ],
              const SizedBox(height: 8),
              const Text('← шударж үзэх →', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            ]),
          ),
        );
      },
    );
  }
}

class _OverlayBadge extends StatelessWidget {
  final String text; final Color color; final bool isRight;
  const _OverlayBadge(this.text, this.color, this.isRight);
  @override
  Widget build(BuildContext context) => Positioned(
    top: 0, right: isRight ? 0 : null, left: isRight ? null : 0,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String name; final int index;
  const _Avatar({required this.name, required this.index});

  static const _bgs = [Color(0xFFE6F1FB), Color(0xFFE1F5EE), Color(0xFFEEEDFE), Color(0xFFFAECE7)];
  static const _fg  = [Color(0xFF185FA5), Color(0xFF0F6E56), Color(0xFF534AB7), Color(0xFF993C1D)];

  @override
  Widget build(BuildContext context) {
    final i = index % 4;
    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    return CircleAvatar(
      radius: 36, backgroundColor: _bgs[i],
      child: Text(initials, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: _fg[i])),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int count;
  const _EmptyState({required this.count});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(
        color: AppColors.bg, borderRadius: BorderRadius.circular(32)),
        child: const Icon(Icons.check, size: 32, color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      const Text('Бүх CV-г үзлээ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Text('$count хүсэлт ирсэн байсан',
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ]),
  );
}
