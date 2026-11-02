-- Create raw student, course, and enrollment tables

CREATE TABLE IF NOT EXISTS raw.students (
	student_id TEXT,
	grade_level TEXT,
	enrollment_status TEXT,
	graduation_cohort TEXT
);

CREATE TABLE IF NOT EXISTS raw.course_catalogues (
	course_id TEXT,
	course TEXT,
	course_subject TEXT,
	credit TEXT
);

CREATE TABLE IF NOT EXISTS raw.course_enrollments (
	enrollment_id TEXT,
	student_id TEXT,
	school_year TEXT,
	credits_attempted TEXT,
	enrollment_status TEXT,
	final_grade TEXT,
	course_outcome TEXT,
	credits_earned TEXT,
	attempted_number TEXT
);