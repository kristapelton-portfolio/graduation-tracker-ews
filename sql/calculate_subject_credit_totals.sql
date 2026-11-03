-- Earned-Credit View

CREATE OR REPLACE VIEW analysis.student_course_credits AS
SELECT e.student_id, 
	e.course_id,
	c.course_subject,
	MAX(CASE WHEN e.course_outcome = 'Passed'
			THEN c.credit ELSE 0 END) AS earned_credit
FROM clean.course_enrollments AS e
JOIN clean.course_catalogue AS c
	ON c.course_id = e.course_id
GROUP BY e.student_id, e.course_id, c.course_subject;

-- Verify Earned-Credit View

SELECT *
FROM analysis.student_course_credits
ORDER BY student_id, course_subject 
LIMIT 25;

-- Aggregate by subect

CREATE OR REPLACE VIEW analysis.student_subject_credits AS
SELECT st.student_id, 
	st.grade_level, 
	st.graduation_cohort,
	subj.course_subject,
	COALESCE(SUM(cc.earned_credit),0) AS earned_credits
FROM clean.students AS st
CROSS JOIN (
	SELECT DISTINCT course_subject
	FROM clean.course_catalogue
) AS subj
LEFT JOIN analysis.student_course_credits AS cc
	ON cc.student_id = st.student_id
	AND cc.course_subject = subj.course_subject
GROUP BY st.student_id,
	st.grade_level,
	st.graduation_cohort,
	subj.course_subject;

-- Verify Subject Credits

SELECT *
FROM analysis.student_subject_credits
WHERE grade_level = 12
ORDER BY student_id, course_subject
LIMIT 25;