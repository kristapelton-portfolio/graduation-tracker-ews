-- Check raw data

SELECT student_id, grade_level, graduation_cohort
FROM raw.students
WHERE grade_level !~ '^[0-9]+$'
	OR graduation_cohort !~ '^[0-9]+$';

SELECT course_id, credit
FROM raw.course_catalogue
WHERE credit !~ '^[0-9]+(\.[0-9]+)?$';

SELECT service_id, hours_reported
FROM raw.community_service
WHERE hours_reported !~ '^[0-9]+(\.[0-9]+)?$';

SELECT enrollment_id,
	credits_attempted, 
	final_grade, 
	credits_earned, 
	attempted_number
FROM raw.course_enrollments
WHERE attempted_number !~ '^[0-9]+$'
	OR credits_attempted !~ '^[0-9]+(\.[0-9]+)?$'
	OR final_grade !~ '^[0-9]+(\.[0-9]+)?$'
	OR credits_earned !~ '^[0-9]+(\.[0-9]+)?$';

SELECT assessment_id, attempt_number, scaled_score
FROM raw.keystones
WHERE attempt_number !~ '^[0-9]+$'
	OR scaled_score !~ '^[0-9]+$';

SELECT graduation_cohort, course_subject, required_credits
FROM raw.requirements
WHERE required_credits !~ '^[0-9]+(\.[0-9]+)?$';

-- Create clean tables

CREATE TABLE IF NOT EXISTS clean.students (
	student_id VARCHAR(20) PRIMARY KEY,
	grade_level INTEGER,
	enrollment_statues VARCHAR(50),
	graduation_cohort INTEGER
);

INSERT INTO clean.students
SELECT student_id, 
	grade_level::INTEGER,
	enrollment_status,
	graduation_cohort::INTEGER
FROM raw.students;

CREATE TABLE IF NOT EXISTS clean.course_catalogue (
	course_id VARCHAR(20) PRIMARY KEY,
	course_name VARCHAR(200) NOT NULL,
	course_subject VARCHAR(20) NOT NULL,
	credit NUMERIC(4,2) NOT NULL
);

INSERT INTO clean.course_catalogue 
SELECT course_id, course, course_subject, credit::NUMERIC(4,2)
FROM raw.course_catalogue;

CREATE TABLE IF NOT EXISTS clean.course_enrollments (
	enrollment_id VARCHAR(20) PRIMARY KEY,
	student_id VARCHAR(20) NOT NULL REFERENCES clean.students(student_id),
	course_id VARCHAR(20) NOT NULL REFERENCES clean.course_catalogue(course_id),
	school_year VARCHAR(20),
	enrollment_status VARCHAR(50),
	final_grade NUMERIC(5,2),
	course_outcome VARCHAR(100),
	attempted_number INTEGER,
	credits_attempted NUMERIC(4,2),
	credits_earned NUMERIC(4,2)
);

INSERT INTO clean.course_enrollments
SELECT enrollment_id,
	student_id,
	course_id,
	school_year,
	enrollment_status,
	NULLIF(final_grade,'')::NUMERIC(5,2),
	course_outcome,
	NULLIF(attempted_number,'')::INTEGER,
	NULLIF(credits_attempted, '')::NUMERIC(4,2),
	NULLIF(credits_earned,'')::NUMERIC(4,2)
FROM raw.course_enrollments;

CREATE TABLE IF NOT EXISTS clean.interventions (
	intervention_id VARCHAR(20) PRIMARY KEY,
	student_id VARCHAR(20) NOT NULL REFERENCES clean.students(student_id),
	intervention_type VARCHAR(200),
	intervention_date DATE,
	status VARCHAR(200)
);

INSERT INTO clean.interventions
SELECT intervention_id,
	student_id,
	intervention_type,
	intervention_date::DATE,
	status
FROM raw.interventions;

CREATE TABLE IF NOT EXISTS clean.community_service (
	service_id VARCHAR(20) PRIMARY KEY,
	student_id VARCHAR(20) NOT NULL REFERENCES clean.students(student_id),
	service_date DATE,
	hours_reported INTEGER,
	verification_status VARCHAR(50)
);

INSERT INTO clean.community_service
SELECT service_id,
	student_id,
	service_date::DATE,
	hours_reported::INTEGER,
	verification_status
FROM raw.community_service;

CREATE TABLE IF NOT EXISTS clean.keystones (
	assessment_id VARCHAR(20) PRIMARY KEY,
	student_id VARCHAR(20) NOT NULL REFERENCES clean.students(student_id),
	assessment_subject VARCHAR(50),
	attempt_number INTEGER,
	scaled_score INTEGER,
	assessment_season VARCHAR(50),
	assessment_year INTEGER
);

INSERT INTO clean.keystones
SELECT assessment_id,
	student_id,
	assessment_subject,
	attempt_number::INTEGER,
	scaled_score::INTEGER,
	assessment_season,
	assessment_year::INTEGER
FROM raw.keystones;

CREATE TABLE IF NOT EXISTS clean.pathways (
	pathway_id VARCHAR(20) PRIMARY KEY,
	student_id VARCHAR(20) NOT NULL REFERENCES clean.students(student_id),
	proposed_pathway VARCHAR(200),
	evidence_status VARCHAR(100),
	evidence_reference VARCHAR(200)
);

INSERT INTO clean.pathways
SELECT pathway_record_id,
	student_id,
	proposed_pathway,
	evidence_status,
	evidence_reference
FROM raw.pathway;

CREATE TABLE IF NOT EXISTS clean.requirements (
	graduation_cohort VARCHAR(20),
	course_subject VARCHAR(50),
	required_credits NUMERIC(4,2),
	requireme4nt_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY
);

INSERT INTO clean.requirements
SELECT graduation_cohort,
	course_subject,
	required_credits::NUMERIC(4,2)
FROM raw.requirements;

-- Data quality checks

SELECT COUNT(*) AS missing_student_refs
FROM raw.course_enrollments AS r
LEFT JOIN clean.students AS c
	ON c.student_id = r.student_id
WHERE c.student_id IS NULL;

SELECT COUNT(*) AS missing_course_refs
FROM raw.course_enrollments AS r
LEFT JOIN clean.course_catalogue AS c
	ON c.course_id = r.course_id
WHERE c.course_id IS NULL;

SELECT COUNT(*) AS invalid_earned_credit_rows
FROM clean.course_enrollments
WHERE credits_earned > credits_attempted
	OR (course_outcome <> 'Passed' AND credits_earned > 0);

SELECT COUNT(*) AS missing_cs_student_refs
FROM raw.community_service AS r
LEFT JOIN clean.community_service AS c
	ON c.student_id = r.student_id
WHERE c.student_id IS NULL;

SELECT COUNT(*) AS missing_keystones_refs
FROM raw.keystones AS r
LEFT JOIN clean.keystones AS c
	ON c.student_id = r.student_id
WHERE c.student_id IS NULL;

SELECT COUNT(*) AS missing_pathways_refs
FROM raw.pathway AS r
LEFT JOIN clean.pathways AS c
	ON c.student_id = r.student_id
WHERE c.student_id IS NULL;

SELECT COUNT(*) AS missing_interventions_refs
FROM raw.interventions AS r
LEFT JOIN clean.interventions AS c
	ON c.student_id = r.student_id
WHERE c.student_id IS NULL;