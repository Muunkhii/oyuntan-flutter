// lib/screens/cv/cv_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class CVScreen extends StatefulWidget {
  const CVScreen({super.key});
  @override
  State<CVScreen> createState() => _CVScreenState();
}

class _CVScreenState extends State<CVScreen> {
  // Controllers
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _univCtrl     = TextEditingController();
  final _majorCtrl    = TextEditingController();
  final _yearCtrl     = TextEditingController();
  final _gpaCtrl      = TextEditingController();
  final _summaryCtrl  = TextEditingController();
  final _skillCtrl    = TextEditingController();
  final _langCtrl     = TextEditingController();
  final _certCtrl     = TextEditingController();

  final List<String> _skills    = [];
  final List<String> _languages   = [];
  final List<String> _certs       = [];
  final List<_ExpItem> _experiences = [];

  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final auth    = context.read<AuthProvider>();
    final profile = auth.profile ?? {};
    final name    = '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
    _nameCtrl.text    = name;
    _emailCtrl.text   = profile['email']      as String? ?? '';
    _phoneCtrl.text   = profile['phone']      as String? ?? '';
    _univCtrl.text    = profile['university'] as String? ?? '';
    _majorCtrl.text   = profile['major']      as String? ?? '';
    _gpaCtrl.text     = profile['gpa']        as String? ?? '';
    _yearCtrl.text    = '${profile['year'] ?? ''}';
    _summaryCtrl.text = profile['bio']        as String? ?? '';
    _skills.addAll(List<String>.from((profile['skills'] as List?) ?? []));
    _languages.addAll(['Монгол', 'Англи']);
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _addressCtrl,
      _univCtrl, _majorCtrl, _yearCtrl, _gpaCtrl, _summaryCtrl,
      _skillCtrl, _langCtrl, _certCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── PDF generation ──────────────────────────────────────
  Future<pw.Document> _buildPdf() async {
    final doc  = pw.Document();
    // Bundled NotoSans font — Монгол кирилл үсгийг бүрэн дэмждэг
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final font = pw.Font.ttf(fontData);
    final bold = pw.Font.ttf(boldData);

    final blue  = PdfColor.fromHex('#2563EB');
    final dark  = PdfColor.fromHex('#1E293B');
    final grey  = PdfColor.fromHex('#64748B');
    final light = PdfColor.fromHex('#EFF6FF');
    const white = PdfColors.white;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) => [
          // ── Header ──────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 32, vertical: 28),
            color: blue,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Avatar circle
                pw.Container(
                  width: 70, height: 70,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(
                        color: white, width: 2),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    _nameCtrl.text.isNotEmpty
                        ? _nameCtrl.text[0].toUpperCase()
                        : 'О',
                    style: pw.TextStyle(
                        font: bold, fontSize: 28,
                        color: white),
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_nameCtrl.text,
                          style: pw.TextStyle(
                              font: bold, fontSize: 22,
                              color: white)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          '${_majorCtrl.text}${_univCtrl.text.isNotEmpty ? ' · ${_univCtrl.text}' : ''}',
                          style: pw.TextStyle(
                              font: font, fontSize: 11,
                              color: PdfColor.fromHex('#BFDBFE'))),
                      pw.SizedBox(height: 8),
                      pw.Row(children: [
                        if (_emailCtrl.text.isNotEmpty) ...[
                          pw.Text('✉ ${_emailCtrl.text}',
                              style: pw.TextStyle(
                                  font: font, fontSize: 9,
                                  color: PdfColor.fromHex('#DBEAFE'))),
                          pw.SizedBox(width: 16),
                        ],
                        if (_phoneCtrl.text.isNotEmpty)
                          pw.Text('✆ ${_phoneCtrl.text}',
                              style: pw.TextStyle(
                                  font: font, fontSize: 9,
                                  color: PdfColor.fromHex('#DBEAFE'))),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 32, vertical: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Summary
                if (_summaryCtrl.text.isNotEmpty) ...[
                  _pdfSection('Товч танилцуулга', blue, bold),
                  pw.Text(_summaryCtrl.text,
                      style: pw.TextStyle(
                          font: font, fontSize: 10,
                          color: grey, lineSpacing: 4)),
                  pw.SizedBox(height: 14),
                ],

                // Education
                _pdfSection('Боловсрол', blue, bold),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: light,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(_univCtrl.text,
                                style: pw.TextStyle(
                                    font: bold, fontSize: 11,
                                    color: dark)),
                            pw.SizedBox(height: 2),
                            pw.Text(_majorCtrl.text,
                                style: pw.TextStyle(
                                    font: font, fontSize: 10,
                                    color: grey)),
                          ]),
                      pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.end,
                          children: [
                            if (_yearCtrl.text.isNotEmpty)
                              pw.Text(
                                  '${_yearCtrl.text}-р курс',
                                  style: pw.TextStyle(
                                      font: font, fontSize: 10,
                                      color: blue)),
                            if (_gpaCtrl.text.isNotEmpty)
                              pw.Text('GPA: ${_gpaCtrl.text}',
                                  style: pw.TextStyle(
                                      font: bold, fontSize: 10,
                                      color: dark)),
                          ]),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Experience
                if (_experiences.isNotEmpty) ...[
                  _pdfSection('Ажлын туршлага', blue, bold),
                  ..._experiences.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Row(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 6, height: 6,
                          margin: const pw.EdgeInsets.only(
                              top: 4, right: 10),
                          decoration: pw.BoxDecoration(
                            color: blue,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  pw.Text(e.role,
                                      style: pw.TextStyle(
                                          font: bold,
                                          fontSize: 11,
                                          color: dark)),
                                  pw.Text(e.period,
                                      style: pw.TextStyle(
                                          font: font,
                                          fontSize: 9,
                                          color: grey)),
                                ],
                              ),
                              pw.Text(e.company,
                                  style: pw.TextStyle(
                                      font: font, fontSize: 10,
                                      color: blue)),
                              if (e.desc.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(e.desc,
                                    style: pw.TextStyle(
                                        font: font, fontSize: 9,
                                        color: grey,
                                        lineSpacing: 3)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                  pw.SizedBox(height: 6),
                ],

                // Skills
                if (_skills.isNotEmpty) ...[
                  _pdfSection('Ур чадвар', blue, bold),
                  pw.Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _skills.map((s) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: light,
                        borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(12)),
                        border: pw.Border.all(
                            color: PdfColor.fromHex('#BFDBFE'),
                            width: 0.5),
                      ),
                      child: pw.Text(s,
                          style: pw.TextStyle(
                              font: font, fontSize: 9,
                              color: blue)),
                    )).toList(),
                  ),
                  pw.SizedBox(height: 14),
                ],

                // Languages
                if (_languages.isNotEmpty) ...[
                  _pdfSection('Хэл', blue, bold),
                  pw.Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _languages.map((l) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F0FDF4'),
                        borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(12)),
                      ),
                      child: pw.Text(l,
                          style: pw.TextStyle(
                              font: font, fontSize: 9,
                              color: PdfColor.fromHex('#16A34A'))),
                    )).toList(),
                  ),
                  pw.SizedBox(height: 14),
                ],

                // Certifications
                if (_certs.isNotEmpty) ...[
                  _pdfSection('Гэрчилгээ & Амжилт', blue, bold),
                  ..._certs.map((c) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(children: [
                      pw.Container(
                        width: 5, height: 5,
                        margin: const pw.EdgeInsets.only(
                            top: 3, right: 8),
                        decoration: pw.BoxDecoration(
                          color: blue,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.Text(c,
                          style: pw.TextStyle(
                              font: font, fontSize: 10,
                              color: dark)),
                    ]),
                  )),
                ],

                // Footer
                pw.SizedBox(height: 24),
                pw.Divider(
                    color: PdfColor.fromHex('#E2E8F0'),
                    thickness: 0.5),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Оюунтан Платформаар үүсгэгдсэн · oyuntan.mn',
                    style: pw.TextStyle(
                        font: font, fontSize: 8,
                        color: PdfColor.fromHex('#94A3B8')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return doc;
  }

  pw.Widget _pdfSection(
      String title, PdfColor color, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(children: [
          pw.Container(width: 3, height: 14, color: color),
          pw.SizedBox(width: 8),
          pw.Text(title,
              style: pw.TextStyle(
                  font: bold, fontSize: 12,
                  color: PdfColor.fromHex('#1E293B'))),
        ]),
        pw.SizedBox(height: 8),
      ],
    );
  }

  Future<void> _generatePdf() async {
    setState(() => _generating = true);
    // Capture context-dependent values before any async gap
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    try {
      final doc  = await _buildPdf();
      final bytes = await doc.save();

      // Save to Firestore
      // uid already captured before async gap
      if (uid.isNotEmpty) {
        await CVService().saveCV(uid, {
          'name':        _nameCtrl.text,
          'email':       _emailCtrl.text,
          'phone':       _phoneCtrl.text,
          'address':     _addressCtrl.text,
          'university':  _univCtrl.text,
          'major':       _majorCtrl.text,
          'year':        _yearCtrl.text,
          'gpa':         _gpaCtrl.text,
          'summary':     _summaryCtrl.text,
          'skills':      _skills,
          'languages':   _languages,
          'certs':       _certs,
          'experiences': _experiences
              .map((e) => {'role': e.role, 'company': e.company,
                           'period': e.period, 'desc': e.desc})
              .toList(),
        });
      }

      // Print / Share / Download
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${_nameCtrl.text}_CV.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('PDF үүсгэхэд алдаа гарлаа: $e'),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  // ── Build UI ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('CV Maker'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        actions: [
          TextButton.icon(
            onPressed: _generating ? null : _generatePdf,
            icon: _generating
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.picture_as_pdf_rounded,
                    size: 18),
            label: Text(_generating ? 'Үүсгэж байна...' : 'PDF'),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(children: [
              Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Профессиональ CV үүсгэх',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text('Мэдээллээ бөглөж PDF татаж авна уу',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Хувийн мэдээлэл ─────────────────────────────
          _Section(
            title: 'Хувийн мэдээлэл',
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.primary,
            child: Column(children: [
              _Field('Бүтэн нэр', _nameCtrl,
                  hint: 'Жишээ: Мөнхбаяр Баяр'),
              _Field('Имэйл хаяг', _emailCtrl,
                  hint: 'example@mail.com',
                  type: TextInputType.emailAddress),
              _Field('Утасны дугаар', _phoneCtrl,
                  hint: '+976 9900 0000',
                  type: TextInputType.phone),
              _Field('Хаяг', _addressCtrl,
                  hint: 'Улаанбаатар, Монгол'),
            ]),
          ),

          // ── Боловсрол ────────────────────────────────────
          _Section(
            title: 'Боловсрол',
            icon: Icons.school_outlined,
            iconColor: AppColors.teal,
            child: Column(children: [
              _Field('Их сургуулийн нэр', _univCtrl,
                  hint: 'МУИС, ШУТИС, МУБИС...'),
              _Field('Мэргэжил', _majorCtrl,
                  hint: 'Програм хангамж, Дизайн...'),
              Row(children: [
                Expanded(child: _Field('Курс', _yearCtrl,
                    hint: '1-4',
                    type: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _Field('GPA', _gpaCtrl,
                    hint: '0.0 - 4.0',
                    type: const TextInputType.numberWithOptions(
                        decimal: true))),
              ]),
            ]),
          ),

          // ── Товч танилцуулга ─────────────────────────────
          _Section(
            title: 'Товч танилцуулга',
            icon: Icons.edit_note_rounded,
            iconColor: AppColors.purple,
            child: TextField(
              controller: _summaryCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Өөрийн давуу талыг, зорилгоо товч бичнэ үү...',
              ),
            ),
          ),

          // ── Ажлын туршлага ───────────────────────────────
          _Section(
            title: 'Ажлын туршлага & Дадлага',
            icon: Icons.work_outline_rounded,
            iconColor: AppColors.amber,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_rounded,
                  color: AppColors.primary),
              onPressed: _addExperience,
            ),
            child: _experiences.isEmpty
                ? const _EmptyPlaceholder(
                    icon: Icons.work_off_outlined,
                    text: '+ товч дарж туршлага нэмнэ үү',
                  )
                : Column(
                    children: _experiences.asMap().entries.map((e) =>
                        _ExperienceCard(
                          item: e.value,
                          onDelete: () =>
                              setState(() => _experiences.removeAt(e.key)),
                          onEdit: () => _editExperience(e.key),
                        )).toList(),
                  ),
          ),

          // ── Ур чадвар ────────────────────────────────────
          _Section(
            title: 'Ур чадвар',
            icon: Icons.code_rounded,
            iconColor: AppColors.coral,
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _skillCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Flutter, React, Figma...'),
                    onSubmitted: _addSkill,
                  ),
                ),
                const SizedBox(width: 8),
                _AddBtn(onTap: () => _addSkill(_skillCtrl.text)),
              ]),
              if (_skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ChipList(
                  items: _skills,
                  color: AppColors.primary,
                  bg: AppColors.primaryLight,
                  onRemove: (s) => setState(() => _skills.remove(s)),
                ),
              ],
            ]),
          ),

          // ── Хэл ──────────────────────────────────────────
          _Section(
            title: 'Хэл мэдлэг',
            icon: Icons.language_outlined,
            iconColor: AppColors.teal,
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _langCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Монгол, Англи, Хятад...'),
                    onSubmitted: _addLang,
                  ),
                ),
                const SizedBox(width: 8),
                _AddBtn(onTap: () => _addLang(_langCtrl.text)),
              ]),
              if (_languages.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ChipList(
                  items: _languages,
                  color: AppColors.teal,
                  bg: AppColors.tealLight,
                  onRemove: (s) => setState(() => _languages.remove(s)),
                ),
              ],
            ]),
          ),

          // ── Гэрчилгээ ────────────────────────────────────
          _Section(
            title: 'Гэрчилгээ & Амжилт',
            icon: Icons.military_tech_outlined,
            iconColor: AppColors.purple,
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _certCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Google UX Design, AWS...'),
                    onSubmitted: _addCert,
                  ),
                ),
                const SizedBox(width: 8),
                _AddBtn(onTap: () => _addCert(_certCtrl.text)),
              ]),
              if (_certs.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ChipList(
                  items: _certs,
                  color: AppColors.purple,
                  bg: AppColors.purpleLight,
                  onRemove: (s) => setState(() => _certs.remove(s)),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 24),

          // Generate button
          ElevatedButton.icon(
            onPressed: _generating ? null : _generatePdf,
            icon: _generating
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white))
                : const Icon(Icons.picture_as_pdf_rounded, size: 20),
            label: Text(_generating
                ? 'PDF үүсгэж байна...'
                : 'PDF үүсгэж татах'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'PDF-г татаж авсны дараа хуваалцах, хэвлэх боломжтой',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _addSkill(String s) {
    final v = s.trim();
    if (v.isNotEmpty && !_skills.contains(v)) {
      setState(() => _skills.add(v));
    }
    _skillCtrl.clear();
  }

  void _addLang(String s) {
    final v = s.trim();
    if (v.isNotEmpty && !_languages.contains(v)) {
      setState(() => _languages.add(v));
    }
    _langCtrl.clear();
  }

  void _addCert(String s) {
    final v = s.trim();
    if (v.isNotEmpty && !_certs.contains(v)) {
      setState(() => _certs.add(v));
    }
    _certCtrl.clear();
  }

  void _addExperience() => _showExpDialog(null);
  void _editExperience(int idx) => _showExpDialog(idx);

  void _showExpDialog(int? editIdx) {
    final roleCtrl    = TextEditingController(
        text: editIdx != null ? _experiences[editIdx].role : '');
    final companyCtrl = TextEditingController(
        text: editIdx != null ? _experiences[editIdx].company : '');
    final periodCtrl  = TextEditingController(
        text: editIdx != null ? _experiences[editIdx].period : '');
    final descCtrl    = TextEditingController(
        text: editIdx != null ? _experiences[editIdx].desc : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_outline_rounded,
                    color: AppColors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Text(editIdx != null
                  ? 'Туршлага засах' : 'Туршлага нэмэх',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 20),
            _Field('Албан тушаал / Дадлага', roleCtrl,
                hint: 'Frontend Developer'),
            _Field('Байгууллага', companyCtrl,
                hint: 'Компанийн нэр'),
            _Field('Хугацаа', periodCtrl,
                hint: '2024.06 - 2024.09'),
            _Field('Тодорхойлолт', descCtrl,
                hint: 'Хийсэн ажлаа товч тайлбарлана уу...',
                maxLines: 3),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (roleCtrl.text.trim().isEmpty) return;
                final item = _ExpItem(
                  role:    roleCtrl.text.trim(),
                  company: companyCtrl.text.trim(),
                  period:  periodCtrl.text.trim(),
                  desc:    descCtrl.text.trim(),
                );
                setState(() {
                  if (editIdx != null) {
                    _experiences[editIdx] = item;
                  } else {
                    _experiences.add(item);
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(editIdx != null ? 'Засах' : 'Нэмэх'),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────
class _ExpItem {
  final String role, company, period, desc;
  const _ExpItem({
    required this.role, required this.company,
    required this.period, required this.desc,
  });
}

// ── UI Widgets ────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? trailing;
  const _Section({
    required this.title, required this.icon,
    required this.iconColor, required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ]),
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final TextInputType? type;
  final int maxLines;
  const _Field(this.label, this.ctrl,
      {this.hint, this.type, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint ?? label),
      ),
    ]),
  );
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
    ),
  );
}

class _ChipList extends StatelessWidget {
  final List<String> items;
  final Color color, bg;
  final void Function(String) onRemove;
  const _ChipList({
    required this.items, required this.color,
    required this.bg, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6, runSpacing: 6,
    children: items.map((s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(s,
            style: TextStyle(
                fontSize: 12, color: color,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => onRemove(s),
          child: Icon(Icons.close_rounded, size: 13, color: color),
        ),
      ]),
    )).toList(),
  );
}

class _ExperienceCard extends StatelessWidget {
  final _ExpItem item;
  final VoidCallback onDelete, onEdit;
  const _ExperienceCard({
    required this.item, required this.onDelete, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.amberLight,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.3), width: 0.8),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 8, height: 8,
        margin: const EdgeInsets.only(top: 5),
        decoration: const BoxDecoration(
          color: AppColors.amber, shape: BoxShape.circle),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Expanded(child: Text(item.role,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary))),
          if (item.period.isNotEmpty)
            Text(item.period,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
        ]),
        if (item.company.isNotEmpty)
          Text(item.company,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.amber,
                  fontWeight: FontWeight.w600)),
        if (item.desc.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(item.desc,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary,
                  height: 1.4)),
        ],
      ])),
      Column(children: [
        GestureDetector(
          onTap: onEdit,
          child: const Icon(Icons.edit_outlined,
              size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onDelete,
          child: const Icon(Icons.delete_outline_rounded,
              size: 16, color: AppColors.red),
        ),
      ]),
    ]),
  );
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyPlaceholder({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textTertiary)),
      ]),
    ),
  );
}
