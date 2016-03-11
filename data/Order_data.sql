-- CREATE PROCEDURE addOrder(IN o_nos INTEGER, IN o_time TIME, IN o_oid INTEGER,IN o_eid INTEGER
-- 	,IN o_acctNum CHAR(12),IN o_ss VARCHAR(10),IN o_od DATE, IN o_ssn INTEGER)


-- I added a random an employee that handled the proper person
-- (SocialSecurityNumber,NumberOfShares,Time,EmployeeSSN,AccountNumber,StockSymbol,Orderdate)
call addOrder(444444444,75,'21:04:00',789123456,1,'GM','2016-03-09');
call addOrder(222222222,10,'21:10:15',123456789,1,'IBM','2016-02-29');

