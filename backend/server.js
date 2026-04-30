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
app.use(express.json({ limit: '20mb' }));

// ── Startup migration ─────────────────────────────────────────
(async () => {
  const cols = [
    `ALTER TABLE students ADD COLUMN IF NOT EXISTS photo TEXT`,
    `ALTER TABLE students ADD COLUMN IF NOT EXISTS phone TEXT`,
    `ALTER TABLE students ADD COLUMN IF NOT EXISTS bio TEXT`,
    `ALTER TABLE students ADD COLUMN IF NOT EXISTS birth_date DATE`,
    `ALTER TABLE students ADD COLUMN IF NOT EXISTS country TEXT`,
    `ALTER TABLE students ADD COLUMN IF NOT EXISTS psych_profile JSONB`,
    `ALTER TABLE companies ADD COLUMN IF NOT EXISTS phone TEXT`,
    `ALTER TABLE companies ADD COLUMN IF NOT EXISTS employee_count INTEGER`,
    `ALTER TABLE companies ADD COLUMN IF NOT EXISTS founded_year INTEGER`,
    `ALTER TABLE companies ADD COLUMN IF NOT EXISTS history TEXT`,
    `ALTER TABLE companies ADD COLUMN IF NOT EXISTS photo TEXT`,
    `ALTER TABLE companies ADD COLUMN IF NOT EXISTS cover_photo TEXT`,
    `ALTER TABLE companies ADD COLUMN IF NOT EXISTS assessment_questions JSONB DEFAULT '[]'`,
    `CREATE TABLE IF NOT EXISTS assessment_responses (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       application_id UUID NOT NULL,
       company_id UUID NOT NULL,
       answers JSONB NOT NULL DEFAULT '[]',
       created_at TIMESTAMPTZ DEFAULT NOW()
     )`,
    `CREATE TABLE IF NOT EXISTS messages (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       sender_uid UUID NOT NULL,
       receiver_uid UUID NOT NULL,
       content TEXT NOT NULL,
       read BOOLEAN DEFAULT FALSE,
       created_at TIMESTAMPTZ DEFAULT NOW()
     )`,
    `CREATE TABLE IF NOT EXISTS interview_slots (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       application_id UUID NOT NULL,
       company_id UUID NOT NULL,
       student_id UUID NOT NULL,
       scheduled_at TIMESTAMPTZ NOT NULL,
       location TEXT,
       notes TEXT,
       status VARCHAR(20) DEFAULT 'proposed',
       created_at TIMESTAMPTZ DEFAULT NOW()
     )`,
    `ALTER TABLE internship_posts ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0`,
    `CREATE TABLE IF NOT EXISTS student_reviews (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       internship_id UUID NOT NULL,
       company_id UUID NOT NULL,
       student_id UUID NOT NULL,
       work_score INTEGER NOT NULL DEFAULT 0,
       attitude_score INTEGER NOT NULL DEFAULT 0,
       punctuality_score INTEGER NOT NULL DEFAULT 0,
       learning_score INTEGER NOT NULL DEFAULT 0,
       avg_score NUMERIC(3,1) NOT NULL DEFAULT 0,
       would_rehire BOOLEAN DEFAULT NULL,
       comment TEXT,
       created_at TIMESTAMPTZ DEFAULT NOW()
     )`,
  ];
  for (const sql of cols) {
    await pool.query(sql).catch(e => console.warn('Migration:', e.message));
  }
})();

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
  const { email, password, firstName, lastName, university, major,
          year, skills, phone, birthDate, country } = req.body;
  try {
    const hash = await bcrypt.hash(password, 10);
    const { rows: [user] } = await pool.query(
      `INSERT INTO users (email, password_hash, type) VALUES ($1, $2, 'student') RETURNING uid`,
      [email, hash]
    );
    await pool.query(
      `INSERT INTO students
         (uid, first_name, last_name, university, major, year, skills, phone, birth_date, country)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
      [user.uid, firstName, lastName, university, major,
       year || null, skills || [],
       phone || null,
       birthDate ? birthDate.substring(0, 10) : null,
       country || null]
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
  const { firstName, lastName, university, major, year, skills, bio, photo, phone, psychProfile } = req.body;
  try {
    await pool.query(
      `UPDATE students SET
        first_name   = COALESCE($1,  first_name),
        last_name    = COALESCE($2,  last_name),
        university   = COALESCE($3,  university),
        major        = COALESCE($4,  major),
        year         = COALESCE($5,  year),
        skills       = COALESCE($6,  skills),
        bio          = COALESCE($7,  bio),
        photo        = COALESCE($8,  photo),
        phone        = COALESCE($9,  phone),
        psych_profile= COALESCE($10, psych_profile)
       WHERE uid = $11`,
      [firstName ?? null, lastName ?? null, university ?? null, major ?? null,
       year ?? null, skills ?? null, bio ?? null, photo ?? null,
       phone ?? null, psychProfile ? JSON.stringify(psychProfile) : null,
       req.params.uid]
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
  const { name, industry, description, location, website, logoUrl,
          phone, employeeCount, foundedYear, history, photo, coverPhoto } = req.body;
  try {
    await pool.query(
      `UPDATE companies SET
        name           = COALESCE($1,  name),
        industry       = COALESCE($2,  industry),
        description    = COALESCE($3,  description),
        location       = COALESCE($4,  location),
        website        = COALESCE($5,  website),
        logo_url       = COALESCE($6,  logo_url),
        phone          = COALESCE($7,  phone),
        employee_count = COALESCE($8,  employee_count),
        founded_year   = COALESCE($9,  founded_year),
        history        = COALESCE($10, history),
        photo          = COALESCE($11, photo),
        cover_photo    = COALESCE($12, cover_photo)
       WHERE uid = $13`,
      [name ?? null, industry ?? null, description ?? null,
       location ?? null, website ?? null, logoUrl ?? null,
       phone ?? null, employeeCount ?? null, foundedYear ?? null,
       history ?? null, photo ?? null, coverPhoto ?? null,
       req.params.uid]
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
      `SELECT p.*, c.name as company_name, c.industry, c.description as company_description,
              c.location as company_location, c.website, c.logo_url, c.avg_score, c.review_count
       FROM internship_posts p
       JOIN companies c ON c.uid = p.company_id WHERE p.id = $1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ message: 'Олдсонгүй' });
    res.json(rows[0]);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// DELETE /posts/:id  – soft-delete if active internships exist, hard-delete otherwise
app.delete('/posts/:id', auth, async (req, res) => {
  const { id } = req.params;
  try {
    const { rows: active } = await pool.query(
      `SELECT COUNT(*) as cnt FROM internships WHERE post_id = $1 AND status = 'active'`,
      [id]
    );
    if (parseInt(active[0].cnt) > 0) {
      await pool.query(`UPDATE internship_posts SET is_active = FALSE WHERE id = $1`, [id]);
    } else {
      await pool.query(`DELETE FROM internship_posts WHERE id = $1`, [id]);
    }
    res.json({ message: 'Устгагдлаа' });
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
    // Reject if student already has an active internship
    const { rows: active } = await pool.query(
      `SELECT COUNT(*) as cnt FROM internships WHERE student_id = $1 AND status = 'active'`,
      [studentId]
    );
    if (parseInt(active[0].cnt) > 0) {
      return res.status(400).json({ message: 'Одоогийн дадлагаа дуусгасны дараа шинэ дадлагад өргөдөл гаргана уу.' });
    }
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
      `SELECT a.*, s.first_name, s.last_name, s.university, s.major, s.skills, s.bio, s.year,
              s.photo as student_photo,
              p.title as post_title, c.name as company_name, c.photo as company_photo,
              c.industry as company_industry
       FROM applications a
       JOIN students s ON s.uid = a.student_id
       LEFT JOIN internship_posts p ON p.id = a.post_id
       LEFT JOIN companies c ON c.uid = a.company_id
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
    const { rows } = await pool.query(
      `UPDATE applications SET status = 'rejected' WHERE id = $1 RETURNING student_id, post_id`,
      [req.params.id]
    );
    if (rows.length) {
      await pool.query(
        `INSERT INTO notifications (to_uid, type, post_id) VALUES ($1, 'application_rejected', $2)`,
        [rows[0].student_id, rows[0].post_id]
      );
    }
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
      q = `SELECT i.*, s.first_name, s.last_name, s.photo, s.university, s.major, p.title FROM internships i
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

// PUT /internships/:id/terminate — хугацаанаас өмнө дуусгах
app.put('/internships/:id/terminate', auth, async (req, res) => {
  const { reason } = req.body;
  const terminatedBy = req.user.type; // 'student' | 'company'
  try {
    const { rows } = await pool.query(
      `UPDATE internships
         SET status = 'terminated', terminated_by = $1, termination_reason = $2
       WHERE id = $3
       RETURNING *`,
      [terminatedBy, reason || '', req.params.id]
    );
    if (!rows.length) return res.status(404).json({ message: 'Олдсонгүй' });
    // нөгөө талд мэдэгдэл илгээх
    const intern = rows[0];
    const notifyUid = terminatedBy === 'company' ? intern.student_id : intern.company_id;
    await pool.query(
      `INSERT INTO notifications (to_uid, type) VALUES ($1, 'internship_terminated')`,
      [notifyUid]
    );
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
  const avg = parseFloat(((envScore + mentorScore + learnScore + relationScore) / 4).toFixed(1));
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
      [parseFloat(parseFloat(all[0].avg).toFixed(1)), parseInt(all[0].cnt), companyId]
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
// STUDENT REVIEWS (компани → оюутан)
// ═══════════════════════════════════════════════════════════════

app.post('/student-reviews', auth, async (req, res) => {
  const { internshipId, studentId, workScore, attitudeScore, punctualityScore, learningScore, wouldRehire, comment } = req.body;
  const companyId = req.user.uid;
  const avg = parseFloat(((workScore + attitudeScore + punctualityScore + learningScore) / 4).toFixed(1));
  try {
    const { rows: [rev] } = await pool.query(
      `INSERT INTO student_reviews
         (internship_id, company_id, student_id, work_score, attitude_score, punctuality_score, learning_score, avg_score, would_rehire, comment)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [internshipId, companyId, studentId, workScore, attitudeScore, punctualityScore, learningScore, avg, wouldRehire, comment]
    );
    // дадлагыг completed болгох (terminated биш бол)
    await pool.query(
      `UPDATE internships SET status = 'completed' WHERE id = $1 AND status != 'terminated'`,
      [internshipId]
    );
    res.json(rev);
  } catch (e) {
    if (e.code === '23505') return res.status(400).json({ message: 'Аль хэдийн үнэлсэн' });
    res.status(500).json({ message: e.message });
  }
});

app.get('/student-reviews', auth, async (req, res) => {
  const { internshipId, studentId } = req.query;
  try {
    let q, params;
    if (internshipId) {
      q = 'SELECT * FROM student_reviews WHERE internship_id = $1';
      params = [internshipId];
    } else {
      q = `SELECT sr.*, c.name as company_name FROM student_reviews sr
           JOIN companies c ON c.uid = sr.company_id
           WHERE sr.student_id = $1 ORDER BY sr.created_at DESC`;
      params = [studentId];
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
// CLASS SCHEDULES
// ═══════════════════════════════════════════════════════════════

app.get('/schedules', auth, async (req, res) => {
  const studentId = req.query.studentId || req.user.uid;
  try {
    const { rows } = await pool.query(
      `SELECT * FROM class_schedules WHERE student_id = $1 ORDER BY day, start_hour, start_min`,
      [studentId]
    );
    // Return in Flutter-friendly camelCase format
    res.json(rows.map(r => ({
      id: r.id, day: r.day, subject: r.subject,
      startHour: r.start_hour, startMin: r.start_min,
      endHour: r.end_hour,   endMin: r.end_min,
      room: r.room, teacher: r.teacher, type: r.type,
    })));
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.put('/schedules', auth, async (req, res) => {
  const items = Array.isArray(req.body) ? req.body : [];
  const studentId = req.user.uid;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM class_schedules WHERE student_id = $1', [studentId]);
    for (const item of items) {
      await client.query(
        `INSERT INTO class_schedules
           (student_id, day, subject, start_hour, start_min, end_hour, end_min, room, teacher, type)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
        [studentId, item.day, item.subject,
         item.startHour ?? 8, item.startMin ?? 0,
         item.endHour ?? 9,   item.endMin ?? 0,
         item.room || null, item.teacher || null, item.type || 'Лекц']
      );
    }
    await client.query('COMMIT');
    res.json({ message: 'Хуваарь хадгалагдлаа' });
  } catch (e) {
    await client.query('ROLLBACK');
    res.status(500).json({ message: e.message });
  } finally { client.release(); }
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

// ═══════════════════════════════════════════════════════════════
// POST VIEW TRACKING
// ═══════════════════════════════════════════════════════════════
app.post('/posts/:id/view', auth, async (req, res) => {
  try {
    await pool.query(
      `UPDATE internship_posts SET view_count = COALESCE(view_count,0) + 1 WHERE id = $1`,
      [req.params.id]
    );
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// MESSAGES
// ═══════════════════════════════════════════════════════════════
app.get('/messages/unread-count', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT COUNT(*) as count FROM messages WHERE receiver_uid=$1 AND read=FALSE`,
      [req.user.uid]
    );
    res.json({ count: parseInt(rows[0].count) });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.get('/messages/conversations', auth, async (req, res) => {
  try {
    const uid = req.user.uid;
    const { rows } = await pool.query(
      `SELECT DISTINCT ON (other_uid)
         other_uid,
         (SELECT name FROM companies WHERE uid=other_uid)   as company_name,
         (SELECT CONCAT(first_name,' ',last_name) FROM students WHERE uid=other_uid) as student_name,
         (SELECT photo FROM companies WHERE uid=other_uid)  as company_photo,
         (SELECT photo FROM students  WHERE uid=other_uid)  as student_photo,
         m.content as last_message,
         m.created_at,
         (SELECT COUNT(*) FROM messages WHERE sender_uid=other_uid AND receiver_uid=$1 AND read=FALSE) as unread
       FROM (
         SELECT CASE WHEN sender_uid=$1 THEN receiver_uid ELSE sender_uid END as other_uid,
                content, created_at
         FROM messages WHERE sender_uid=$1 OR receiver_uid=$1
       ) m
       ORDER BY other_uid, m.created_at DESC`,
      [uid]
    );
    res.json(rows);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.get('/messages', auth, async (req, res) => {
  const { with: withUid } = req.query;
  const uid = req.user.uid;
  try {
    const { rows } = await pool.query(
      `SELECT * FROM messages
       WHERE (sender_uid=$1 AND receiver_uid=$2) OR (sender_uid=$2 AND receiver_uid=$1)
       ORDER BY created_at ASC`,
      [uid, withUid]
    );
    await pool.query(
      `UPDATE messages SET read=TRUE WHERE sender_uid=$2 AND receiver_uid=$1 AND read=FALSE`,
      [uid, withUid]
    );
    res.json(rows);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.post('/messages', auth, async (req, res) => {
  const { toUid, content } = req.body;
  try {
    const { rows: [msg] } = await pool.query(
      `INSERT INTO messages (sender_uid, receiver_uid, content) VALUES ($1,$2,$3) RETURNING *`,
      [req.user.uid, toUid, content]
    );
    res.json(msg);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// INTERVIEW SLOTS
// ═══════════════════════════════════════════════════════════════
app.post('/interview-slots', auth, async (req, res) => {
  const { applicationId, studentId, scheduledAt, location, notes } = req.body;
  try {
    const { rows: [slot] } = await pool.query(
      `INSERT INTO interview_slots (application_id, company_id, student_id, scheduled_at, location, notes)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [applicationId, req.user.uid, studentId, scheduledAt, location || null, notes || null]
    );
    await pool.query(
      `INSERT INTO notifications (to_uid, type, post_id) VALUES ($1,'interview_scheduled',$2)`,
      [studentId, applicationId]
    );
    res.json(slot);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.get('/interview-slots', auth, async (req, res) => {
  const { applicationId, studentId } = req.query;
  try {
    const conds = [], params = [];
    if (applicationId) { params.push(applicationId); conds.push(`application_id=$${params.length}`); }
    if (studentId)     { params.push(studentId);     conds.push(`student_id=$${params.length}`); }
    const where = conds.length ? 'WHERE ' + conds.join(' AND ') : '';
    const { rows } = await pool.query(
      `SELECT * FROM interview_slots ${where} ORDER BY scheduled_at ASC`, params
    );
    res.json(rows);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.put('/interview-slots/:id', auth, async (req, res) => {
  const { status } = req.body;
  try {
    await pool.query(`UPDATE interview_slots SET status=$1 WHERE id=$2`, [status, req.params.id]);
    res.json({ message: 'ok' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ═══════════════════════════════════════════════════════════════
// ASSESSMENT
// ═══════════════════════════════════════════════════════════════

app.get('/companies/:uid/assessment', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT assessment_questions FROM companies WHERE uid = $1`, [req.params.uid]
    );
    if (!rows.length) return res.json({ questions: [] });
    res.json({ questions: rows[0].assessment_questions || [] });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.put('/companies/:uid/assessment', auth, async (req, res) => {
  const { questions } = req.body;
  try {
    await pool.query(
      `UPDATE companies SET assessment_questions = $1 WHERE uid = $2`,
      [JSON.stringify(questions || []), req.params.uid]
    );
    res.json({ message: 'Шалгалт хадгалагдлаа' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.post('/assessment-responses', auth, async (req, res) => {
  const { applicationId, companyId, answers } = req.body;
  try {
    const existing = await pool.query(
      `SELECT id FROM assessment_responses WHERE application_id = $1`, [applicationId]
    );
    if (existing.rows.length) {
      await pool.query(
        `UPDATE assessment_responses SET answers = $1 WHERE application_id = $2`,
        [JSON.stringify(answers || []), applicationId]
      );
    } else {
      await pool.query(
        `INSERT INTO assessment_responses (application_id, company_id, answers)
         VALUES ($1, $2, $3)`,
        [applicationId, companyId, JSON.stringify(answers || [])]
      );
    }
    res.json({ message: 'Хариулт хадгалагдлаа' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

app.get('/assessment-responses/:applicationId', auth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT * FROM assessment_responses WHERE application_id = $1`,
      [req.params.applicationId]
    );
    if (!rows.length) return res.status(404).json({ message: 'Олдсонгүй' });
    res.json(rows[0]);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ─────────────────────────────────────────────────────────────
app.listen(PORT, () => console.log(`Oyuntan API → http://localhost:${PORT}`));
