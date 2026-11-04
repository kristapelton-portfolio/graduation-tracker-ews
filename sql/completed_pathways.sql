-- Create a view which identifies whether or not the student has completed a pathway

CREATE OR REPLACE VIEW analysis.pathway_verification AS
SELECT
	student_id,
	proposed_pathway,
	CASE
		WHEN evidence_status = 'Verified'
			THEN 'Completed'
		ELSE 'Not Completed'
	END AS pathway_completion
FROM (
	SELECT 
		student_id,
		proposed_pathway,
		evidence_status
	FROM clean.pathways
) AS pathway_data;

CREATE OR REPLACE VIEW analysis.completed_pathway AS
SELECT
	student_id,
	pathway_completion
FROM analysis.pathway_verification
WHERE pathway_completion = 'Completed';

-- View students who have completed a Act 158 Pathway

SELECT *
FROM analysis.completed_pathway;
	