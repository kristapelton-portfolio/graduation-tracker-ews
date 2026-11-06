-- Create view for monitoring interventions

CREATE OR REPLACE VIEW analysis.intervention_monitoring AS
SELECT 
	intervention_id,
	student_id,
	intervention_type,
	intervention_date,
	status AS intervention_status,
	CASE
		WHEN status = 'Open' 
		THEN 1
		ELSE 0
	END AS open,
	CASE
		WHEN status = 'Follow-Up Needed'
		THEN 1
		ELSE 0
	END AS follow_up,
	CASE
		WHEN status = 'Completed'
		THEN 1
		ELSE 0
	END AS completed,
	CASE
		WHEN status IN ('Open', 'Follow-Up Needed')
		THEN 1
		ELSE 0
	END AS active_intervention
FROM clean.interventions;

-- View the view for monitoring interventions

SELECT *
FROM analysis.intervention_monitoring;

-- Create intervention summary analysis

CREATE OR REPLACE VIEW analysis.intervention_summary AS
SELECT
	COUNT(*) AS total_interventions,
	COUNT(DISTINCT student_id) AS students_with_interventions,
	SUM(open) AS open_interventions,
	SUM(follow_up) AS follow_ups_needed,
	SUM(completed) AS completed_interventions,
	SUM(active_intervention) AS active_interventions,
	ROUND(
        100.0 * SUM(completed) / NULLIF(COUNT(*), 0),
        2
    ) AS completion_rate
FROM analysis.intervention_monitoring;

-- View intervention analysis

SELECT *
FROM analysis.intervention_summary;

-- Create intervention category analysis view

CREATE OR REPLACE VIEW analysis.intervention_categories AS 
SELECT
	intervention_type,
	COUNT(*) AS total_interventions,
	COUNT(DISTINCT student_id) AS students_served,
	SUM(open) AS open_interventions,
	SUM(follow_up) AS follow_ups_needed,
	SUM(completed) AS completed_interventions,
	ROUND(
		100.0 * SUM(completed)
		/ NULLIF(COUNT(*), 0), 
		2
	) AS completed_rate
FROM analysis.intervention_monitoring
GROUP BY intervention_type;

-- View intervention catefory analysis

SELECT *
FROM analysis.intervention_categories;

-- Create student intervention summary

CREATE OR REPLACE VIEW analysis.student_intervention_summary AS
SELECT
	student_id,
	COUNT(*) AS total_interventions,
	COUNT(*) FILTER (
			WHERE intervention_status = 'Open'
	) AS open,
	COUNT(*) FILTER (
			WHERE intervention_status = 'Follow-Up Needed'
	) AS follow_ups,
	COUNT (*) FILTER (
			WHERE intervention_status = 'Completed'
	) AS completed,
	MAX(intervention_date) AS latest_intervention_date,
	CASE
		WHEN COUNT(*) FILTER (
			WHERE intervention_status = 'Follow-Up Needed'
		) > 0
		THEN 'Follow-Up Needed'
		WHEN COUNT(*) FILTER (
			WHERE intervention_status = 'Open'
		) > 0
		THEN 'Open Interventions'
		ELSE 'No Active Interventions'
	END AS intervention_priority
FROM analysis.intervention_monitoring
GROUP BY student_id;

-- View student intervention summary

SELECT *
FROM analysis.student_intervention_summary

-- Create follow up queue

CREATE OR REPLACE VIEW analysis.follow_up_queue AS
SELECT 
	student_id,
	total_interventions,
	open,
	follow_ups,
	latest_intervention_date,
	intervention_priority
FROM analysis.student_intervention_summary
WHERE follow_ups > 0
ORDER BY follow_ups DESC, student_id;

-- View follow up queue

SELECT *
FROM analysis.follow_up_queue

