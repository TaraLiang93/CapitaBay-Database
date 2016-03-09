-- addEmployee(IN e_ssn INTEGER,IN e_pos VARCHAR(12),IN e_date DATE,IN e_hrRate FLOAT,IN e_id INTEGER)

call addEmployee(123456789,"Manager",STR_TO_DATE('11-1-05', '%d-%m-%Y'),60.0,1);
call addEmployee(789123456,"CustomerRep",STR_TO_DATE('2-2-06', '%d-%m-%Y'),50.0,2);