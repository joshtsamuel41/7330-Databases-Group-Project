use library_sim;
-- Run this once to seed copies 51 through 500
-- 1. Clean out existing copies and loans first to avoid duplicate primary key errors
DELETE FROM loan;
DELETE FROM book_copy;

-- 2. Create a procedure to seed 5,000 book copies
DELIMITER //
CREATE PROCEDURE seed_large_inventory()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 15000 DO
        INSERT INTO book_copy -- (copy_id, condition, status, Book_book_id, version) 
        VALUES (i, '2026-01-01', 'Good', 'Available', 1, 0);
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- 3. Execute and clean up
CALL seed_large_inventory();
DROP PROCEDURE seed_large_inventory;