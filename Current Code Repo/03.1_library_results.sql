CREATE SCHEMA IF NOT EXISTS `library_results`;

-- Stores one row per experiment
CREATE TABLE IF NOT EXISTS `library_results`.`experiment_run` (
    run_id INT AUTO_INCREMENT PRIMARY KEY,
    experiment_type VARCHAR(45) NOT NULL,
    run_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_transactions INT,
    avg_latency_ms DECIMAL(12,3),
    min_latency_ms DECIMAL(12,3),
    max_latency_ms DECIMAL(12,3),
    transactions_per_second DECIMAL(12,3)
);

-- Stores each individual transaction
CREATE TABLE IF NOT EXISTS `library_results`.`transaction_result` (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    run_id INT NOT NULL,
    test_id INT NOT NULL,
    copy_id INT,
    member_id INT,
    execution_time_ms DECIMAL(12,3),

    FOREIGN KEY (run_id)
        REFERENCES `library_results`.`experiment_run` (run_id)
);