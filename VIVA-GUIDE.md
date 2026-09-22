# EduResult — Viva Guide

Everything below is written the way you would say it to an examiner: short, concrete, and tied to
files you can actually open on screen.

---

## 1. Project objective

To build a web portal where a student can see their semester marks the moment they are published,
get their SGPA and CGPA calculated automatically, understand which subjects are strong or weak, and
print an official marksheet — while the examination cell manages all of it from one admin panel.

## 2. Problem statement

In most colleges, marks are printed on a notice board or mailed as a PDF. A student who wants to
know their CGPA has to collect old marksheets and calculate it by hand, and a mistake in that
arithmetic is only caught much later. Staff maintain marks in Excel files that are easy to
overwrite and hard to search. There is no single place where a student's full academic record lives.

## 3. Existing system

- Marks kept in spreadsheets or registers, one file per semester.
- SGPA and CGPA calculated manually with a calculator.
- Results announced on a notice board or through WhatsApp groups.
- No access control: whoever has the file can change it.
- No analysis — the student sees numbers, not meaning.

## 4. Proposed system

EduResult stores every student, subject and mark in a single MySQL database.

- The admin enters only internal and external marks. Total, grade, grade point, pass/fail, SGPA,
  CGPA and percentage are computed by the system.
- Results stay in **Draft** until they are verified, then they are **Published**.
- Students log in with their roll number and see only their own published results.
- A performance page shows the highest and lowest subject, the average, the pass count and a plain
  remark on where the student stands.
- The marksheet prints straight from the browser, or saves as a PDF.

## 5. Technologies used

| Layer | Technology | Why |
|-------|-----------|-----|
| Structure | HTML5 | Page markup |
| Styling | CSS3 (custom, no framework) | Responsive layout, cards, sidebar, print styles |
| Client logic | Vanilla JavaScript | Bar chart, SVG trend chart, table search, live grade preview, print |
| Server logic | PHP 7.4+ | Sessions, authentication, CRUD, grade and SGPA calculation |
| Database | MySQL (InnoDB) | Five related tables with foreign keys |
| Server | Apache via XAMPP | Local deployment |
| DB access | PDO with prepared statements | Protects against SQL injection |

## 6. System architecture

Three tiers:

1. **Presentation tier** — the browser: HTML, CSS and JavaScript.
2. **Application tier** — PHP files on Apache: authentication, validation, grade and SGPA logic.
3. **Data tier** — MySQL: `users`, `subjects`, `results`, `semesters`, `admin`.

A request flows: browser → Apache → PHP page → `includes/config.php` opens a PDO connection →
prepared statement runs against MySQL → rows come back → PHP builds the HTML → the browser renders it.

Shared code is factored out: `config.php` (connection + calculations), `auth.php` (sessions and
guards), `header.php` / `footer.php` (layout).

## 7. Database design

| Table | Purpose | Key columns |
|-------|---------|-------------|
| `users` | students | `id` PK, `student_id` unique (roll number, used as login and as FK target), `email` unique, `password` |
| `subjects` | subject catalogue | `id` PK, `subject_code` unique, `credits`, `department`, `semester` |
| `results` | one row per student per subject | `id` PK, `student_id` FK, `subject_id` FK, marks, `grade`, `grade_point`, `status` |
| `semesters` | computed summary | `id` PK, `student_id` FK, `semester`, `sgpa`, `cgpa`, `percentage` |
| `admin` | staff accounts | `id` PK, `username` unique, `password` |

Constraints used:

- `results` has `UNIQUE (student_id, subject_id)` so the same subject cannot be entered twice.
- `semesters` has `UNIQUE (student_id, semester)`.
- Both foreign keys are `ON DELETE CASCADE`, so deleting a student removes their marks too.

`results` and `semesters` are in third normal form: marks depend only on the student–subject pair,
and nothing about the subject (its name or credits) is repeated inside `results`.

## 8. ER diagram explanation

```
   USERS (1) ───────< (M) RESULTS (M) >─────── (1) SUBJECTS
      │                                              
      │ 1                                            
      └────────< M  SEMESTERS                        
                                                     
   ADMIN  (standalone — manages everything, related by application logic, not by a key)
```

- One student has **many** result rows; one subject appears in **many** result rows. `results` is
  therefore the junction table that resolves the many-to-many relationship between students and
  subjects, and it carries its own attributes (marks, grade, status).
- One student has **many** semester summary rows (one per semester).
- `admin` has no foreign key to the others because an admin does not *own* rows; it operates on them.

## 9. Login authentication

Two separate logins.

Student (`login.php`): the typed roll number is looked up with a prepared statement, then
`password_verify($typed, $row['password'])` compares the password against the stored bcrypt hash.
On success `session_regenerate_id(true)` is called (to stop session fixation) and
`$_SESSION['student_id']` is set.

Admin (`admin/login.php`) does the same against the `admin` table and sets `$_SESSION['admin_id']`.

The two session keys are different, so an admin session can never unlock a student page, and vice versa.

## 10. PHP sessions

A session is server-side storage keyed by a cookie (`PHPSESSID`) held by the browser.
`includes/auth.php` calls `session_start()` once and then provides guards:

```php
function requireStudent() {
    if (!isStudent()) { set_flash('error','Please login to continue.'); redirect('login.php'); }
}
```

Every protected page begins with `require_once 'includes/auth.php'; requireStudent();`
(or `requireAdmin()`), so typing `dashboard.php` in the address bar without logging in just bounces
you to the login page. `logout.php` clears `$_SESSION` and calls `session_destroy()`.

## 11. CRUD operations

| Where | Create | Read | Update | Delete |
|-------|--------|------|--------|--------|
| `admin/students.php` | add student (password hashed on insert) | list + instant search | edit; password only changed if a new one is typed | delete, cascading to marks |
| `admin/subjects.php` | add subject | list with department/semester filters | edit | delete, blocked if marks already exist |
| `admin/results.php` | enter marks | list per student per semester | edit a marks row | delete a marks row |

All four operations use prepared statements, and the POST handler redirects after a successful save
(Post/Redirect/Get) so refreshing the page does not insert the row twice.

## 12. Result calculation

The admin types only two numbers. In `admin/results.php`:

```php
$total = $internal + $external;          // out of 100
$g     = calculateGrade($total);         // grade + grade point
```

The row is saved with the computed total, grade, grade point and a status of Draft or Published.
The semester result is **PASS** only if every subject is at or above the pass mark (40); one failed
subject makes the whole semester **FAIL**. That rule lives in `summarise()` in `includes/config.php`.

## 13. Grade calculation

A single function, so the scale can be changed in one place:

```php
function calculateGrade($total) {
    if ($total >= 90) return ['grade'=>'O',  'point'=>10];
    if ($total >= 80) return ['grade'=>'A+', 'point'=>9];
    if ($total >= 70) return ['grade'=>'A',  'point'=>8];
    if ($total >= 60) return ['grade'=>'B+', 'point'=>7];
    if ($total >= 50) return ['grade'=>'B',  'point'=>6];
    if ($total >= 40) return ['grade'=>'C',  'point'=>5];
    return ['grade'=>'F', 'point'=>0];
}
```

The same ladder is repeated in `js/script.js` only to show a live preview while the admin types; the
value actually stored always comes from PHP.

## 14. SGPA calculation

SGPA is a **credit-weighted** average of grade points for one semester:

```
SGPA = Σ(credit × grade point) ÷ Σcredits
```

Example — semester 4 of CSE2021001:

| Subject | Credits | Total | Grade | Point | Credit × Point |
|---------|--------:|------:|-------|------:|---------------:|
| Computer Networks | 4 | 91 | O | 10 | 40 |
| Machine Learning | 4 | 87 | A+ | 9 | 36 |
| Web Technology | 3 | 93 | O | 10 | 30 |
| Software Engineering | 3 | 86 | A+ | 9 | 27 |
| Operating Systems | 2 | 92 | O | 10 | 20 |
| **Total** | **16** | | | | **153** |

SGPA = 153 ÷ 16 = **9.56** — which is exactly the value stored in the `semesters` table for that
student, so you can open the page and show it matching.

A 4-credit subject therefore moves the SGPA twice as much as a 2-credit subject — that is the whole
point of using credits instead of a plain average.

## 15. CGPA calculation

CGPA applies the same formula across every subject up to and including the current semester:

```
CGPA = Σ(credit × grade point) over all semesters ÷ Σcredits over all semesters
```

`recalculateStudent()` in `includes/config.php` loops over the student's semesters in order, keeps a
running total of points and credits, and writes SGPA, CGPA and percentage into the `semesters` table.
It is called automatically whenever marks are saved, edited, deleted or published, so the stored
values can never drift out of date. Admin → SGPA / CGPA → **Recalculate all** re-runs it for everyone.

## 16. Performance analysis

`performance.php` does four ordinary things:

1. Loops over the semester's rows to find the highest subject, the lowest subject and the average.
2. Counts passed and failed subjects.
3. Draws one bar per subject — the bar width is simply the total marks out of 100, animated by
   `js/script.js`; gold marks the best subject, grey the weakest, red an uncleared one.
4. Draws the SGPA/CGPA trend as an inline SVG built in JavaScript from the `semesters` rows.

The remark is an if/else ladder on the percentage: 85+ "Excellent Academic Performance",
70+ "Very Good Performance", 50+ "Good — Keep Improving", otherwise "Needs Improvement".

**This is rule-based logic, not AI.** Every number can be traced to a formula — which is exactly
what makes it defensible in a viva.

## 17. Admin module

- **Dashboard** — counts of students, subjects, results and departments, the most recent marks
  entered, and a pass-rate bar per department.
- **Student Management** — full CRUD with instant client-side search.
- **Subject Management** — full CRUD with department and semester filters.
- **Result Management** — pick a student and semester, enter marks with a live grade preview, and
  publish or move the whole semester back to draft.
- **SGPA / CGPA** — every stored summary row, with a Recalculate all button.

## 18. Student module

- **Dashboard** — CGPA, overall percentage, current semester, subjects passed and failed, the latest
  result, and a performance remark.
- **View Result** — the official marksheet, with a semester selector and Print / Save as PDF.
- **My Academic Journey** — every published semester with SGPA, CGPA, percentage and status, plus
  the trend chart; each semester links to its marksheet and analysis.
- **Performance** — the analysis described in section 16.
- **Profile** — edit contact details, change password.

Anyone, logged in or not, can use **Check Result** with a roll number and semester.

## 19. Security

| Measure | Where |
|---------|-------|
| Passwords stored as bcrypt hashes | `password_hash()` on register / add / password change; `password_verify()` on login |
| SQL injection prevented | every query is a PDO prepared statement with bound parameters |
| XSS prevented | all output passes through `e()`, which is `htmlspecialchars()` |
| Session fixation prevented | `session_regenerate_id(true)` right after a successful login |
| Access control | `requireStudent()` / `requireAdmin()` at the top of every protected page |
| Data isolation | student pages always filter by `$_SESSION['student_id']`, so one student cannot open another's result by editing the URL |
| Draft protection | student queries add `AND status = 'Published'` |
| Public page minimised | `search-result.php` selects only name, department and year — never the password hash, email or phone |
| Input validation | marks are range-checked (0–25 internal, 0–75 external) and cast to integers |

## 20. Future enhancements

- Email or SMS alert when a result is published.
- Bulk marks upload from Excel/CSV.
- Server-side PDF generation with a digital signature and a QR code for verification.
- Attendance and internal assessment modules feeding the same record.
- Revaluation request workflow with status tracking.
- Faculty role in addition to admin, with subject-level permissions.
- Class-level analytics: toppers list, subject-wise pass percentage, department comparison.
- Migration to HTTPS with CSRF tokens on every form, plus login rate limiting.

---

# 20 viva questions with simple answers

**1. What is EduResult?**
A web-based student result management system where students view their marksheet, SGPA, CGPA and
performance analysis, and the examination cell manages students, subjects, marks and publication.

**2. Which technologies did you use and why?**
HTML and CSS for the interface, JavaScript for charts and live validation, PHP for server-side logic,
MySQL for storage and XAMPP to run Apache and MySQL locally. No framework is used, so every line is
plain, readable code.

**3. Why PHP and not a framework like Laravel?**
The project is small enough that a framework would add setup complexity without adding value, and
core PHP shows the actual concepts — sessions, prepared statements, form handling — more clearly.

**4. How many tables are there and what are they?**
Five: `users` (students), `subjects`, `results` (marks), `semesters` (SGPA/CGPA summary) and `admin`.

**5. Why is `student_id` used as the foreign key instead of `users.id`?**
The roll number is the natural business key — it is what the student types to log in and what appears
on the marksheet — so it is declared `UNIQUE` and referenced by `results` and `semesters`. With
`ON UPDATE CASCADE`, correcting a roll number updates the child rows automatically.

**6. What is a prepared statement and why use it?**
A query where the SQL structure is sent first with `?` placeholders and the values are bound
separately. The database never treats user input as SQL, so SQL injection is not possible — typing
`' OR '1'='1` into the login box just fails to match a roll number.

**7. How are passwords stored?**
Never as plain text. `password_hash()` produces a bcrypt hash with a random salt, and
`password_verify()` checks a typed password against it. A hash cannot be reversed, so even someone
who dumps the database cannot read the passwords.

**8. What is a PHP session and how did you use it?**
Session data lives on the server and is identified by a cookie in the browser. After login, PHP
stores the roll number in `$_SESSION`. Every protected page checks for it, so a user who is not
logged in is redirected to the login page.

**9. How do you stop a student from opening another student's result?**
Pages never take the roll number from the URL. Queries always use `$_SESSION['student_id']`, which
only the server can set.

**10. How is the total calculated?**
`Total = Internal + External`, that is 25 + 75, out of 100. It is computed in PHP when the admin
saves the marks, never typed by hand.

**11. Explain the grading system.**
90–100 → O (10), 80–89 → A+ (9), 70–79 → A (8), 60–69 → B+ (7), 50–59 → B (6), 40–49 → C (5),
below 40 → F (0). It lives in one function, `calculateGrade()`, so a different university scale
needs only that function changed.

**12. What is SGPA and how is it calculated?**
Semester Grade Point Average — the credit-weighted average of grade points for one semester:
Σ(credit × grade point) ÷ Σcredits. Credits matter, so a 4-credit subject counts twice as much as a
2-credit one.

**13. What is the difference between SGPA and CGPA?**
SGPA covers one semester; CGPA applies the same formula to every subject from semester one up to the
current semester. It is a credit-weighted cumulative average, not the plain average of the SGPAs.

**14. When are SGPA and CGPA recalculated?**
`recalculateStudent()` runs automatically after any marks row is saved, edited, deleted or published,
and rewrites that student's `semesters` rows. There is also a Recalculate all button in the admin panel.

**15. How do you decide pass or fail?**
A subject is cleared at 40 out of 100. A semester is PASS only if every subject is cleared; a single
F makes the semester FAIL.

**16. What is the Draft / Published status for?**
Marks are entered as Draft while they are being verified. Student queries include
`AND status = 'Published'`, so nothing reaches the student until the examination cell publishes it.
It prevents half-entered results from leaking.

**17. Is your performance analysis machine learning?**
No. It loops over the result rows in PHP to find the highest, lowest and average marks, counts passes
and failures, and picks a remark with an if/else ladder on the percentage. The charts are drawn with
plain JavaScript and SVG. Nothing is predicted or trained.

**18. How does the download as PDF work without a PDF library?**
The marksheet page has a print stylesheet (`@media print`) that hides the sidebar, topbar and
buttons. The button calls `window.print()`, and the browser's own dialog offers "Save as PDF". It is
simpler, lighter and produces identical output on every machine.

**19. How is the project made responsive?**
CSS media queries. Below 760px the sidebar slides in from the left through a checkbox toggle, grids
collapse to a single column, and wide tables scroll horizontally inside their container instead of
breaking the layout.

**20. What are the limitations, and what would you add next?**
It runs on localhost over HTTP, has no CSRF tokens or login rate limiting, and marks are entered one
subject at a time. Next steps: bulk CSV upload, email notification on publication, server-side PDF
with a verification QR code, a faculty role, and deployment over HTTPS.
