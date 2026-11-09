-- Create view for graduation status for 9th Grade

CREATE OR REPLACE VIEW analysis.student_readiness_ninth AS
SELECT
	s.student_id,
	s.grade_level,
	s.graduation_cohort,
	SUM(c.earned_credits) AS total_credits,
	'On Track' AS graduation_status
FROM clean.students AS s
LEFT JOIN analysis.student_subject_credits AS c
	ON s.student_id = c.student_id
WHERE s.graduation_cohort = 2030
GROUP BY s.student_id

-- View student_readiness_ninth

SELECT *
FROM analysis.student_readiness_ninth

-- Create view that calculates the suject totals qwith only one row per student

CREATE OR REPLACE VIEW analysis.subject_credits AS
SELECT 
	s.student_id,
	s.grade_level,
	s.graduation_cohort,
	SUM(c.earned_credits) AS total_credits,
	COALESCE(SUM(c.earned_credits)
		FILTER (WHERE c.course_subject = 'ela'), 0) AS ela_credits,
	COALESCE(SUM(c.earned_credits)
		FILTER (WHERE c.course_subject = 'math'), 0) AS math_credits,
	COALESCE(SUM(c.earned_credits)
		FILTER (WHERE c.course_subject = 'hist'), 0) AS hist_credits,
	COALESCE(SUM(c.earned_credits)
		FILTER (WHERE c.course_subject = 'sci'), 0) AS sci_credits,
	COALESCE(SUM(c.earned_credits)
		FILTER (WHERE c.course_subject = 'heal'), 0) AS heal_credits,
	COALESCE(SUM(c.earned_credits)
		FILTER (WHERE c.course_subject = 'pe'), 0) AS pe_credits,
	COALESCE(SUM(c.earned_credits)
		FILTER (WHERE c.course_subject = 'art'), 0) AS art_credits,
	COALESCE(SUM(c.earned_credits)
		FILTER (WHERE c.course_subject = 'pfin'), 0) AS pfin_credits
FROM clean.students AS s
LEFT JOIN analysis.subject_credits AS c
	ON s.student_id = c.student_id
GROUP BY s.student_id

SELECT *
FROM analysis.subject_credits

-- Create view for graduation status for 10th Grade

CREATE OR REPLACE VIEW analysis.student_readiness_tenth AS
SELECT
	s.student_id,
	s.grade_level,
	s.graduation_cohort,
	s.total_credits,
	s.ela_credits,
	c.total_hours,
	CASE
		WHEN s.total_credits >= 6.5
			AND s.ela_credits >= 1
			AND c.total_hours >= 5
		THEN 'On Track'
		ELSE 'Off Track'
	END AS graduation_status
FROM analysis.subject_credits AS s
LEFT JOIN analysis.total_hours AS C
	ON s.student_id = c.student_id
WHERE s.graduation_cohort = 2029

-- View student readiness view for 10th Grade

SELECT *
FROM analysis.student_readiness_tenth

-- Create view for graduation status for 11th grade

CREATE OR REPLACE VIEW analysis.student_readiness_eleventh AS
SELECT
	s.student_id,
	s.grade_level,
	s.graduation_cohort,
	s.total_credits,
	s.ela_credits,
	s.math_credits,
	s.hist_credits,
	s.sci_credits,
	s.heal_credits,
	s.pe_credits,
	c.total_hours,	
	CASE
		WHEN s.total_credits >= 13
			AND s.ela_credits >= 2
			AND s.math_credits >= 1
			AND s.hist_credits >= 1
			AND s.sci_credits >= 1
			AND s.heal_credits >= 0.5
			AND s.pe_credits >= 0.5
			AND total_hours >= 10
		THEN 'On Track'
		ELSE 'Off Track'
	END AS graduation_status
FROM analysis.subject_credits AS s
LEFT JOIN analysis.total_hours AS c
	ON s.student_id = c.student_id
WHERE s.graduation_cohort = 2028

-- View 11th grade student readiness view

SELECT *
FROM analysis.student_readiness_eleventh

-- Create view for graduation status for 12th grade

CREATE OR REPLACE VIEW analysis.student_readiness_seniors AS
SELECT
	s.student_id,
	s.grade_level,
	s.graduation_cohort,
	s.total_credits,
	s.ela_credits,
	s.math_credits,
	s.hist_credits,
	s.sci_credits,
	s.heal_credits,
	s.pe_credits,
	s.art_credits,
	c.total_hours,
	p.proposed_pathway,
	p.pathway_completion,
	CASE
		WHEN s.total_credits >= 19.5
			AND s.ela_credits >= 3
			AND s.math_credits >= 2
			AND s.hist_credits >= 2
			AND s.sci_credits >= 2
			AND s.heal_credits >= 0.5
			AND s.pe_credits >= 0.5
			AND s.art_credits >= 1
			AND c.total_hours >= 20
			AND p.pathway_completion = 'Verified'
		THEN 'On Track'
		ELSE 'Off Track'
	END AS graduation_status
FROM analysis.subject_credits AS s
LEFT JOIN analysis.total_hours AS c
	ON s.student_id = c.student_id
LEFT JOIN analysis.pathway_verification AS p
	ON s.student_id = p.student_id
WHERE s.graduation_cohort = 2027

-- View 12th grade student readiness view

SELECT *
FROM analysis.student_readiness_seniors

-- Create view with graduation status for all grades

CREATE OR REPLACE VIEW analysis.graduation_status AS
SELECT 
	student_id,
	grade_level,
	graduation_cohort,
	graduation_status
FROM analysis.student_readiness_ninth
UNION ALL
SELECT
	student_id,
	grade_level,
	graduation_cohort,
	graduation_status
FROM analysis.student_readiness_tenth
UNION ALL
SELECT
	student_id,
	grade_level,
	graduation_cohort,
	graduation_status
FROM analysis.student_readiness_eleventh
UNION ALL
SELECT 
	student_id,
	grade_level,
	graduation_cohort,
	graduation_status
FROM analysis.student_readiness_seniors

-- View All grades graduation status view

SELECT *
FROM analysis.graduation_status