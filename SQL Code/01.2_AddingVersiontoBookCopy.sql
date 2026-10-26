use `library`;

SET SESSION restrict_fk_on_non_standard_key = OFF;
alter table book_copy
add column version int not null default 0;