DELIMITER $$

DROP PROCEDURE IF EXISTS checkout_optimistic $$

CREATE PROCEDURE checkout_optimistic(
    IN p_copy_id INT,
    IN p_member_id INT,
    IN p_isolation VARCHAR(45)
)
BEGIN

    DECLARE v_version INT;

    SELECT version
    INTO v_version
    FROM book_copy
    WHERE copy_id = p_copy_id;

    -- DO SLEEP(1);

    UPDATE book_copy
    SET version = version + 1
    WHERE copy_id = p_copy_id
      AND version = v_version;

    IF ROW_COUNT() = 0 THEN

        INSERT INTO conflict_log
        (
            old_version,
            attempted_version,
            timestamp
        )
        VALUES
        (
            v_version,
            v_version + 1,
            NOW()
        );

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
            p_isolation,
            'optimistic',
            'FALSE',
            'TRUE',
            'FALSE'
        );

    ELSE

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
            p_isolation,
            'optimistic',
            'TRUE',
            'FALSE',
            'FALSE'
        );
	commit;
    END IF;

END $$

DELIMITER ;