# Graduation Tracker — Project Methodology

**Author:** Krista Pelton  
**Project type:** End-to-end educational data analytics portfolio project  
**Technology:** Python (pandas, NumPy), Google Colab, PostgreSQL, SQL, Tableau Public  
**Dashboard:** [Pennsylvania Graduation Tracker](https://public.tableau.com/views/PennsylvaniaGraduationTracker/Dashboard)

> **Data disclosure:** This project uses simulated student records generated for demonstration and portfolio use. Results do not describe actual students, schools, or Pennsylvania graduation outcomes.

## 1. Business problem and objective

Graduation-readiness information often lives across disconnected course, assessment, service-hour, pathway, and intervention records. The project demonstrates how to organize those data into a consistent analytical foundation that can support graduation-readiness monitoring and intervention follow-up.

The implementation combines synthetic data generation, relational database preparation, reusable SQL views, and a published Tableau dashboard. The intended audience includes school leaders, counseling teams, and education technology stakeholders.

## 2. End-to-end architecture

```text
Python / Google Colab
    └── Synthetic student, course, assessment, pathway,
        community-service and intervention CSV files
              ↓
PostgreSQL raw schema
    └── Source fields ingested as TEXT
              ↓
PostgreSQL clean schema
    └── Typed columns, keys, referential relationships
              ↓
PostgreSQL analysis schema
    └── Credits, verified hours, assessment pathways,
        pathway evidence, intervention metrics and queues
              ↓
Tableau Public
    └── Pennsylvania Graduation Tracker dashboard
```

The repository's SQL scripts define the `raw`, `clean`, and `analysis` schemas. The notebooks use a Google Drive project directory with folders for ground-truth data, raw/dirty data, cleaned data, audits, notebooks, SQL, documentation, and dashboards. The supplied notebooks substantiate **ground-truth synthetic data generation and initial profiling**; they do not establish that a complete dirty-data injection and remediation pipeline was executed.

## 3. Synthetic data generation (Python)

The Python notebooks use `pandas`, `numpy`, `pathlib`, and Google Colab / Google Drive. Generation notebooks initialize `np.random.default_rng(42)` to make each notebook's random sampling repeatable, subject to its execution order and inputs.

| Dataset | Generation approach | Evidence |
|---|---|---|
| Students | Creates **5,000** synthetic student IDs; randomly assigns grades 9–12 and enrollment statuses; derives cohort from grade relative to 2027 | `create_student_data.ipynb` |
| Course catalogue | Builds subject-coded course identifiers, course names, and one-credit or half-credit values; notebook asserts 67 catalogue entries | `create_course_catalogue.ipynb` |
| Course enrollments | Samples grade-dependent numbers of distinct courses; assigns school years, completion status, grades, pass/fail outcomes and earned credits | `generate_student_course_enrollments.ipynb` |
| Graduation requirements | Creates cohort-specific subject and total-credit requirements for 2027–2030 | `generate_graduation_requirements.ipynb` |
| Keystone assessments | Simulates Algebra 1, Biology, and Literature attempts, scaled scores and assessment seasons; generates unique assessment IDs | `keystone_assessments.ipynb` |
| Act 158 evidence | Assigns a proposed pathway (1–5), evidence status and evidence reference; missing/not-evaluated evidence receives a null reference | `act_158_pathway.ipynb` |
| Community service | Generates zero to four service records per student with reported hours and verification statuses | `community_service.ipynb` |
| Interventions | Generates zero to four intervention events per student, with intervention type, date and status | `generate_interventions.ipynb` |

The `create_cte_program_enrollments.ipynb` file is named for CTE enrollment but its inspected code repeats student-record generation and references variables not defined within that notebook. **It should not be described as an implemented CTE enrollment model without revision.**

### Selected simulation parameters

- Enrollment status probabilities: Active **75%**, Dropped **8%**, Withdrawn **7%**, Transferred **10%**.
- Course final grades for completed enrollments: sampled from a normal distribution centered at **78**, standard deviation **14**, clipped to 0–100; grades **≥60** are labeled Passed.
- Assessment generation: approximately **75%** chance of a record for each student–subject combination; one or two attempts, with a **15%** chance of two attempts conditional on generation.
- Keystone scaled scores: normal distribution centered at **1480**, standard deviation **95**, clipped to **1200–1800**.
- Community-service verification: Verified **75%**, Pending **20%**, Rejected **5%**.
- Intervention statuses: Open **25%**, Completed **55%**, Follow-Up Needed **20%**.

These are **simulation design choices**, not observed school statistics or official statewide distributions.

## 4. Data profiling and relational preparation

`data_cleaning.ipynb` loads eight synthetic datasets and produces a profiling table of row counts, column counts, missing values, and duplicate rows. It also checks whether course-enrollment student IDs and course IDs exist in the corresponding reference tables. The supplied notebook shows **profiling and foreign-key checks**, rather than a comprehensive Python cleaning pipeline.

In PostgreSQL:

1. `schemas.sql` creates `raw`, `clean`, and `analysis`.
2. `create_tables.sql` creates source tables in `raw`, initially using `TEXT` fields.
3. `create_clean_tables.sql` checks numeric formatting, creates typed tables, casts dates and numbers, and defines primary/foreign keys.
4. Additional SQL scripts build analytical views.

The clean-layer design includes students, catalogue, enrollments, interventions, community service, Keystones, pathways, and graduation requirements. SQL checks target missing references and credit inconsistencies, such as earned credits exceeding attempted credits or credits awarded to non-passing outcomes.

**Execution note:** The uploaded SQL contains a probable `enrollment_statues`/`enrollment_status` column-name mismatch in `clean.students`; it should be reconciled against the successfully executed database definition before publishing runnable scripts.

## 5. Analytical SQL transformations

### 5.1 Earned credits

`calculate_subject_credit_totals.sql` creates:

- `analysis.student_course_credits`: joins enrollments to the course catalogue and uses `MAX(CASE WHEN course_outcome = 'Passed' THEN credit ELSE 0 END)` per student/course/subject.
- `analysis.student_subject_credits`: cross joins students to the set of subjects, left joins earned credits, and uses `COALESCE(SUM(...), 0)` to retain zero-credit subject rows.

The `MAX` pattern prevents multiple rows for the *same course* from being counted more than once, but it does **not** resolve equivalency across distinct course IDs.

### 5.2 Community-service verification

`community_service.sql` creates `analysis.total_hours` by summing `hours_reported` **only when** `verification_status = 'Verified'`. `analysis.completed_hours` retains students with **at least 20 verified hours**. Students with no verified records do not appear in the aggregation view unless joined back to the student roster.

### 5.3 Keystone and Act 158 pathways

`pathway_one.sql` uses `ROW_NUMBER()` partitioned by student and assessment subject, ordered by descending scaled score, to select each student's highest recorded assessment. It defines proficiency with `scaled_score > 1500` and identifies Pathway 1 when three qualifying subject records exist.

`pathway_two.sql` identifies students whose summed highest scores meet **4452**, with at least one subject present in the proficiency view.

`completed_pathways.sql` separately converts `evidence_status = 'Verified'` to `pathway_completion = 'Completed'`, regardless of which proposed pathway is recorded.

**Important distinction:** The uploaded scripts contain both *score-based eligibility logic* and *evidence-based completion logic*. They do not demonstrate that those conditions have been reconciled into a single legally authoritative Act 158 determination. Thresholds and pathway definitions are the project's implemented rules and should be independently verified before claiming statutory compliance.

### 5.4 Intervention monitoring

`intervention_analysis.sql` creates:

- `analysis.intervention_monitoring`: binary flags for Open, Follow-Up Needed, Completed and Active.
- `analysis.intervention_summary`: total interventions, distinct students served, status counts and completion rate.
- `analysis.intervention_categories`: metrics by intervention type.
- `analysis.student_intervention_summary`: student-level counts, latest intervention date and a rule-based priority label.
- `analysis.follow_up_queue`: students with at least one Follow-Up Needed event, sorted by follow-up count.

The queue is a **status-based follow-up list**. The supplied data does not contain due dates or staff assignment, so it cannot substantiate overdue-task metrics or owner-based workload reporting.

## 6. Graduation-readiness rules and interpretation

The SQL scripts provided in this review establish component indicators for credits, service hours, pathways, and interventions. They do **not** include the final grade-specific readiness views or consolidated `graduation_status` calculation. Therefore, the exact final On Track / Off Track classification logic, grade-specific milestones, and readiness counts **cannot be independently verified from this file set**.

Before publishing project-level graduation-readiness findings, document:

- Required credits by subject and graduation cohort, and how total credits are evaluated.
- Whether readiness means **currently meeting grade-specific milestones** or **already meeting graduation requirements**.
- How missing, incomplete, and transferred records are handled.
- Whether only active students belong in the dashboard denominator.
- How assessment eligibility and verified pathway evidence are combined.
- How the final status is reconciled to source-level indicators.

## 7. Tableau dashboard: Graduation Tracker

**[Open the interactive Graduation Tracker dashboard on Tableau Public](https://public.tableau.com/views/PennsylvaniaGraduationTracker/Dashboard)**

![Graduation Tracker Tableau dashboard showing graduation status, credit status, community service, pathway completion, and student detail](assets/graduation-tracker-tableau-dashboard.png)

*Figure 1. Graduation Tracker dashboard, captured from the published Tableau visualization. Data are synthetic.*

The dashboard provides an overview of graduation readiness with a **Grade Level** filter and an **On Track / Off Track** status legend. It includes KPI tiles, stacked grade-level charts for graduation status, credit status, community service, and pathway completion, plus a student-detail table with student ID, grade, cohort, component statuses, and overall graduation status.

**Visible dashboard totals (all grades selected):**

| Measure | Students | Share of total |
| --- | ---: | ---: |
| Total students | 5,000 | 100.0% |
| On Track | 1,491 | 29.82% |
| Off Track | 3,509 | 70.18% |

These values are **observed in the supplied dashboard screenshot**, not independently recalculated from the source database. They describe a simulated dataset and should not be interpreted as real-world graduation rates or predictive performance.

The screenshot shows variation by grade in the readiness components. Some components are labeled **Not Applicable** for certain students; those labels should be interpreted using the project's underlying grade-specific business rules, which were not included in the reviewed final-readiness SQL.

The dashboard is published to Tableau Public and can be linked from or embedded in the GitHub Pages project case study. The screenshot is a static record of one dashboard state; use the live link for filtering and exploration.

## 8. Validation and quality assurance

Validation code visible in the supplied materials includes:

- Python assertions for student-record count, unique IDs, allowed grade/status values and cohort derivation.
- Assertions for course catalogue uniqueness, completeness, course count and credit values.
- Referential membership checks for enrollment student/course IDs and assessment/pathway/intervention IDs.
- Assessment-score bounds, community-service positive hours, and earned-credit constraints.
- PostgreSQL checks for malformed numeric text, missing references, and inconsistent credit records.

**Validation scope:** These are checks implemented in the notebooks/scripts. This review did not rerun the complete pipeline against all CSVs or verify that every check passed in the final production database.

## 9. Limitations and responsible interpretation

1. **Synthetic data:** Relationships are simulated and may not reflect realistic school-level distributions, interventions, or student trajectories.
2. **Not a prediction model:** Status rules and follow-up queues are descriptive/rule-based; no predictive accuracy, sensitivity, or model performance is claimed.
3. **Regulatory interpretation:** Pennsylvania Act 158 pathway definitions and proficiency rules require independent confirmation before operational use.
4. **Potential cohort/field inconsistencies:** The student-generation notebook uses `cohort` while SQL expects `graduation_cohort`; the requirements notebook likewise uses `cohort`. The final exported schema or any renaming step should be confirmed.
5. **Unverified final classification:** The consolidated readiness calculation was not included among the reviewed SQL scripts.
6. **No operational SLA:** Intervention records have statuses and dates but no documented due dates, owners, or escalation SLAs.
7. **Public Tableau:** A published visualization is not evidence of verified source accuracy or refresh automation.

## 10. Reproduction outline

1. Run the synthetic-generation notebooks in dependency order, beginning with students and course catalogue, then dependent datasets.
2. Verify CSV names and fields match the PostgreSQL `raw` definitions; reconcile `cohort` versus `graduation_cohort` before import.
3. Run `schemas.sql` and `create_tables.sql`.
4. Load the CSVs into `raw` tables.
5. Review and run `create_clean_tables.sql`, then inspect quality-check results.
6. Run analytical scripts in dependency order: earned-credit totals; community service; Pathway 1; Pathway 2; pathway completion; intervention analysis.
7. Add the final grade-specific and consolidated readiness SQL, if available, and reconcile classification counts.
8. Export or connect the validated analytical outputs to Tableau; compare Tableau totals against SQL.
9. Publish the dashboard and link it from the portfolio case study.

**Reproducibility caveat:** This is a documented workflow, not a verified one-command reproducible build. The supplied notebooks use Google Drive paths, and some scripts require corrections or missing upstream artifacts.

## 11. Source inventory

**Python notebooks (10):** `create_student_data.ipynb`, `create_course_catalogue.ipynb`, `generate_student_course_enrollments.ipynb`, `generate_graduation_requirements.ipynb`, `keystone_assessments.ipynb`, `act_158_pathway.ipynb`, `community_service.ipynb`, `generate_interventions.ipynb`, `data_cleaning.ipynb`, `create_cte_program_enrollments.ipynb`.

**SQL scripts (9):** `schemas.sql`, `create_tables.sql`, `create_clean_tables.sql`, `calculate_subject_credit_totals.sql`, `community_service.sql`, `pathway_one.sql`, `pathway_two.sql`, `completed_pathways.sql`, `intervention_analysis.sql`.

---

*Prepared from the supplied Python notebooks and SQL scripts. Statements about implemented code are distinguished from unverified execution outcomes and dashboard results.*
