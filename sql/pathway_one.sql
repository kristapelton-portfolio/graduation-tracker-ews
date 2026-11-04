-- Create best-attempt pattern for the Keystone Assessment

CREATE OR REPLACE VIEW analysis.highest_assessments AS
SELECT *
FROM (
	SELECT 
		k.*,
		ROW_NUMBER() OVER(
			PARTITION BY student_id, assessment_subject
			ORDER BY 
				scaled_score DESC NULLS LAST,
				assessment_year DESC,
				assessment_id DESC
	) AS rn
	FROM clean.keystones AS k
) ranked
WHERE rn = 1;

-- View best-attempt pattern

SELECT *
FROM analysis.highest_assessments

-- Create a view to identifying students who are proficient in at least one subject.

CREATE OR REPLACE VIEW analysis.proficiency AS
SELECT
	student_id,
	assessment_subject,
	scaled_score,
	assessment_year,
	attempt_number
FROM analysis.highest_assessments
WHERE scaled_score > 1500
ORDER BY student_id, assessment_subject

-- View which students are proficient in at least one subject

SELECT *
FROM analysis.proficiency

-- Create a view to identify which students have completed Pathway 1

CREATE OR REPLACE VIEW analysis.pathway_one AS
SELECT
	student_id,
	COUNT(attempt_number) AS total_proficient
FROM analysis.proficiency
GROUP BY student_id
HAVING COUNT(attempt_number) = 3;

-- View students who qualify for Pathway 1

SELECT *
FROM analysis.pathway_one
