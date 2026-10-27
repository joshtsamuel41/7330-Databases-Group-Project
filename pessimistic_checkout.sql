DELIMITER $$

DROP PROCEDURE IF EXISTS checkout_pessimistic $$

CREATE PROCEDURE checkout_pessimistic(
    IN p_copy_id INT
)
BEGIN

    DECLARE v_version INT;

    START TRANSACTION;

    SELECT version
    INTO v_version
    FROM book_copy
    WHERE copy_id = p_copy_id
    FOR UPDATE;

    -- DO SLEEP(1);

    UPDATE book_copy
    SET version = version + 1
    WHERE copy_id = p_copy_id;

    INSERT INTO transaction_log
    (
        operation_type,
        timestamp,
        isolation_level,
        strategy,
        success_flag,
        conflict_flag,
        deadlock_flag
    )
    VALUES
    (
        'checkout',
        NOW(),
        'READ COMMITTED',
        'pessimistic',
        'TRUE',
        'FALSE',
        'FALSE'
    );

    COMMIT;

END $$

DELIMITER ;