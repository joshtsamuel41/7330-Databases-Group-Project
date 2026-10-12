drop schema if exists library_sim;
create schema if not exists library_sim;
-- copy tables
create table library_sim.book like library.book;
create table library_sim.book_copy like library.book_copy;
create table library_sim.member like library.member;
create table library_sim.loan like library.loan;
create table libary_sim.transaction_log like library.transaction_log;
create table library_sim.conflict_log like library.conflict_log;
create table library_sim.deadlock_log like library.deadlock_log;
-- insert data
INSERT INTO library_sim.Book
SELECT * FROM library.Book;
INSERT INTO library_sim.Book_copy
SELECT * FROM library.Book_copy;
INSERT INTO library_sim.Member
SELECT * FROM library.Member;
INSERT INTO library_sim.Loan
SELECT * FROM library.Loan;
INSERT INTO library_sim.Transaction_log
SELECT * FROM library.Transaction_log;
INSERT INTO library_sim.Conflict_log
SELECT * FROM library.Conflict_log;
INSERT INTO library_sim.Deadlock_log
SELECT * FROM library.Deadlock_log;
-- verify counts match
select count(*) from library.book;
select count(*) from library_sim.book;

use library_sim;