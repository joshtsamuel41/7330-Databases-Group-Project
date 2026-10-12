DELIMITER $$

CREATE PROCEDURE checkout_pessimistic(
    IN p_copy_id INT,
    IN p_member_id INT,
    IN p_staff_id INT,
    IN p_isolation VARCHAR(45)
)
BEGIN
    DECLARE v_status VARCHAR(45);
    DECLARE v_tx_id INT;
    DECLARE v_deadlock INT DEFAULT 0;

    -- Deadlock handler must be declared BEFORE any SQL statements
    DECLARE CONTINUE HANDLER FOR 1213
    BEGIN
        SET v_deadlock = 1;
    END;

    -- Generate a transaction ID
    SELECT IFNULL(MAX(tx_id),0) + 1 INTO v_tx_id FROM Transaction_log;

    -- Set isolation level
    SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

    START TRANSACTION;

    -- Attempt to lock the row
    SELECT status INTO v_status
    FROM Book_copy
    WHERE copy_id = p_copy_id
    FOR UPDATE;

    -- If deadlock occurred
    IF v_deadlock = 1 THEN
        INSERT INTO Transaction_log
        VALUES (v_tx_id, 'checkout', NOW(), p_isolation, 'pessimistic',
                'FALSE', 'FALSE', 'TRUE');
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- Check availability
    IF v_status <> 'Available' THEN
        INSERT INTO Transaction_log
        VALUES (v_tx_id, 'checkout', NOW(), p_isolation, 'pessimistic',
                'FALSE', 'FALSE', 'FALSE');
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- Perform checkout
    UPDATE Book_copy
    SET status = 'CheckedOut'
    WHERE copy_id = p_copy_id;

    INSERT INTO Loan
    VALUES (v_tx_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY),
            'Open', NULL, p_copy_id, p_member_id);

    -- Log success
    INSERT INTO Transaction_log
    VALUES (v_tx_id, 'checkout', NOW(), p_isolation, 'pessimistic',
            'TRUE', 'FALSE', 'FALSE');

    COMMIT;

    proc_end: BEGIN END;

END$$

DELIMITER ;
