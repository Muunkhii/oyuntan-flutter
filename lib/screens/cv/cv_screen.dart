// lib/screens/cv/cv_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

// ─── Data models ─────────────────────────────────────────────
class _PortfolioItem {
  final nameCtrl = TextEditingController();
  final urlCtrl  = TextEditingController();
  _PortfolioItem({String name = '', String url = ''}) {
    nameCtrl.text = name;
    urlCtrl.text  = url;
  }
  void dispose() { nameCtrl.dispose(); urlCtrl.dispose(); }
}

class _GradeItem {
  final subjectCtrl = TextEditingController();
  final gradeCtrl   = TextEditingController();
  _GradeItem({String subject = '', String grade = ''}) {
    subjectCtrl.text = subject;
    gradeCtrl.text   = grade;
  }
  void dispose() { subjectCtrl.dispose(); gradeCtrl.dispose(); }
}

class _ExpItem {
  final companyCtrl = TextEditingController();
  final roleCtrl    = TextEditingController();
  final periodCtrl  = TextEditingController();
  final descCtrl    = TextEditingController();
  _ExpItem({String company = '', String role = '', String period = '', String desc = ''}) {
    companyCtrl.text = company;
    roleCtrl.text    = role;
    periodCtrl.text  = period;
    descCtrl.text    = desc;
  }
  void dispose() { companyCtrl.dispose(); roleCtrl.dispose(); periodCtrl.dispose(); descCtrl.dispose(); }
}

// ─── Screen ───────────────────────────────────────────────────
class CVScreen extends StatefulWidget {
  const CVScreen({super.key});
  @override State<CVScreen> createState() => _CVScreenState();
}

class _CVScreenState extends State<CVScreen> {
  // Personal
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _countryCtrl   = TextEditingController();
  DateTime? _dob;

  // Education
  final _univCtrl  = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _yearCtrl  = TextEditingController();
  final _gpaCtrl   = TextEditingController();

  // Lists
  final List<_GradeItem> _grades      = [];
  final List<_ExpItem>   _experiences = [];
  final List<String>     _skills      = [];
  final List<String>     _languages   = [];
  final List<String>     _certs       = [];

  // Bio
  final _summaryCtrl = TextEditingController();

  // Interests & portfolio
  final List<String>        _interests   = [];
  final List<_PortfolioItem> _portfolio  = [];

  // Chip input controllers
  final _skillCtrl    = TextEditingController();
  final _langCtrl     = TextEditingController();
  final _certCtrl     = TextEditingController();
  final _interestCtrl = TextEditingController();

  bool _saving     = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _prefill();
    _loadSaved();
  }

  void _prefill() {
    final p = context.read<AuthProvider>().profile ?? {};
    _firstNameCtrl.text = (p['first_name'] ?? p['firstName'] ?? '').toString();
    _lastNameCtrl.text  = (p['last_name']  ?? p['lastName']  ?? '').toString();
    _emailCtrl.text     = (p['email']      ?? '').toString();
    _phoneCtrl.text     = (p['phone']      ?? '').toString();
    _countryCtrl.text   = (p['country']    ?? '').toString();
    _univCtrl.text      = (p['university'] ?? '').toString();
    _majorCtrl.text     = (p['major']      ?? '').toString();
    _yearCtrl.text      = (p['year']?.toString() ?? '');
    _gpaCtrl.text       = (p['gpa']?.toString()  ?? '');
    _summaryCtrl.text   = (p['bio']        ?? '').toString();

    final ps = List<String>.from((p['skills'] as List?) ?? []);
    if (ps.isNotEmpty) _skills.addAll(ps);
    if (_languages.isEmpty) _languages.add('Монгол');

    final interests = List<String>.from((p['interests'] as List?) ?? []);
    if (interests.isNotEmpty) _interests.addAll(interests);

    final dobStr = p['birth_date'] ?? p['birthDate'];
    if (dobStr != null) {
      try { _dob = DateTime.parse(dobStr.toString()); } catch (_) {}
    }
  }

  Future<void> _loadSaved() async {
    final uid = context.read<AuthProvider>().uid;
    if (uid.isEmpty) return;
    try {
      final cv = await CVService().get(uid);
      if (cv != null && mounted) setState(() => _applyCv(cv));
    } catch (_) {}
  }

  void _applyCv(Map<String, dynamic> cv) {
    void maybe(TextEditingController c, dynamic v) {
      final s = v?.toString() ?? '';
      if (s.isNotEmpty) c.text = s;
    }
    maybe(_firstNameCtrl, cv['firstName'] ?? cv['first_name']);
    maybe(_lastNameCtrl,  cv['lastName']  ?? cv['last_name']);
    maybe(_emailCtrl,     cv['email']);
    maybe(_phoneCtrl,     cv['phone']);
    maybe(_countryCtrl,   cv['country']);
    maybe(_univCtrl,      cv['university']);
    maybe(_majorCtrl,     cv['major']);
    maybe(_gpaCtrl,       cv['gpa']?.toString());
    maybe(_yearCtrl,      cv['year']?.toString());
    maybe(_summaryCtrl,   cv['summary'] ?? cv['bio']);

    final dobStr = cv['dob'] ?? cv['birthDate'];
    if (dobStr != null) {
      try { _dob = DateTime.parse(dobStr.toString()); } catch (_) {}
    }

    final skills = (cv['skills'] as List?)?.cast<String>() ?? [];
    if (skills.isNotEmpty) { _skills.clear(); _skills.addAll(skills); }

    final langs = (cv['languages'] as List?)?.cast<String>() ?? [];
    if (langs.isNotEmpty) { _languages.clear(); _languages.addAll(langs); }

    final certs = (cv['certs'] as List?)?.cast<String>() ?? [];
    if (certs.isNotEmpty) { _certs.clear(); _certs.addAll(certs); }

    final grades = (cv['grades'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (grades.isNotEmpty) {
      for (final g in _grades) { g.dispose(); }
      _grades.clear();
      _grades.addAll(grades.map((g) => _GradeItem(
        subject: g['subject']?.toString() ?? '',
        grade:   g['grade']?.toString()   ?? '',
      )));
    }

    final exps = (cv['experiences'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (exps.isNotEmpty) {
      for (final e in _experiences) { e.dispose(); }
      _experiences.clear();
      _experiences.addAll(exps.map((e) => _ExpItem(
        company: e['company']?.toString() ?? '',
        role:    e['role']?.toString()    ?? '',
        period:  e['period']?.toString()  ?? '',
        desc:    e['desc']?.toString()    ?? '',
      )));
    }

    final ints = (cv['interests'] as List?)?.cast<String>() ?? [];
    if (ints.isNotEmpty) { _interests.clear(); _interests.addAll(ints); }

    final ports = (cv['portfolio'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (ports.isNotEmpty) {
      for (final p in _portfolio) { p.dispose(); }
      _portfolio.clear();
      _portfolio.addAll(ports.map((p) => _PortfolioItem(
        name: p['name']?.toString() ?? '',
        url:  p['url']?.toString()  ?? '',
      )));
    }
  }

  Map<String, dynamic> _buildCvData() => {
    'firstName':   _firstNameCtrl.text.trim(),
    'lastName':    _lastNameCtrl.text.trim(),
    'email':       _emailCtrl.text.trim(),
    'phone':       _phoneCtrl.text.trim(),
    'country':     _countryCtrl.text.trim(),
    'dob':         _dob?.toIso8601String(),
    'university':  _univCtrl.text.trim(),
    'major':       _majorCtrl.text.trim(),
    'gpa':         _gpaCtrl.text.trim(),
    'year':        int.tryParse(_yearCtrl.text) ?? 1,
    'summary':     _summaryCtrl.text.trim(),
    'skills':      _skills,
    'languages':   _languages,
    'certs':       _certs,
    'interests':   _interests,
    'portfolio':   _portfolio.map((p) => {
      'name': p.nameCtrl.text.trim(),
      'url':  p.urlCtrl.text.trim(),
    }).where((p) => (p['name'] as String).isNotEmpty || (p['url'] as String).isNotEmpty).toList(),
    'grades':      _grades.map((g) => {
      'subject': g.subjectCtrl.text.trim(),
      'grade':   g.gradeCtrl.text.trim(),
    }).where((g) => (g['subject'] as String).isNotEmpty).toList(),
    'experiences': _experiences.map((e) => {
      'company': e.companyCtrl.text.trim(),
      'role':    e.roleCtrl.text.trim(),
      'period':  e.periodCtrl.text.trim(),
      'desc':    e.descCtrl.text.trim(),
    }).where((e) => (e['company'] as String).isNotEmpty).toList(),
  };

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final uid  = auth.uid;
      final cv   = _buildCvData();
      await ApiClient.put('/students/$uid', {
        'firstName':  cv['firstName'],
        'lastName':   cv['lastName'],
        'phone':      cv['phone'],
        'bio':        cv['summary'],
        'skills':     cv['skills'],
        'year':       cv['year'],
        'university': cv['university'],
        'major':      cv['major'],
        'interests':  cv['interests'],
      });
      await CVService().save(uid, cv);
      await auth.refreshProfile();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Профайл хадгалагдлаа ✓'),
        backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message), backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _generating = true);
    try {
      final cv   = _buildCvData();
      final name = '${cv['firstName']} ${cv['lastName']}'.trim();
      final pdf  = pw.Document();

      final fontData  = await DefaultAssetBundle.of(context).load('assets/fonts/NotoSans-Regular.ttf');
      final fontBData = await DefaultAssetBundle.of(context).load('assets/fonts/NotoSans-Bold.ttf');
      final ttf       = pw.Font.ttf(fontData.buffer.asByteData());
      final ttfBold   = pw.Font.ttf(fontBData.buffer.asByteData());
      final body      = pw.TextStyle(font: ttf,     fontSize: 10);
      final head      = pw.TextStyle(font: ttfBold, fontSize: 14);
      final sec       = pw.TextStyle(font: ttfBold, fontSize: 11);
      final muted     = pw.TextStyle(font: ttf,     fontSize: 9, color: PdfColors.grey600);

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Text(name.isEmpty ? 'Профайл' : name, style: head),
          pw.SizedBox(height: 3),
          if ((cv['email'] as String).isNotEmpty)
            pw.Text('${cv['email']}  ·  ${cv['phone']}  ·  ${cv['country']}', style: muted),
          pw.SizedBox(height: 10),
          pw.Divider(),
          if ((cv['summary'] as String).isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Танилцуулга', style: sec),
            pw.SizedBox(height: 3),
            pw.Text(cv['summary'] as String, style: body),
            pw.SizedBox(height: 10),
          ],
          pw.Text('Боловсрол', style: sec),
          pw.SizedBox(height: 3),
          pw.Text(
            '${cv['university']}  ·  ${cv['major']}  ·  ${cv['year']}-р курс'
            '${(cv['gpa'] as String).isNotEmpty ? "  ·  GPA: ${cv['gpa']}" : ""}',
            style: body,
          ),
          if ((cv['grades'] as List).isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('Хичээлийн дүн', style: sec),
            pw.SizedBox(height: 3),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Хичээл', style: sec)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Дүн', style: sec)),
                ]),
                ...(cv['grades'] as List).map((g) => pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(g['subject'] ?? '', style: body)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(g['grade']   ?? '', style: body)),
                ])),
              ],
            ),
          ],
          if ((cv['experiences'] as List).isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('Ажлын туршлага', style: sec),
            pw.SizedBox(height: 3),
            ...(cv['experiences'] as List).map((e) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(children: [
                  pw.Text('${e['company']}  ·  ${e['role']}', style: sec),
                  pw.Spacer(),
                  pw.Text(e['period'] ?? '', style: muted),
                ]),
                if ((e['desc'] as String?)?.isNotEmpty == true)
                  pw.Text(e['desc'] as String, style: body),
                pw.SizedBox(height: 6),
              ],
            )),
          ],
          if ((cv['skills'] as List).isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Ур чадвар', style: sec),
            pw.SizedBox(height: 3),
            pw.Text((cv['skills'] as List).join('  ·  '), style: body),
          ],
          if ((cv['languages'] as List).isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Хэл мэдлэг', style: sec),
            pw.SizedBox(height: 3),
            pw.Text((cv['languages'] as List).join('  ·  '), style: body),
          ],
          if ((cv['certs'] as List).isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Гэрчилгээ', style: sec),
            pw.SizedBox(height: 3),
            pw.Text((cv['certs'] as List).join('  ·  '), style: body),
          ],
        ],
      ));

      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('PDF алдаа: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Профайл засах'),
        actions: [
          _generating
            ? const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted)))
            : TextButton.icon(
                onPressed: _generatePdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.muted),
                label: const Text('PDF', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
          _saving
            ? const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
            : TextButton(
                onPressed: _saveProfile,
                child: const Text('Хадгалах',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _section('Хувийн мэдээлэл', Icons.person_outline, _buildPersonal()),
          _section('Боловсрол', Icons.school_outlined, _buildEducation()),
          _section('Хичээлийн дүн', Icons.grade_outlined, _buildGrades()),
          _section('Ажлын туршлага', Icons.work_history_outlined, _buildExperiences()),
          _section('Ур чадвар', Icons.psychology_outlined, _buildChips(
            items: _skills,
            ctrl: _skillCtrl,
            hint: 'Flutter, Python, Figma...',
            color: AppColors.primaryLight,
            onAdd: (v) => setState(() { _skills.add(v); _skillCtrl.clear(); }),
            onRemove: (v) => setState(() => _skills.remove(v)),
          )),
          _section('Хэл мэдлэг', Icons.language_outlined, _buildChips(
            items: _languages,
            ctrl: _langCtrl,
            hint: 'Монгол, Англи, Хятад...',
            color: AppColors.bg,
            onAdd: (v) => setState(() { _languages.add(v); _langCtrl.clear(); }),
            onRemove: (v) => setState(() => _languages.remove(v)),
          )),
          _section('Гэрчилгээ', Icons.verified_outlined, _buildChips(
            items: _certs,
            ctrl: _certCtrl,
            hint: 'AWS Certified, IELTS 7.0...',
            color: AppColors.amberLight,
            onAdd: (v) => setState(() { _certs.add(v); _certCtrl.clear(); }),
            onRemove: (v) => setState(() => _certs.remove(v)),
          )),
          _section('Сонирхлын чиглэл', Icons.explore_outlined, _buildChips(
            items: _interests,
            ctrl: _interestCtrl,
            hint: 'Веб хөгжүүлэлт, Дата шинжилгээ...',
            color: const Color(0xFFE8F5E9),
            maxItems: 10,
            onAdd: (v) => setState(() { _interests.add(v); _interestCtrl.clear(); }),
            onRemove: (v) => setState(() => _interests.remove(v)),
          )),
          _section('Бүтээл / Портфолио', Icons.folder_special_outlined, _buildPortfolio()),
          _section('Танилцуулга', Icons.notes_outlined, TextField(
            controller: _summaryCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Өөрийн тухай товч танилцуулга, зорилго, давуу тал...'),
          )),
        ]),
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget content) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
      ]),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: content,
      ),
      const SizedBox(height: 14),
    ],
  );

  // ─── Personal ────────────────────────────────────────────────
  Widget _buildPersonal() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: _field('Нэр',  _firstNameCtrl, hint: 'Болд')),
      const SizedBox(width: 10),
      Expanded(child: _field('Овог', _lastNameCtrl,  hint: 'Төмөр')),
    ]),
    _field('Имэйл', _emailCtrl,
      hint: 'name@example.com',
      enabled: false,
      icon: Icons.email_outlined),
    _field('Утасны дугаар', _phoneCtrl,
      hint: '+976 ···· ····',
      type: TextInputType.phone,
      icon: Icons.phone_outlined),
    const SizedBox(height: 8),
    const Text('Төрсөн огноо', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted)),
    const SizedBox(height: 6),
    GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _dob ?? DateTime(2002),
          firstDate: DateTime(1980),
          lastDate: DateTime(2010),
        );
        if (d != null) setState(() => _dob = d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.faint),
          const SizedBox(width: 10),
          Text(
            _dob == null ? 'Огноо сонгох'
              : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 13, color: _dob == null ? AppColors.faint : AppColors.text),
          ),
        ]),
      ),
    ),
    _field('Улс / Хот', _countryCtrl, hint: 'Монгол, Улаанбаатар', icon: Icons.location_on_outlined),
  ]);

  // ─── Education ────────────────────────────────────────────────
  Widget _buildEducation() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _field('Сургуулийн нэр', _univCtrl, hint: 'ШУТИС, МУИС...',     icon: Icons.account_balance_outlined),
    _field('Мэргэжил',       _majorCtrl, hint: 'Програм хангамж...', icon: Icons.book_outlined),
    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: _field('Курс', _yearCtrl,
        hint: '3', type: TextInputType.number, suffix: '-р курс')),
      const SizedBox(width: 10),
      Expanded(child: _field('Голч дүн (GPA)', _gpaCtrl,
        hint: '3.50', type: TextInputType.number, suffix: '/ 4.0')),
    ]),
  ]);

  // ─── Grades ───────────────────────────────────────────────────
  Widget _buildGrades() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ..._grades.asMap().entries.map((e) {
      final i = e.key; final g = e.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(flex: 3, child: TextField(
            controller: g.subjectCtrl,
            decoration: const InputDecoration(hintText: 'Хичээлийн нэр'),
          )),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: TextField(
            controller: g.gradeCtrl,
            decoration: const InputDecoration(hintText: 'A, 3.8, 90%'),
          )),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() { _grades[i].dispose(); _grades.removeAt(i); }),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.remove_circle_outline, size: 18, color: AppColors.red)),
          ),
        ]),
      );
    }),
    if (_grades.isEmpty)
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('Хичээлийн дүн оруулаагүй байна.',
          style: TextStyle(fontSize: 12, color: AppColors.faint)),
      ),
    TextButton.icon(
      onPressed: () => setState(() => _grades.add(_GradeItem())),
      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
      label: const Text('Хичээл нэмэх', style: TextStyle(fontSize: 13, color: AppColors.primary)),
    ),
  ]);

  // ─── Experiences ─────────────────────────────────────────────
  Widget _buildExperiences() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ..._experiences.asMap().entries.map((e) {
      final i = e.key; final exp = e.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Туршлага', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() { _experiences[i].dispose(); _experiences.removeAt(i); }),
              child: const Icon(Icons.close, size: 16, color: AppColors.red)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: exp.companyCtrl,
              decoration: const InputDecoration(hintText: 'Компани / Байгууллага'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: exp.roleCtrl,
              decoration: const InputDecoration(hintText: 'Үүрэг / Албан тушаал'))),
          ]),
          const SizedBox(height: 6),
          TextField(controller: exp.periodCtrl,
            decoration: const InputDecoration(hintText: 'Хугацаа: 2023.01 – 2023.06')),
          const SizedBox(height: 6),
          TextField(controller: exp.descCtrl, maxLines: 2,
            decoration: const InputDecoration(hintText: 'Хийсэн ажил, гаргасан үр дүн...')),
        ]),
      );
    }),
    if (_experiences.isEmpty)
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('Ажлын туршлага оруулаагүй байна.',
          style: TextStyle(fontSize: 12, color: AppColors.faint)),
      ),
    TextButton.icon(
      onPressed: () => setState(() => _experiences.add(_ExpItem())),
      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
      label: const Text('Туршлага нэмэх', style: TextStyle(fontSize: 13, color: AppColors.primary)),
    ),
  ]);

  // ─── Portfolio ───────────────────────────────────────────────
  Widget _buildPortfolio() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ..._portfolio.asMap().entries.map((e) {
      final i = e.key; final p = e.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5)),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.link_rounded, size: 15, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: p.nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Бүтээлийн нэр', isDense: true,
                border: InputBorder.none, contentPadding: EdgeInsets.zero),
            )),
            GestureDetector(
              onTap: () => setState(() { _portfolio[i].dispose(); _portfolio.removeAt(i); }),
              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted)),
          ]),
          const Divider(height: 10),
          TextField(
            controller: p.urlCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://github.com/... эсвэл docs.google.com/...',
              isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero,
              prefixIcon: Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.faint)),
          ),
        ]),
      );
    }),
    if (_portfolio.isEmpty)
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('GitHub репо, Google Docs эсвэл бусад холбоос нэмж болно',
          style: TextStyle(fontSize: 12, color: AppColors.faint)),
      ),
    if (_portfolio.length < 10)
      TextButton.icon(
        onPressed: () => setState(() => _portfolio.add(_PortfolioItem())),
        icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
        label: const Text('Бүтээл нэмэх', style: TextStyle(fontSize: 13, color: AppColors.primary)),
      ),
  ]);

  // ─── Chip section ────────────────────────────────────────────
  Widget _buildChips({
    required List<String> items,
    required TextEditingController ctrl,
    required String hint,
    required Color color,
    int? maxItems,
    required void Function(String) onAdd,
    required void Function(String) onRemove,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (items.isNotEmpty) ...[
      Wrap(spacing: 8, runSpacing: 6,
        children: items.map((s) => Chip(
          label: Text(s, style: const TextStyle(fontSize: 12)),
          onDeleted: () => onRemove(s),
          deleteIconColor: AppColors.muted,
          backgroundColor: color,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        )).toList()),
      const SizedBox(height: 10),
    ],
    if (maxItems == null || items.length < maxItems)
      Row(children: [
        Expanded(child: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) { if (v.trim().isNotEmpty) onAdd(v.trim()); },
        )),
        IconButton(
          onPressed: () { if (ctrl.text.trim().isNotEmpty) onAdd(ctrl.text.trim()); },
          icon: const Icon(Icons.add_circle, color: AppColors.primary),
        ),
      ]),
    if (maxItems != null && items.length >= maxItems)
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text('Хамгийн ихдээ $maxItems зүйл оруулах боломжтой',
          style: const TextStyle(fontSize: 11, color: AppColors.faint)),
      ),
  ]);

  // ─── Field helper ─────────────────────────────────────────────
  Widget _field(String label, TextEditingController ctrl, {
    String? hint,
    bool enabled = true,
    TextInputType? type,
    IconData? icon,
    String? suffix,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted)),
    const SizedBox(height: 5),
    TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        filled: !enabled,
        fillColor: enabled ? null : AppColors.bg,
        prefixIcon: icon != null ? Icon(icon, size: 16, color: AppColors.faint) : null,
      ),
    ),
  ]);

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl, _countryCtrl,
      _univCtrl, _majorCtrl, _yearCtrl, _gpaCtrl, _summaryCtrl,
      _skillCtrl, _langCtrl, _certCtrl, _interestCtrl,
    ]) { c.dispose(); }
    for (final g in _grades)      { g.dispose(); }
    for (final e in _experiences) { e.dispose(); }
    for (final p in _portfolio)   { p.dispose(); }
    super.dispose();
  }
}
