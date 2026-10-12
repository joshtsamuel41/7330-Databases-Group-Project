DELIMITER $$

CREATE PROCEDURE checkout_optimistic(
    IN p_copy_id INT,
    IN p_member_id INT,
    IN p_staff_id INT,
    IN p_isolation VARCHAR(45)
)
BEGIN
    DECLARE v_version INT;
    DECLARE v_tx_id INT;

    -- Generate transaction ID
    SELECT IFNULL(MAX(tx_id),0) + 1 INTO v_tx_id FROM Transaction_log;

    START TRANSACTION;

    -- Read version
    SELECT version INTO v_version
    FROM Book_copy
    WHERE copy_id = p_copy_id;

    -- Attempt update
    UPDATE Book_copy
    SET status = 'CheckedOut', version = version + 1
    WHERE copy_id = p_copy_id AND version = v_version;

    -- If no rows updated → conflict
    IF ROW_COUNT() = 0 THEN
        INSERT INTO Conflict_log
        VALUES (v_tx_id, v_version, v_version + 1, NOW());

        INSERT INTO Transaction_log
        VALUES (v_tx_id, 'checkout', NOW(), p_isolation, 'optimistic',
                'FALSE', 'TRUE', 'FALSE');

        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- Insert loan
    INSERT INTO Loan
    VALUES (v_tx_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY),
            'Open', NULL, p_copy_id, p_member_id);

    -- Log success
    INSERT INTO Transaction_log
    VALUES (v_tx_id, 'checkout', NOW(), p_isolation, 'optimistic',
            'TRUE', 'FALSE', 'FALSE');

    COMMIT;

    proc_end: BEGIN END;

END$$

DELIMITER ;
