-- Create tables for datasets

CREATE TABLE IF NOT EXISTS raw.students (
	student_id TEXT,
	grade_level TEXT,
	enrollment_status TEXT,
	graduation_cohort TEXT
);

CREATE TABLE IF NOT EXISTS raw.course_catalogue (
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

CREATE TABLE IF NOT EXISTS raw.pathway (
	pathway_record_id TEXT,
	student_id TEXT,
	proposed_pathway TEXT,
	evidence_status TEXT,
	evidence_reference TEXT
);

CREATE TABLE IF NOT EXISTS raw.community_service (
	service_id TEXT,
	student_id TEXT,
	service_date TEXT,
	hours_reported TEXT, 
	verification_status TEXT
);

CREATE TABLE IF NOT EXISTS raw.requirements (
	graduation_cohort TEXT,
	course_subject TEXT,
	required_credits TEXT
);

CREATE TABLE IF NOT EXISTS raw.interventions (
	intervention_id TEXT,
	student_id TEXT,
	intervention_type TEXT,
	intervention_date TEXT,
	status TEXT
);

CREATE TABLE IF NOT EXISTS raw.keystones (
	assessment_id TEXT,
	student_id TEXT,
	assessment_subject TEXT,
	attempt_number TEXT,
	scaled_score TEXT,
	assessment_season TEXT,
	assessment_year TEXT
);

-- Verify that tables have been created

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'raw'
ORDER BY table_name;