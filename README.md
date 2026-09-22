# EduResult — Student Result Management System

**"Your Results. Your Progress. Your Future."**

A web-based result portal built with **HTML, CSS, JavaScript, PHP and MySQL**, designed to run on
**XAMPP**. Students log in to see their marksheet, SGPA/CGPA and a performance analysis; the
examination cell manages students, subjects, marks and publication from an admin panel.

---

## 1. Running the project on XAMPP

1. **Install XAMPP** from apachefriends.org (PHP 7.4 or newer).
2. Open the **XAMPP Control Panel** and click **Start** next to **Apache**.
3. Click **Start** next to **MySQL**.
4. Copy the whole `EduResult` folder into the XAMPP `htdocs` folder:
   - Windows: `C:\xampp\htdocs\EduResult`
   - macOS: `/Applications/XAMPP/htdocs/EduResult`
5. Open **phpMyAdmin** at <http://localhost/phpmyadmin>.
6. Click the **Import** tab, choose **`database/eduresult.sql`**, and click **Go**.
   The file creates the `eduresult` database by itself — you do not need to create it first.
7. If your MySQL has a password, open `includes/config.php` and edit `DB_USER` / `DB_PASS`.
   On a default XAMPP install, user is `root` and the password is empty, so nothing needs changing.
8. Open the project in a browser:

```
http://localhost/EduResult/
```

### Demo logins

| Role    | Username / Roll number | Password     |
|---------|------------------------|--------------|
| Admin   | `admin`                | `admin123`   |
| Student | `CSE2021001`           | `student123` |
| Student | `CSE2021002`           | `student123` |
| Student | `CSE2021003`           | `student123` |
| Student | `AID2021004`           | `student123` |
| Student | `ECE2021005`           | `student123` |
| Student | `EEE2021006`           | `student123` |

`CSE2021003` has semester 4 left in **Draft**, so you can demonstrate the publish workflow.
`ECE2021005` has one failed subject, so you can demonstrate a **FAIL** result.

---

## 2. Folder structure

```
EduResult/
├── index.php            home page
├── login.php            student login
├── register.php         student registration
├── logout.php
├── dashboard.php        student dashboard
├── result.php           marksheet + print / save as PDF
├── semesters.php        My Academic Journey
├── performance.php      performance analysis
├── profile.php          profile + password change
├── search-result.php    public result check
│
├── admin/
│   ├── login.php        admin login
│   ├── dashboard.php    admin dashboard
│   ├── students.php     student CRUD
│   ├── subjects.php     subject CRUD
│   ├── results.php      marks entry, grading, publishing
│   ├── semesters.php    SGPA / CGPA overview
│   └── logout.php
│
├── includes/
│   ├── config.php       database connection + all helper functions
│   ├── header.php       shared header (public / student / admin layouts)
│   ├── footer.php
│   └── auth.php         session handling and page guards
│
├── css/style.css
├── js/script.js
├── images/
└── database/eduresult.sql
```

---

## 3. Marks and grading rules

- Internal marks: **0 – 25**, external marks: **0 – 75**, total out of **100**
- A subject is cleared at **40** marks
- `SGPA = Σ(credit × grade point) ÷ Σcredits`
- `CGPA` uses the same formula over every subject up to that semester

| Total marks | Grade | Grade point |
|-------------|-------|-------------|
| 90 – 100    | O     | 10 |
| 80 – 89     | A+    | 9  |
| 70 – 79     | A     | 8  |
| 60 – 69     | B+    | 7  |
| 50 – 59     | B     | 6  |
| 40 – 49     | C     | 5  |
| below 40    | F     | 0  |

To change the grading scale, edit **one function**: `calculateGrade()` in `includes/config.php`
(and the matching `grade()` function in `js/script.js`, which only powers the live preview).

---

## 4. Common problems

| Problem | Fix |
|---------|-----|
| "Database connection failed" | MySQL is not started in XAMPP, or the SQL file was never imported. |
| Port 80 is busy | Change Apache's port in XAMPP, or stop Skype / IIS. |
| Blank page | Check `C:\xampp\apache\logs\error.log`. |
| Student sees "no published result" | The marks are still in **Draft**. Publish them from Admin → Result Management. |
| SGPA looks wrong after editing SQL by hand | Admin → SGPA / CGPA → **Recalculate all**. |

---

## 5. Notes for the demonstration

- Everything on screen is computed from the database — nothing is hard-coded.
- The performance analysis is plain rule-based PHP/JavaScript, not machine learning.
- Passwords are stored as bcrypt hashes (`password_hash()`), and every query uses a prepared statement.
- The PDF is produced by the browser's own print dialog, so no external PDF library is needed.

See **VIVA-GUIDE.md** for the full project explanation and question bank.
