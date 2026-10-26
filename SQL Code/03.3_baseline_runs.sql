-- CALL run_baseline
CALL `library_sim`.`run_baseline`();

-- Check library_results
SELECT *
FROM `library_results`.`experiment_run`
ORDER BY run_id DESC;