-- Create a view to identify students who qualify for Pathway 2

CREATE OR REPLACE VIEW analysis.pathway_two AS
SELECT
	h.student_id,
	SUM(h.scaled_score) AS total_score
FROM analysis.highest_assessments AS h
GROUP BY h.student_id
HAVING 
	SUM(h.scaled_score) >= 4452
	AND EXISTS (
			SELECT 1
			FROM analysis.proficiency AS p
			WHERE p.student_id = h.student_id
	);

-- View students who qualify for Pathway 2

SELECT *
FROM analysis.pathway_two