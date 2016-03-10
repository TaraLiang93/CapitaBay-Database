-- CREATE PROCEDURE addCustomer(IN c_ssn INTEGER,IN c_rate FLOAT,IN c_ccn CHAR(20),IN c_email VARCHAR(50))

call addCustomer(111111111,1.0,"1234-5678-1234-5678","syang@cs.sunysb.edu");
call addCustomer(222222222,1.0,"1234-5678-1234-5678","vicdu@cs.sunysb.edu");
call addCustomer(333333333,1.0,"1234-5678-1234-5678","smith@ic.sunysb.edu");
call addCustomer(444444444,1.0,"1234-5678-1234-5678","pml@cs.sunysb.edu");