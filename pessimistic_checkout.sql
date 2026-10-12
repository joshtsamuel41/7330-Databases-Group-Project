DELIMITER $$

CREATE PROCEDURE checkout_pessimistic(
    IN p_copy_id INT,
    IN p_member_id INT,
    IN p_isolation VARCHAR(45)
)
BEGIN
    DECLARE v_status VARCHAR(45);
    DECLARE v_tx_id INT;
    DECLARE v_deadlock INT DEFAULT 0;

    -- Deadlock handler
    DECLARE CONTINUE HANDLER FOR 1213
    BEGIN
        SET v_deadlock = 1;
    END;

    -- Generate transaction ID
    SELECT IFNULL(MAX(tx_id),0) + 1 INTO v_tx_id FROM transaction_log;

    SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

    START TRANSACTION;

    -- Try to lock the row
    SELECT status INTO v_status
    FROM book_copy
    WHERE copy_id = p_copy_id
    FOR UPDATE;

    -- Deadlock occurred
    IF v_deadlock = 1 THEN
        INSERT INTO transaction_log
        VALUES (v_tx_id, 'checkout', NOW(), p_isolation, 'pessimistic',
                'FALSE', 'FALSE', 'TRUE');
        ROLLBACK;
    ELSEIF v_status <> 'Available' THEN
        INSERT INTO transaction_log
        VALUES (v_tx_id, 'checkout', NOW(), p_isolation, 'pessimistic',
                'FALSE', 'FALSE', 'FALSE');
        ROLLBACK;
    ELSE
        -- Perform checkout
        UPDATE book_copy
        SET status = 'Checked Out'
        WHERE copy_id = p_copy_id;

        INSERT INTO loan
        VALUES (
            v_tx_id,
            CURDATE(),
            DATE_ADD(CURDATE(), INTERVAL 14 DAY),
            'Open',
            NULL,
            p_copy_id,
            p_member_id
        );

        INSERT INTO transaction_log
        VALUES (v_tx_id, 'checkout', NOW(), p_isolation, 'pessimistic',
                'TRUE', 'FALSE', 'FALSE');

        COMMIT;
    END IF;

END$$

DELIMITER ;
