-- Create community service total view

CREATE OR REPLACE VIEW analysis.total_hours AS
SELECT 
	student_id,
	SUM(hours_reported) AS total_hours
FROM clean.community_service
WHERE verification_status = 'Verified'
GROUP BY student_id

-- View community service total view

SELECT *
FROM analysis.total_hours

-- Create a view for students who have completed their community service requiement

CREATE OR REPLACE VIEW analysis.completed_hours AS
SELECT
	student_id,
	total_hours
FROM analysis.total_hours
WHERE total_hours >= 20;

-- View students who have completed their community service hours

SELECT * 
FROM analysis.completed_hours