// Oyuntan Backend - Express + PostgreSQL
require('dotenv').config();
const express  = require('express');
const cors     = require('cors');
const bcrypt   = require('bcryptjs');
const jwt      = require('jsonwebtoken');
const pool     = require('./db');

const app  = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'change_this_secret';

app.use(cors());
app.use(express.json());

// ── JWT middleware ─────────────────────────────────────────────
function auth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) return res.status(401).json({ message: 'Нэвтрэх шаардлагатай' });
  try {
    req.user = jwt.verify(header.slice(7), JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ message: 'Token хүчинтэй биш' });
  }
}

function makeToken(uid, type) {
  return jwt.sign({ uid, type }, JWT_SECRET, { expiresIn: '30d' });
}

// ═══════════════════════════════════════════════════════════════
// AUTH
// ═══════════════════════════════════════════════════════════════

// POST /auth/register/student
app.post('/auth/register/student', async (req, res) => {
  const { email, password, firstName, lastName, university, major, year, skills } = req.body;
  try {
    const hash = await bcrypt.hash(password, 10);
    const { rows: [user] } = await pool.query(
      `INSERT INTO users (email, password_hash, type) VALUES ($1, $2, 'student') RETURNING uid`,
      [email, hash]
    );
    await pool.query(
      `INSERT INTO students (uid, first_name, last_name, university, major, year, skills)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [user.uid, firstName, lastName, university, major, year || null, skills || []]
    );
    const token = makeToken(user.uid, 'student');
    res.json({ token, uid: user.uid, type: 'student' });
  } catch (e) {
    if (e.code === '23505') return res.status(400).json({ message: 'Имэйл аль хэдийн бүртгэлтэй' });
    res.status(500).json({ message: e.message });
  }
});

// POST /auth/register/company
app.post('/auth/register/company', async (req, res) => {
  const { email, password, name, industry, description, location, website } = req.body;
  try {
    const hash = await bcrypt.hash(password, 10);
    const { rows: [user] } = await pool.query(
      `INSERT INTO users (email, password_hash, type) VALUES ($1, $2, 'company') RETURNING uid`,
      [email, hash]
    );
    await pool.query(
      `INSERT INTO companies (uid, name, industry, description, location, website)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [user.uid, name, industry, description, location, website]
    );
    const token = makeToken(user.uid, 'company');
    res.json({ token, uid: user.uid, type: 'company' });
  } catch (e) {
    if (e.code === '23505') return res.status(400).json({ message: 'Имэйл аль хэдийн бүртгэлтэй' });
    res.status(500).json({ message: e.message });
  }
});

// POST /auth/login
app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (!rows.length) return res.status(400).json({ message: 'Хэрэглэгч олдсонгүй' });
    const user = rows[0];
    const ok   = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(400).json({ message: 'Имэйл эсвэл нууц үг буруу' });
    const token = makeToken(user.uid, user.type);
    res.json({ token, uid: user.uid, type: user.type });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// GET /auth/me
app.get('/auth/me', auth, async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT uid, email, type, language FROM users WHERE uid = $1', [req.user.uid]);
    if (!rows.length) return res.status(404).json({ message: 'Хэрэглэгч олдсонгүй' });
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// PUT /auth/change-password
app.put('/auth/change-password', auth, async (req, res) => {
  const { newPassword } = req.body;
  try {
    const hash = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE users SET password_hash = $1 WHERE uid = $2', [hash, req.user.uid]);
    res.json({ message: 'Нууц үг шинэчлэгдлээ' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ═══════════════════════════════════════════════════════════════
// STUDENTS
// ═══════════════════════════════════════════════════════════════

app.get('/students/:uid', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT s.*, u.email FROM students s JOIN users u ON u.uid = s.uid WHERE s.uid = $1`,
      [req.params.uid]
    );
    if (!rows.length) return res.status(404).json({ message: 'Олдсонгүй' });
    res.json(rows[0]);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.put('/students/:uid', auth, async (req, res) => {
  const { firstName, lastName, university, major, year, skills, bio, avatarUrl } = req.body;
  try {
    await pool.query(
      `UPDATE students SET first_name=$1, last_name=$2, university=$3, major=$4,
       year=$5, skills=$6, bio=$7, avatar_url=$8 WHERE uid=$9`,
      [firstName, lastName, university, major, year, skills || [], bio, avatarUrl, req.params.uid]
    );
    res.json({ message: 'Шинэчлэгдлээ' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// COMPANIES
// ═══════════════════════════════════════════════════════════════

app.get('/companies/:uid', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT c.*, u.email FROM companies c JOIN users u ON u.uid = c.uid WHERE c.uid = $1`,
      [req.params.uid]
    );
    if (!rows.length) return res.status(404).json({ message: 'Олдсонгүй' });
    res.json(rows[0]);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.put('/companies/:uid', auth, async (req, res) => {
  const { name, industry, description, location, website, logoUrl } = req.body;
  try {
    await pool.query(
      `UPDATE companies SET name=$1, industry=$2, description=$3,
       location=$4, website=$5, logo_url=$6 WHERE uid=$7`,
      [name, industry, description, location, website, logoUrl, req.params.uid]
    );
    res.json({ message: 'Шинэчлэгдлээ' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// INTERNSHIP POSTS
// ═══════════════════════════════════════════════════════════════

// POST /posts
app.post('/posts', auth, async (req, res) => {
  const { title, description, location, durationDays, requiredSkills, salary } = req.body;
  try {
    const { rows: [post] } = await pool.query(
      `INSERT INTO internship_posts (company_id, title, description, location, duration_days, required_skills, salary)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [req.user.uid, title, description, location, durationDays, requiredSkills || [], salary]
    );
    res.json(post);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// GET /posts  (feed - бүх идэвхтэй зар)
app.get('/posts', auth, async (req, res) => {
  try {
    const companyId = req.query.companyId;
    let q, params;
    if (companyId) {
      q = `SELECT p.*, c.name as company_name, c.logo_url
           FROM internship_posts p JOIN companies c ON c.uid = p.company_id
           WHERE p.company_id = $1 ORDER BY p.created_at DESC`;
      params = [companyId];
    } else {
      q = `SELECT p.*, c.name as company_name, c.logo_url
           FROM internship_posts p JOIN companies c ON c.uid = p.company_id
           WHERE p.is_active = TRUE ORDER BY p.created_at DESC`;
      params = [];
    }
    const { rows } = await pool.query(q, params);
    res.json(rows);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// GET /posts/:id
app.get('/posts/:id', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT p.*, c.name as company_name FROM internship_posts p
       JOIN companies c ON c.uid = p.company_id WHERE p.id = $1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ message: 'Олдсонгүй' });
    res.json(rows[0]);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// APPLICATIONS
// ═══════════════════════════════════════════════════════════════

// POST /applications
app.post('/applications', auth, async (req, res) => {
  const { postId, companyId, message } = req.body;
  const studentId = req.user.uid;
  try {
    const { rows: [app_] } = await pool.query(
      `INSERT INTO applications (post_id, student_id, company_id, message)
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [postId, studentId, companyId, message]
    );
    await pool.query('UPDATE internship_posts SET applicant_count = applicant_count + 1 WHERE id = $1', [postId]);
    await pool.query(
      `INSERT INTO notifications (to_uid, type, post_id, student_id)
       VALUES ($1, 'new_application', $2, $3)`,
      [companyId, postId, studentId]
    );
    res.json(app_);
  } catch (e) {
    if (e.code === '23505') return res.status(400).json({ message: 'Аль хэдийн хүсэлт илгээсэн' });
    res.status(500).json({ message: e.message });
  }
});

// GET /applications?postId=xx&companyId=xx&status=pending
app.get('/applications', auth, async (req, res) => {
  const { postId, studentId, status, companyId } = req.query;
  try {
    let conditions = [];
    let params = [];
    if (postId)    { params.push(postId);    conditions.push(`a.post_id = $${params.length}`); }
    if (studentId) { params.push(studentId); conditions.push(`a.student_id = $${params.length}`); }
    if (status)    { params.push(status);    conditions.push(`a.status = $${params.length}`); }
    if (companyId) { params.push(companyId); conditions.push(`a.company_id = $${params.length}`); }
    const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
    const { rows } = await pool.query(
      `SELECT a.*, s.first_name, s.last_name, s.university, s.major, s.skills,
              p.title as post_title
       FROM applications a
       JOIN students s ON s.uid = a.student_id
       LEFT JOIN internship_posts p ON p.id = a.post_id
       ${where}
       ORDER BY a.created_at DESC`,
      params
    );
    res.json(rows);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// PUT /applications/:id/accept
app.put('/applications/:id/accept', auth, async (req, res) => {
  const { studentId, postId, durationDays } = req.body;
  try {
    await pool.query(`UPDATE applications SET status = 'accepted' WHERE id = $1`, [req.params.id]);
    const endDate = new Date(Date.now() + durationDays * 86400000);
    const { rows: [intern] } = await pool.query(
      `INSERT INTO internships (student_id, post_id, company_id, duration_days, end_date)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [studentId, postId, req.user.uid, durationDays, endDate]
    );
    await pool.query(
      `INSERT INTO notifications (to_uid, type, post_id) VALUES ($1, 'application_accepted', $2)`,
      [studentId, postId]
    );
    res.json(intern);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// PUT /applications/:id/reject
app.put('/applications/:id/reject', auth, async (req, res) => {
  try {
    await pool.query(`UPDATE applications SET status = 'rejected' WHERE id = $1`, [req.params.id]);
    res.json({ message: 'Татгалзлаа' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// INTERNSHIPS
// ═══════════════════════════════════════════════════════════════

app.get('/internships', auth, async (req, res) => {
  const { studentId, companyId } = req.query;
  try {
    let q, params;
    if (studentId) {
      q = `SELECT i.*, p.title, c.name as company_name FROM internships i
           JOIN internship_posts p ON p.id = i.post_id
           JOIN companies c ON c.uid = i.company_id
           WHERE i.student_id = $1 ORDER BY i.start_date DESC`;
      params = [studentId];
    } else {
      q = `SELECT i.*, s.first_name, s.last_name, p.title FROM internships i
           JOIN students s ON s.uid = i.student_id
           JOIN internship_posts p ON p.id = i.post_id
           WHERE i.company_id = $1 ORDER BY i.start_date DESC`;
      params = [companyId];
    }
    const { rows } = await pool.query(q, params);
    res.json(rows);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.get('/internships/:id', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT i.*, p.title, c.name as company_name FROM internships i
       JOIN internship_posts p ON p.id = i.post_id
       JOIN companies c ON c.uid = i.company_id
       WHERE i.id = $1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ message: 'Олдсонгүй' });
    res.json(rows[0]);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// DIARY
// ═══════════════════════════════════════════════════════════════

app.post('/diary', auth, async (req, res) => {
  const { internshipId, dayNumber, workDone, mood, interactions, categories } = req.body;
  try {
    const { rows: [entry] } = await pool.query(
      `INSERT INTO diary_entries (internship_id, student_id, day_number, work_done, mood, interactions, categories)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [internshipId, req.user.uid, dayNumber, workDone, mood, interactions, categories || []]
    );
    await pool.query(
      'UPDATE internships SET completed_days = completed_days + 1 WHERE id = $1',
      [internshipId]
    );
    res.json(entry);
  } catch (e) {
    if (e.code === '23505') return res.status(400).json({ message: 'Тэмдэглэл аль хэдийн байна' });
    res.status(500).json({ message: e.message });
  }
});

app.get('/diary', auth, async (req, res) => {
  const { internshipId } = req.query;
  try {
    const { rows } = await pool.query(
      'SELECT * FROM diary_entries WHERE internship_id = $1 ORDER BY day_number',
      [internshipId]
    );
    res.json(rows);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// REVIEWS
// ═══════════════════════════════════════════════════════════════

app.post('/reviews', auth, async (req, res) => {
  const { internshipId, companyId, envScore, mentorScore, learnScore, relationScore, wouldReturn, comment } = req.body;
  const avg = ((envScore + mentorScore + learnScore + relationScore) / 4).toFixed(1);
  try {
    const { rows: [review] } = await pool.query(
      `INSERT INTO reviews (internship_id, student_id, company_id, env_score, mentor_score,
        learn_score, relation_score, avg_score, would_return, comment)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [internshipId, req.user.uid, companyId, envScore, mentorScore, learnScore, relationScore, avg, wouldReturn, comment]
    );
    await pool.query(`UPDATE internships SET status = 'completed' WHERE id = $1`, [internshipId]);
    // компанийн дундаж оноо шинэчлэх
    const { rows: all } = await pool.query(
      'SELECT AVG(avg_score) as avg, COUNT(*) as cnt FROM reviews WHERE company_id = $1',
      [companyId]
    );
    await pool.query(
      'UPDATE companies SET avg_score = $1, review_count = $2 WHERE uid = $3',
      [parseFloat(all[0].avg).toFixed(1), parseInt(all[0].cnt), companyId]
    );
    res.json(review);
  } catch (e) {
    if (e.code === '23505') return res.status(400).json({ message: 'Аль хэдийн үнэлсэн' });
    res.status(500).json({ message: e.message });
  }
});

app.get('/reviews', auth, async (req, res) => {
  const { companyId, internshipId } = req.query;
  try {
    let q, params;
    if (internshipId) {
      q = 'SELECT * FROM reviews WHERE internship_id = $1';
      params = [internshipId];
    } else {
      q = `SELECT r.*, s.first_name, s.last_name FROM reviews r
           JOIN students s ON s.uid = r.student_id
           WHERE r.company_id = $1 ORDER BY r.created_at DESC`;
      params = [companyId];
    }
    const { rows } = await pool.query(q, params);
    res.json(rows);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// CVs
// ═══════════════════════════════════════════════════════════════

app.get('/cvs/:studentId', auth, async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM cvs WHERE student_id = $1', [req.params.studentId]);
    res.json(rows[0] || null);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.put('/cvs/:studentId', auth, async (req, res) => {
  try {
    await pool.query(
      `INSERT INTO cvs (student_id, data, updated_at) VALUES ($1, $2, NOW())
       ON CONFLICT (student_id) DO UPDATE SET data = $2, updated_at = NOW()`,
      [req.params.studentId, req.body]
    );
    res.json({ message: 'CV хадгалагдлаа' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// NOTIFICATIONS
// ═══════════════════════════════════════════════════════════════

app.get('/notifications', auth, async (req, res) => {
  const uid = req.query.uid || req.user.uid;
  try {
    const { rows } = await pool.query(
      'SELECT * FROM notifications WHERE to_uid = $1 ORDER BY created_at DESC',
      [uid]
    );
    res.json(rows);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.get('/notifications/unread-count', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT COUNT(*) as count FROM notifications WHERE to_uid = $1 AND read = FALSE',
      [req.user.uid]
    );
    res.json({ count: parseInt(rows[0].count) });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.put('/notifications/:id/read', auth, async (req, res) => {
  try {
    await pool.query('UPDATE notifications SET read = TRUE WHERE id = $1', [req.params.id]);
    res.json({ message: 'ok' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.put('/notifications/read-all', auth, async (req, res) => {
  try {
    await pool.query(
      'UPDATE notifications SET read = TRUE WHERE to_uid = $1 AND read = FALSE',
      [req.user.uid]
    );
    res.json({ message: 'ok' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ─────────────────────────────────────────────────────────────
app.listen(PORT, () => console.log(`Oyuntan API → http://localhost:${PORT}`));
