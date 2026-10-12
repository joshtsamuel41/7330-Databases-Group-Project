DELIMITER $$

CREATE PROCEDURE checkout_optimistic(
    IN p_copy_id INT,
    IN p_member_id INT,
    IN p_isolation VARCHAR(45)
)
BEGIN
    DECLARE v_version INT;
    DECLARE v_tx_id INT;

    -- Generate transaction ID
    SELECT IFNULL(MAX(tx_id),0) + 1 INTO v_tx_id FROM transaction_log;

    START TRANSACTION;

    -- Read version
    SELECT version INTO v_version
    FROM book_copy
    WHERE copy_id = p_copy_id;

    -- Attempt update
    UPDATE book_copy
    SET status = 'CheckedOut', version = version + 1
    WHERE copy_id = p_copy_id AND version = v_version;

    -- Conflict detected
    IF ROW_COUNT() = 0 THEN
        INSERT INTO conflict_log
        VALUES (v_tx_id, v_version, v_version + 1, NOW());

        INSERT INTO transaction_log
        VALUES (v_tx_id, 'checkout', NOW(), p_isolation, 'optimistic',
                'FALSE', 'TRUE', 'FALSE');

        ROLLBACK;
    ELSE
        -- Insert loan
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
        VALUES (v_tx_id, 'checkout', NOW(), p_isolation, 'optimistic',
                'TRUE', 'FALSE', 'FALSE');

        COMMIT;
    END IF;

END$$

DELIMITER ;
