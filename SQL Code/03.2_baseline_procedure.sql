SET SESSION restrict_fk_on_non_standard_key = OFF;

USE `library_sim`;

DELIMITER $$

DROP PROCEDURE IF EXISTS run_baseline $$

CREATE PROCEDURE run_baseline()
BEGIN

    DECLARE i INT DEFAULT 1;
    DECLARE current_copy INT;
    DECLARE current_member INT;
    DECLARE new_loan_id INT;

    DECLARE start_time DATETIME(6);
    DECLARE end_time DATETIME(6);
    DECLARE elapsed_ms DECIMAL(12,3);

    DECLARE current_run_id INT;

    -- --------------------------------------------
    -- Create a new experiment run
    -- --------------------------------------------

    INSERT INTO `library_results`.`experiment_run` (
        experiment_type
    )
    VALUES (
        'Baseline'
    );

    SET current_run_id = LAST_INSERT_ID();

    -- --------------------------------------------
    -- Start loan IDs after existing records
    -- --------------------------------------------

    SELECT COALESCE(MAX(loan_id), 0)
    INTO new_loan_id
    FROM `library_sim`.`Loan`;

    -- --------------------------------------------
    -- Run 500 transactions
    -- --------------------------------------------

    WHILE i <= 500 DO

        -- Find one available copy
        SELECT MIN(copy_id)
        INTO current_copy
        FROM `library_sim`.`Book_copy`
        WHERE status = 'Available';

        -- Stop if no copies remain
        IF current_copy IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Not enough available book copies';
        END IF;

        -- Use members 1 through 500
        SET current_member = i;

        -- Start timing
        SET start_time = NOW(6);

        START TRANSACTION;

        -- Check status
        SELECT status
        INTO @copy_status
        FROM `library_sim`.`Book_copy`
        WHERE copy_id = current_copy;

        -- Insert new loan
        INSERT INTO `library_sim`.`Loan` (
            loan_id,
            date_out,
            due_date,
            status,
            return_date,
            Book_copy_copy_id,
            Member_member_id
        )
        VALUES (
            new_loan_id + i,
            CURDATE(),
            DATE_ADD(CURDATE(), INTERVAL 14 DAY),
            'Checked Out',
            NULL,
            current_copy,
            current_member
        );

        -- Update copy
        UPDATE `library_sim`.`Book_copy`
        SET status = 'Checked Out'
        WHERE copy_id = current_copy;

        COMMIT;

        -- Stop timing
        SET end_time = NOW(6);

        SET elapsed_ms =
            TIMESTAMPDIFF(
                MICROSECOND,
                start_time,
                end_time
            ) / 1000.0;

        -- ----------------------------------------
        -- Save individual transaction result
        -- directly into permanent results DB
        -- ----------------------------------------

        INSERT INTO `library_results`.`transaction_result` (
            run_id,
            test_id,
            copy_id,
            member_id,
            execution_time_ms
        )
        VALUES (
            current_run_id,
            i,
            current_copy,
            current_member,
            elapsed_ms
        );

        SET i = i + 1;

    END WHILE;

    -- --------------------------------------------
    -- Update summary metrics for this run
    -- --------------------------------------------

    UPDATE `library_results`.`experiment_run`
    SET
        total_transactions = (
            SELECT COUNT(*)
            FROM `library_results`.`transaction_result`
            WHERE run_id = current_run_id
        ),

        avg_latency_ms = (
            SELECT ROUND(
                AVG(execution_time_ms),
                3
            )
            FROM `library_results`.`transaction_result`
            WHERE run_id = current_run_id
        ),

        min_latency_ms = (
            SELECT ROUND(
                MIN(execution_time_ms),
                3
            )
            FROM `library_results`.`transaction_result`
            WHERE run_id = current_run_id
        ),

        max_latency_ms = (
            SELECT ROUND(
                MAX(execution_time_ms),
                3
            )
            FROM `library_results`.`transaction_result`
            WHERE run_id = current_run_id
        ),

        transactions_per_second = (
            SELECT ROUND(
                COUNT(*) * 1000
                / SUM(execution_time_ms),
                3
            )
            FROM `library_results`.`transaction_result`
            WHERE run_id = current_run_id
        )

    WHERE run_id = current_run_id;

END $$

DELIMITER ;