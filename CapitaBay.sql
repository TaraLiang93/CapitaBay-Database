/*******************************************************************************
* CSE 305: Spring 2016: Online Stock Exchange
* Team: Capita Bay
* Members: Patrick Sullivan, Hui Liang
*******************************************************************************/
drop database IF EXISTS CAPITABAY;
create database CAPITABAY;
USE CAPITABAY;

/*******************************************************************************  
Location: represents where the person lives in our db *******************************************************************************/
CREATE TABLE Location(
	ZipCode	INTEGER			,
	City 		VARCHAR(32)		NOT NULL,
	State		VARCHAR(20)		NOT NULL,
	PRIMARY KEY(ZipCode)
);

/*******************************************************************************  
Person: represents a user who will access our database  
*******************************************************************************/
CREATE TABLE Person (
FirstName 		VARCHAR(32)	 NOT NULL, 
LastName 		VARCHAR(32)	 NOT NULL,
Address 		VARCHAR(128)	 NOT NULL,
Telephone 		CHAR(13)	 	 NOT NULL,
Username VARCHAR(32) NOT NULL,
Password VARCHAR(100) NOT NULL,
ZipCode	INTEGER,
SocialSecurityNumber	 INTEGER,
PRIMARY KEY(SocialSecurityNumber),
UNIQUE(Username),
FOREIGN KEY(ZipCode) REFERENCES Location(ZipCode)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
);

/*******************************************************************************  
Employee: represents a user who will facilitate the buying and selling of stocks
  *******************************************************************************/
CREATE TABLE Employee (
SocialSecurityNumber	 INTEGER,
Position 		VARCHAR(12) 		NOT NULL,
StartDate 		DATE			NOT NULL,
HourlyRate 		FLOAT			NOT NULL,
PRIMARY KEY(SocialSecurityNumber),
-- UNIQUE(SocialSecurityNumber),
FOREIGN KEY(SocialSecurityNumber) REFERENCES Person(SocialSecurityNumber)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
);

-- -- CREATE DOMAIN POSITION  VARCHAR(12)
-- -- 	CHECK ( VALUE IN ( “CustomerRep”, “Manager” ) )

/*******************************************************************************  
Customer: represents a user who will be buying and selling stocks 
 *******************************************************************************/
CREATE TABLE Customer (
SocialSecurityNumber INTEGER,
Rating 			FLOAT			NOT NULL,
CreditCardNumber 	CHAR(20)			NOT NULL,
Email 			VARCHAR(50)	NOT NULL,
PRIMARY KEY(SocialSecurityNumber),
UNIQUE(Email),
FOREIGN KEY(SocialSecurityNumber) REFERENCES Person(SocialSecurityNumber)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
);

/*******************************************************************************  
Stock Account: represents an account for a customer having 0 or more accounts
*******************************************************************************/
CREATE TABLE StockAccount (
SocialSecurityNumber INTEGER,
AccountNumber INTEGER,
AccountCreateDate DATE NOT NULL,
-- PRIMARY KEY(SocialSecurityNumber),
PRIMARY KEY(SocialSecurityNumber,AccountNumber),
FOREIGN KEY(SocialSecurityNumber) REFERENCES Customer(SocialSecurityNumber)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);

/*********************************************************************************
Stock Table: represents the stocks in the stock exchange system.
*********************************************************************************/
CREATE TABLE StockTable (
	StockSymbol		VARCHAR(10),
	StockType		VARCHAR(32)	 NOT NULL,
	StockName		VARCHAR(32)	NOT NULL,
	SharePrice			FLOAT,
	StockDate				DATE,
	StockTime				TIME,
	NumberOfSharesAvaliable	INTEGER,
	PRIMARY KEY(StockSymbol),
	 KEY(StockDate),
	 KEY(StockTime)
);

/*********************************************************************************
Individual Stock: represents a stock price and share number at a certain period of time.
*********************************************************************************/
CREATE TABLE StockHistory (
	SharePrice			FLOAT,
	StockSymbol			VARCHAR(10),
	StockDate				DATE,
	StockTime				TIME,
	NumberOfSharesAvaliable	INTEGER,
	PRIMARY KEY(StockSymbol,StockDate,StockTime, NumberOfSharesAvaliable),
	FOREIGN KEY(StockSymbol) REFERENCES StockTable(StockSymbol)
		ON DELETE NO ACTION
		ON UPDATE CASCADE
);

/******************************************************************************  
Order: information relating to the buying and selling of a number of shares of a certain stock
  ******************************************************************************/
CREATE TABLE Orders (
SocialSecurityNumber INTEGER,
NumberOfShares	 INTEGER,
OrderTime 			TIME,
OrderID			INTEGER AUTO_INCREMENT,
EmployeeSSN		INTEGER,
AccountNumber	INTEGER,
StockSymbol		VARCHAR(10)		NOT NULL,
OrderDate		DATE	NOT NULL,
SharePrice			FLOAT,
OrderType		VARCHAR(32),
PRIMARY KEY(OrderID),
FOREIGN KEY(SocialSecurityNumber,AccountNumber) REFERENCES StockAccount(SocialSecurityNumber,AccountNumber)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
FOREIGN KEY(EmployeeSSN) REFERENCES Employee(SocialSecurityNumber)
	ON DELETE SET NULL
	ON UPDATE CASCADE,
FOREIGN KEY(StockSymbol) REFERENCES StockTable(StockSymbol)
	ON DELETE NO ACTION 
	ON UPDATE CASCADE
-- FOREIGN KEY(OrderDate) REFERENCES StockHistory(StockDate)
-- 	ON DELETE NO ACTION
-- 	ON UPDATE CASCADE
);



/*******************************************************************************  
Market: information market order 
*******************************************************************************/
CREATE TABLE Market (
OrderID 		INTEGER,
PRIMARY KEY(OrderID),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
ON DELETE NO ACTION
ON UPDATE CASCADE
	
);

/******************************************************************************  
MarketOnClose: information Market on Close order 
******************************************************************************/
CREATE TABLE MarketOnClose (
OrderID 		INTEGER,
PRIMARY KEY(OrderID),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
ON DELETE NO ACTION
ON UPDATE CASCADE
	
);
/*******************************************************************************  
TrailingStop: information Trailing Stop order
 *******************************************************************************/
CREATE TABLE TrailingStop (
OrderID 		INTEGER,
Percentage		FLOAT,
PricePerShare 	FLOAT,
PRIMARY KEY(OrderID),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
ON DELETE NO ACTION
ON UPDATE CASCADE
);
/******************************************************************************  
Hidden Stop: information hidden stop order
 ******************************************************************************/
CREATE TABLE HiddenStop (
OrderID 		INTEGER,
PricePerShare		FLOAT,
PRIMARY KEY(OrderID),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
ON DELETE NO ACTION
ON UPDATE CASCADE
	
);

/******************************************************************************
Transaction: information when a order is processed and carried out
******************************************************************************/
CREATE TABLE Transaction(
TransID		INTEGER,
EmployeeSSN INTEGER,
SocialSecurityNumber INTEGER,
AccountNumber INTEGER,
StockSymbol		VARCHAR(10),
Fee			FLOAT NOT NULL,
DateProcessed 	DATE,
PricePerShare	FLOAT CHECK(PricePerShare>=0),
PRIMARY KEY(TransID),
FOREIGN KEY(TransID) REFERENCES Orders(OrderID) ON DELETE NO ACTION ON UPDATE CASCADE,
FOREIGN KEY(EmployeeSSN) REFERENCES Employee(SocialSecurityNumber) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY(SocialSecurityNumber,AccountNumber) REFERENCES StockAccount(SocialSecurityNumber,AccountNumber)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
FOREIGN KEY(StockSymbol) REFERENCES StockTable(StockSymbol) ON DELETE NO ACTION ON UPDATE CASCADE

);




DELIMITER $$
/******************************************************************************  
TRIGGERS
 ******************************************************************************/
CREATE TRIGGER checkShareNumber BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
	IF NEW.NumberOfShares < 0 THEN
		SET NEW.NumberOfShares = 0;
	END IF;
	call queryNumShareAva(NEW.StockSymbol);
	IF NEW.NumberOfShares > @numShareAva THEN
		SET NEW.NumberOfShares = 0;
	END IF;
END $$


/******************************************************************************  
INSERT QUERIES
 ******************************************************************************/
CREATE PROCEDURE addTransaction(IN o_tid INTEGER, IN t_eid INTEGER, IN t_ssn INTEGER, IN t_accNum INTEGER,
	IN t_ss VARCHAR(10), IN t_fee FLOAT, IN t_dp DATE, IN t_t TIME, IN t_pps FLOAT, IN m_ot VARCHAR(32))
BEGIN 
	DECLARE newShareAva INTEGER;
	INSERT INTO CAPITABAY.Transaction(TransID, EmployeeSSN, SocialSecurityNumber, AccountNumber, StockSymbol, Fee, DateProcessed,PricePerShare)
	VALUES(o_tid, t_eid, t_ssn, t_accNum, t_ss, t_fee, t_dp,t_pps);		
	call queryNumShareAva(t_ss);
	call queryOrderShares(o_tid);
	IF m_ot = 'buy' THEN
		SELECT @numShareAva - @oShare INTO newShareAva;
	ELSE
		SELECT @numShareAva + @oShare INTO newShareAva;
	END IF;
	call updateStockTableNumShare(t_ss, newShareAva, t_dp, t_t);
END $$


CREATE PROCEDURE addLocation(IN lcl_zipCode INTEGER,IN lcl_city VARCHAR(32),lcl_state VARCHAR(20))
BEGIN
	INSERT INTO CAPITABAY.Location(ZipCode, City, State)
  	VALUES(lcl_zipCode,lcl_city,lcl_state);
End $$


CREATE PROCEDURE addPerson(IN p_fname VARCHAR(32),IN p_lname VARCHAR(32),IN p_addr VARCHAR(128),IN p_tele CHAR(13),
 IN p_zipcode INTEGER,IN p_ssn INTEGER, IN username VARCHAR(32), IN password VARCHAR(100))
BEGIN
	INSERT INTO CAPITABAY.Person(FirstName, LastName, Address,Telephone, ZipCode, SocialSecurityNumber, Username, Password)
  	VALUES(p_fname,p_lname,p_addr,p_tele,p_zipcode,p_ssn, username, password);
End $$


CREATE PROCEDURE addEmployee(IN e_ssn INTEGER,IN e_pos VARCHAR(12),IN e_date DATE,IN e_hrRate FLOAT)
BEGIN
	INSERT INTO CAPITABAY.Employee(SocialSecurityNumber,Position,StartDate,HourlyRate)
  	VALUES(e_ssn,e_pos,e_date,e_hrRate);
End $$
	
CREATE PROCEDURE addCustomer(IN c_ssn INTEGER,IN c_rate FLOAT,IN c_ccn CHAR(20),IN c_email VARCHAR(50))
BEGIN
	INSERT INTO CAPITABAY.Customer(SocialSecurityNumber,Rating,CreditCardNumber,Email)
  	VALUES(c_ssn,c_rate ,c_ccn,c_email);
End $$


CREATE PROCEDURE addStockAccount(IN sa_ssn INTEGER,IN sa_acctNum CHAR(12),IN sa_acctDate DATE)
BEGIN
	INSERT INTO CAPITABAY.StockAccount(SocialSecurityNumber,AccountNumber,AccountCreateDate)
  	VALUES(sa_ssn,sa_acctNum,sa_acctDate );
End $$


CREATE PROCEDURE addStockTable(IN st_ss VARCHAR(10),IN st_st VARCHAR(32),IN st_sn VARCHAR(32),
	IN price FLOAT, IN s_date DATE, IN s_time TIME, IN NumberOfShares INTEGER)
BEGIN
	INSERT INTO CAPITABAY.StockTable(StockSymbol,StockType,StockName, SharePrice,
		 StockDate, StockTime, NumberOfSharesAvaliable)
  	VALUES(st_ss,st_st,st_sn, price, s_date, s_time, NumberOfShares);
	call addStockHistory(price, st_ss, s_date, s_time, NumberOfShares);
End $$


CREATE PROCEDURE addStockHistory(IN is_sp FLOAT,IN is_ss VARCHAR(10),IN is_dat DATE, IN is_time TIME,IN is_nosa INTEGER)
BEGIN
	INSERT INTO CAPITABAY.StockHistory(SharePrice,StockSymbol,StockDate, StockTime, NumberOfSharesAvaliable)
  	VALUES(is_sp,is_ss,is_dat, is_time,is_nosa);
End $$

CREATE PROCEDURE addOrder(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN price FLOAT, IN o_type VARCHAR(32))
BEGIN 

	INSERT INTO CAPITABAY.Orders(SocialSecurityNumber, NumberOfShares, 
		OrderTime, EmployeeSSN, AccountNumber, StockSymbol, OrderDate, SharePrice, OrderType)
	VALUES(ssn, nos, o_time, e_ssn, an, ss, dat, price, o_type);
END $$



CREATE PROCEDURE addMarket(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN m_ot VARCHAR(32) )
BEGIN
  	call queryCurrentPricePerShare(ss);
	call addOrder(ssn, nos, o_time, e_ssn, an, ss, dat, @price, m_ot);
	call queryOrderId(ssn, o_time, e_ssn, an, ss, dat);
	INSERT INTO CAPITABAY.Market(OrderID)
  	VALUES(@o_id);
  	call CalcFee(@price, nos);
  	-- If(("sell" = m_ot) IS true) then
  	-- call addTransaction(@o_id, e_ssn, ssn, an, ss, @fee, dat, o_time, @price, m_ot);
  	
  	-- else
  	 call addTransaction(@o_id, e_ssn, ssn, an, ss, @fee, dat, o_time, @price, m_ot);
  	-- end if;
End $$

CREATE PROCEDURE addMarketOnClose(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN m_ot VARCHAR(32))
BEGIN
  	call queryCurrentPricePerShare(ss);
	call addOrder(ssn, nos, o_time, e_ssn, an, ss, dat, @price, m_ot);
	call queryOrderId(ssn, o_time, e_ssn, an, ss, dat);
	INSERT INTO CAPITABAY.MarketOnClose(OrderID)
  	VALUES(@o_id);
  	call CalcFee(@price, nos);
  	-- If(("sell" = m_ot) IS true) then
  	call addTransaction(@o_id, e_ssn, ssn, an, ss, @fee, dat, o_time, @price, m_ot);
  	
  	-- else call addTransaction(@o_id, e_ssn, ssn, an, ss, 0, dat, o_time, @price, m_ot);
End $$

CREATE PROCEDURE addTrailingStop(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE,IN  m_percent FLOAT)
BEGIN
	call addOrder(ssn, nos, o_time, e_ssn, an, ss, dat, NULL, 'sell');
  	call queryCurrentPricePerShare(ss);
	call queryOrderId2(ssn, o_time, e_ssn, an, ss, dat, @price);
	INSERT INTO CAPITABAY.TrailingStop(OrderID,Percentage, PricePerShare)
  	VALUES(@o_id,m_percent,@price);
End $$

CREATE PROCEDURE addHiddenStop(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN  m_pps FLOAT)
BEGIN
	call addOrder(ssn, nos, o_time, e_ssn, an, ss, dat, NULL, 'sell');
	call queryCurrentPricePerShare(ss);
	call queryOrderId2(ssn, o_time, e_ssn, an, ss, dat, @price);
	INSERT INTO CAPITABAY.HiddenStop(OrderID,PricePerShare)
  	VALUES(@o_id,m_pps);
End $$
	
/*****************************************************************************  
HiddenStop or Trailing stop Procedure
 ****************************************************************************/
-- CREATE PROCEDURE checkHSOrder(IN stockSym VARCHAR(10), IN SharePrice FLOAT)
-- BEGIN
-- 	DECLEAR i INT DEFAULT 0;
-- 	DECLEAR n INT DEFAULT 0;
-- 	Select COUNT(*) FROM HSCheckTable INTO n;
-- 	WHILE i < n DO 
-- 		Select * INTO @HSorderInd FROM HSCheckTable LIMIT i, 1;
-- 		IF EXISTS(Select * From HiddenStop Where HiddenStop.OrderID = @HSorderInd) THEN
-- 			Select HiddenStop.PricePerShare INTO @HSPrice From HiddenStop Where HiddenStop.OrderID = @HSorderInd;
-- 			IF SharePrice < @HSPrice THEN
-- 				call processCondOrder(@HSorderInd, @HSPrice, stockSym);
-- 			END IF;
-- 		END IF;
-- 		i ++;
-- 	END WHILE;
-- END $$

CREATE PROCEDURE validUser(IN username VARCHAR(32), IN password VARCHAR(100))
BEGIN
	SELECT P.SocialSecurityNumber, P.Username
	FROM Person P
	WHERE ((P.Username = username)&&(P.Password = password));
END $$

CREATE PROCEDURE checkTSOrder (IN ss VARCHAR(10), IN SharePrice FLOAT)
BEGIN
	DECLARE i INT;
	DECLARE n INT;
	DECLARE FinalTSPrice FLOAT;
	DECLARE countExist INT;
	SET i = 0;
	SET n = 0;	
	SET countExist = 0;

CREATE OR REPLACE VIEW TSCheckTable AS
		Select Orders.OrderID AS ID, Orders.StockSymbol AS StockSymbol
		From Orders, TrailingStop
		Where  Orders.OrderType = 'sell';	

	Select COUNT(*) FROM TSCheckTable INTO n;
	WHILE i < n DO 
		SET countExist = 0;
		Select ID INTO @TSorderInd FROM TSCheckTable WHERE TSCheckTable.StockSymbol = ss  LIMIT i, 1;
		Select COUNT(*) From TrailingStop Where TrailingStop.OrderID = @TSorderInd INTO countExist; 
		IF countExist > 0 THEN
			Select TrailingStop.Percentage INTO @TSPercent From TrailingStop Where TrailingStop.OrderID = @TSorderInd;
			Select TrailingStop.PricePerShare INTO @TSPrice From TrailingStop Where TrailingStop.OrderID = @TSorderInd;
		 	SET FinalTSPrice = ((1- @TSPercent)*@TSPrice);
			IF SharePrice < FinalTSPrice THEN
				call queryCurrentPricePerShare(ss);
				call processCondOrder(@TSorderInd, @price, ss);
			END IF;
		END IF;
		SET i = i +1;
	END WHILE;
END $$

 CREATE PROCEDURE checkHSOrder(IN ss VARCHAR(10),IN  SharePrice FLOAT)
 BEGIN 
 	DECLARE i INT;
	DECLARE n INT;
	DECLARE countExist INT;
	SET countExist = 0;
	SET i = 0;
	SET n = 0;

	CREATE OR REPLACE VIEW HSCheckTable AS
		Select Orders.OrderID AS ID, Orders.StockSymbol AS StockSymbol
		From Orders, HiddenStop
		Where Orders.OrderType = 'sell';

	Select COUNT(*) FROM HSCheckTable INTO n;
	WHILE i < n DO 
		SET countExist = 0;
		Select ID INTO @HSorderInd FROM HSCheckTable WHERE HSCheckTable.StockSymbol = ss  LIMIT i, 1;
		Select COUNT(*) From HiddenStop Where HiddenStop.OrderID = @HSorderInd INTO countExist;
		IF countExist>0 THEN
			Select HiddenStop.PricePerShare INTO @HSPrice From HiddenStop Where HiddenStop.OrderID = @HSorderInd;
			IF SharePrice < @HSPrice THEN
				call queryPricePerShare(CURTIME(), CURDATE());
				call processCondOrder(@HSorderInd, @price, ss);
			END IF;
		END IF;
		SET i = i +1;
	END WHILE;
 END $$

CREATE PROCEDURE processCondOrder(IN ID INTEGER, IN price FLOAT, IN stockSym VARCHAR(10))
BEGIN 
	UPDATE Orders o
	SET o.SharePrice = price
	Where OrderID = ID;
	call queryEmployeeSsnByOId(ID);
	call queryCustomerSsnByOId(ID);
	call queryCustomerAcctByOId(ID);
	call queryNumShareByOrder(ID);
	call CalcFee(price, @nos);
	call addTransaction(ID, @e_ssn, @c_ssn, @o_custAct, stockSym, @fee, CURDATE(), CURTIME(),price,'sell');
	-- Fee, DateProcessed,PricePerShare)
END $$

/*****************************************************************************  
Supplment QUERIES for inserting
 *****************************************************************************/
 CREATE PROCEDURE queryNumShareByOrder(IN o_id INTEGER)
 BEGIN 
 	SELECT Orders.NumberOfShares INTO @nos
 	From Orders
 	Where Orders.OrderID = o_id;
 END $$

 CREATE PROCEDURE queryEmployeeSsnByOId(IN o_id INTEGER)
 BEGIN 
 	SELECT Orders.EmployeeSSN INTO @e_ssn
 	From Orders
 	Where Orders.OrderID = o_id;
 END$$

 CREATE PROCEDURE queryCustomerSsnByOId(IN o_id INTEGER)
 BEGIN 
 	SELECT Orders.SocialSecurityNumber INTO @c_ssn
 	From Orders
 	Where Orders.OrderID = o_id;
 END$$

 CREATE PROCEDURE queryCustomerAcctByOId(IN o_id INTEGER)
 BEGIN 
 	SELECT Orders.AccountNumber INTO @o_custAct
 	From Orders
 	Where Orders.OrderID = o_id;
 END$$

CREATE PROCEDURE queryOrderId(IN ssn INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE)
BEGIN 
	SELECT o.OrderID INTO @o_id FROM Orders o WHERE (o.SocialSecurityNumber = ssn AND 
		(o.OrderTime = o_time AND (o.EmployeeSSN = e_ssn AND
		(o.AccountNumber = an AND (o.StockSymbol = ss)))));
END $$

CREATE PROCEDURE queryOrderId2(IN ssn INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN price FLOAT)
BEGIN 
	SELECT o.OrderID INTO @o_id FROM Orders o WHERE (o.SocialSecurityNumber = ssn AND 
		(o.OrderTime = o_time AND (o.EmployeeSSN = e_ssn AND
		(o.AccountNumber = an AND (o.StockSymbol = ss AND
		 o.OrderType ='sell')))));
END $$


CREATE PROCEDURE CalcFee(IN price FLOAT, IN numShare INTEGER)
BEGIN
	SELECT (price * numShare)*0.05 INTO @fee;
END $$

CREATE PROCEDURE queryPricePerShare(IN o_time TIME, IN dat DATE)
BEGIN 
	SELECT i.SharePrice INTO @price
	FROM StockHistory i 
	Where i.StockDate < dat AND i.StockTime < o_time 
	ORDER BY i.StockDate DESC LIMIT 1;
END $$

CREATE PROCEDURE queryCurrentPricePerShare(IN o_ss VARCHAR(10))
BEGIN 
	SELECT i.SharePrice INTO @price
	FROM StockTable i 
	Where i.StockSymbol = o_ss; 
END $$

CREATE PROCEDURE queryNumShareAva(IN stockSym VARCHAR(10))
BEGIN 
	SELECT i.NumberOfSharesAvaliable INTO @numShareAva
	FROM StockTable i
	Where i.StockSymbol = stockSym;
END $$

CREATE PROCEDURE queryOrderShares(IN o_id INTEGER)
BEGIN 
	SELECT o.NumberOfShares INTO @oShare
	FROM Orders o
	Where o.OrderID = o_id;
END $$

CREATE PROCEDURE queryOrderDate(IN o_id INTEGER)
BEGIN 
	SELECT o.OrderDate INTO @oDate
	FROM Orders o
	Where o.OrderID = o_id;
END $$

CREATE PROCEDURE queryOrderTime(IN o_id INTEGER)
BEGIN 
	SELECT o.OrderTime INTO @oTime
	FROM Orders o
	Where o.OrderID = o_id;
END $$

CREATE PROCEDURE queryStockType(IN stockSym VARCHAR(10))
BEGIN	
	SELECT DISTINCT s.StockType INTO @st_type
	FROM StockTable s
	WHERE stockSym = s.StockSymbol;
END $$

CREATE PROCEDURE queryCustomerStocks(IN c_ssn INTEGER)
BEGIN 
	SELECT o.StockSymbol INTO @oSS
	FROM Orders o
	Where o.SocialSecurityNumber = c_ssn;
END $$

/******************************************************************************  
UPDATE QUERIES
 ******************************************************************************/
CREATE PROCEDURE editEmployee(IN e_ssn INTEGER,IN e_pos VARCHAR(12),IN e_hrRate FLOAT)
BEGIN
	UPDATE Employee
	SET Position=e_pos, HourlyRate=e_hrRate
  	WHERE SocialSecurityNumber = e_ssn; 
End $$

CREATE PROCEDURE updateStockTablePrice(IN Sym VARCHAR(10), IN price FLOAT, IN s_date DATE,
	IN s_time TIME)
BEGIN
	UPDATE StockTable
	SET SharePrice = price, StockDate = s_date, StockTime = s_time
	WHERE StockSymbol = Sym;
	call queryNumShareAva(Sym);
	call addStockHistory(price, Sym, s_date, s_time, @numShareAva);
	call queryCurrentPricePerShare(Sym);
	call checkHSOrder(Sym, @price);
	call checkTSOrder(Sym, @price);
END $$

CREATE PROCEDURE updateStockTableNumShare(IN Sym VARCHAR(10), IN shareAvaliable INTEGER,
	IN s_date DATE, IN s_time TIME)
BEGIN
	UPDATE StockTable
	SET NumberOfSharesAvaliable = shareAvaliable, StockDate = s_date, StockTime = s_time
	WHERE StockSymbol = Sym;
	call queryCurrentPricePerShare(Sym);
	call addStockHistory(@price, Sym, s_date, s_time, shareAvaliable);
END$$

CREATE PROCEDURE editPerson(IN p_fname VARCHAR(32),IN p_lname VARCHAR(32),IN p_addr VARCHAR(128),IN p_tele CHAR(13), IN p_zipcode INTEGER,IN p_ssn INTEGER)
BEGIN
	UPDATE Customer
	SET FirstName = p_fname, LastName = p_lname, Address = p_addr, Telephone = p_tele, ZipCode = p_zipcode 
	WHERE SocialSecurityNumber = p_ssn;
End $$
 
CREATE PROCEDURE editCustomer(IN c_ssn INTEGER,IN c_rate FLOAT,IN c_ccn CHAR(20),IN c_email VARCHAR(50))
BEGIN
	UPDATE Customer
	SET Rating = c_rate, CreditCardNumber = c_ccn, Email = c_email 
	WHERE SocialSecurityNumber = c_ssn;
End $$


-- *****************************************************************************  
-- DELETE QUERIES 
--  *****************************************************************************
CREATE PROCEDURE deleteEmployee(IN e_ssn INTEGER)
BEGIN
	DELETE FROM Employee
	WHERE SocialSecurityNumber = e_ssn;
End $$

CREATE PROCEDURE deleteStockTable(IN Sym VARCHAR(10))
BEGIN 
	DELETE FROM StockTable
	WHERE StockSymbol = Sym;
END $$

CREATE PROCEDURE deleteCustomer(IN c_ssn INTEGER)
BEGIN
	DELETE FROM Customer
	WHERE SocialSecurityNumber = c_ssn;
End $$


/******************************************************************************  
Manager QUERIES
 ******************************************************************************/
CREATE PROCEDURE updateStockPrice(IN e_ssn INTEGER,IN is_ss VARCHAR(10),IN new_sp FLOAT)
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE )
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		UPDATE StockHistory
		SET SharePrice = new_sp
		WHERE  StockSymbol = is_ss;
	END IF;

END $$


CREATE PROCEDURE manageEmployees(IN reqeust VARCHAR(12),IN e_ssn1 INTEGER,IN e_ssn2 INTEGER,IN e_pos VARCHAR(12),IN e_hrRate FLOAT)
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);
	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn1;

	IF currentEmployeePosition = 'Manager' THEN
		IF reqeust = 'INSERT' THEN
			call addEmployee(e_ssn2,e_pos,e_date,e_hrRate);
		ELSEIF reqeust = 'UPDATE' THEN
			call editEmployee(e_ssn2,e_pos,e_hrRate);
		ELSEIF reqeust = 'DELETE' THEN
			call deleteEmployee(e_ssn2);
		END IF;
	END IF;

END $$

CREATE PROCEDURE getSalesReportForMonth(IN e_ssn INTEGER, IN month INTEGER)
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		Select *
		FROM Orders
		WHERE MONTH(OrderDate) = month; -- Takes both integer and string
	END IF;

END $$

CREATE PROCEDURE listAllStocks(IN e_ssn INTEGER)
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		SELECT DISTINCT S.StockSymbol, S.StockType,S.StockName, S.SharePrice, S.StockDate,S.NumberOfSharesAvaliable
		FROM StockTable S;
	END IF;

END $$

CREATE PROCEDURE listOrders(IN e_ssn INTEGER,IN name VARCHAR(20),IN ss VARCHAR(10))
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		IF name <> "" THEN 
			SELECT O.*
			FROM Orders O
			INNER JOIN Person P 
			ON P.SocialSecurityNumber = O.SocialSecurityNumber
			WHERE CONCAT(P.Firstname, ' ', P.LastName) LIKE CONCAT("%", name, "%");
		ELSEIF ss <> "" THEN
			SELECT * 
			FROM Orders O
			WHERE StockSymbol = ss;
		END IF; 
	END IF;

END $$

CREATE PROCEDURE listRevenueByStock(IN e_ssn INTEGER,IN Sym VARCHAR(10))
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		SELECT S.StockSymbol,SUM(T.Fee) AS Revenue
		FROM StockTable S 
		INNER JOIN Transaction T 
		ON S.StockSymbol = T.StockSymbol 
		WHERE S.StockSymbol = Sym;
	END IF;

END $$

CREATE PROCEDURE listRevenueByStockType(IN e_ssn INTEGER,IN stockty VARCHAR(32))
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		SELECT DISTINCT S.StockType,SUM(T.Fee) AS Revenue
		FROM StockTable S
		INNER JOIN Transaction T 
		ON S.StockSymbol = T.StockSymbol 
		WHERE S.StockType = stockty;
	END IF;

END $$

CREATE PROCEDURE listRevenueCustomer(IN e_ssn INTEGER,IN c_ssn INTEGER)
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		SELECT P.FirstName,P.LastName,T.SocialSecurityNumber,SUM(T.Fee) AS Revenue
		FROM Transaction T
		INNER JOIN Person P
		ON P.SocialSecurityNumber = T.SocialSecurityNumber
		WHERE P.SocialSecurityNumber = c_ssn;
	END IF;

END $$

CREATE PROCEDURE richestRep(IN e_ssn INTEGER)
BEGIN
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
	SELECT P.FirstName, P.LastName, P.SocialSecurityNumber, SUM(T.Fee) AS Revenue
	FROM Transaction T 
	INNER JOIN Person P
	ON P.SocialSecurityNumber = T.EmployeeSSN
	INNER JOIN Employee E
	ON E.SocialSecurityNumber = P.SocialSecurityNumber
	WHERE E.Position = 'CustomerRep'
	GROUP BY P.SocialSecurityNumber
	ORDER BY Revenue DESC
	LIMIT 1;

	END IF;


END $$

CREATE PROCEDURE richestCustomer(IN e_ssn INTEGER)
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		SELECT O.SocialSecurityNumber,P.FirstName,P.LastName,SUM(O.NumberOfShares*O.SharePrice) AS Revenue
		FROM Orders O 
		INNER JOIN Person P
		ON P.SocialSecurityNumber = O.SocialSecurityNumber
		WHERE O.OrderType = 'sell'
		GROUP BY O.SocialSecurityNumber
		ORDER BY Revenue DESC
		LIMIT 1;
	END IF;

END $$

CREATE PROCEDURE mostPopularStocks(IN e_ssn INTEGER)
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		SELECT O.StockSymbol,S.StockName, S.NumberOfSharesAvaliable,S.SharePrice
		FROM Orders O
		INNER JOIN StockTable S
		ON S.StockSymbol = O.StockSymbol
		GROUP BY O.StockSymbol
		ORDER BY COUNT(*) DESC;
	END IF;

END $$

CREATE PROCEDURE listBestSellingStock()
BEGIN
	SELECT StockTable.StockSymbol
	FROM StockTable
	INNER JOIN Transaction
	ON StockTable.StockSymbol = Transaction.StockSymbol
	GROUP BY StockSymbol
	ORDER BY COUNT(*) DESC
	LIMIT 5;
	
END $$
/******************************************************************************  
CustomerRep QUERIES
 ******************************************************************************/
CREATE PROCEDURE makeCustomerMailingList(IN e_ssn INTEGER)
BEGIN
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'CustomerRep' 
		OR currentEmployeePosition = 'Manager' THEN
		SELECT C.Email  
		FROM Customer C;
	END IF;
	
	
END $$

CREATE PROCEDURE makeStockSuggestionList(IN e_ssn INTEGER, IN c_ssn INTEGER)
BEGIN
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'CustomerRep' 
		OR currentEmployeePosition = 'Manager' THEN
		call queryCustomerStocks(c_ssn);
		call queryStockType(@oSS);
		SELECT s.StockSymbol
		FROM StockTable s
		WHERE s.StockType = @st_type;
	END IF;
	
	
END $$

CREATE PROCEDURE recordOrder(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN m_ot VARCHAR(32))
BEGIN
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'CustomerRep' 
		OR currentEmployeePosition = 'Manager' THEN
		IF m_ot = 'Market' THEN
			call addMarket(ssn, nos, o_time, e_ssn, an, ss, dat, m_ot);
		ELSEIF m_ot = 'MarketOnClose' THEN
			call addMarketOnClose(ssn, nos, o_time, e_ssn, an, ss, dat, m_ot);
		ELSEIF m_ot = 'TrailingStop' THEN
			call addTrailingStop(ssn, nos, o_time, e_ssn, an, ss, dat, m_ot, m_percent);
		ELSEIF m_ot = 'HiddenStop' THEN	
			call addHiddenStop(ssn, nos, o_time, e_ssn, an, ss, dat, m_ot, m_percent);
		END IF;
	END IF;
END $$

CREATE PROCEDURE manageCustomers(IN reqeust VARCHAR(12),IN e_ssn INTEGER,IN c_ssn INTEGER,
	IN c_rate FLOAT,IN c_ccn CHAR(20),IN c_email VARCHAR(50))
BEGIN
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'CustomerRep' 
		OR currentEmployeePosition = 'Manager' THEN
		IF reqeust = 'INSERT' THEN
			call addCustomer(c_ssn, c_rate, c_ccn, c_email);
		ELSEIF reqeust = 'UPDATE' THEN
			call editCustomer(c_ssn, c_rate, c_ccn, c_email);
		ELSEIF reqeust = 'DELETE' THEN
			call deleteCustomer(c_ssn);
		END IF;
	END IF;

END $$




/******************************************************************************  
Customer QUERIES
 ******************************************************************************/
CREATE PROCEDURE getStockSuggestionList(IN c_ssn INTEGER)
BEGIN
	call queryCustomerStocks(c_ssn);
	call queryStockType(@oSS);
	SELECT s.*
	FROM StockTable s
	WHERE s.StockType = @st_type;
END $$

CREATE PROCEDURE OrderHistory(IN c_ssn INTEGER)
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE )

	DECLARE customer	 INTEGER;

	SELECT COUNT(*) INTO customer
	FROM Customer C
	WHERE C.SocialSecurityNumber = c_ssn;

	-- If there is atleast one customer 
	IF customer > 0 THEN
		SELECT *
		FROM Orders T 
		WHERE T.SocialSecurityNumber = c_ssn
		ORDER BY DateProcessed DESC
		LIMIT 10;

	END IF;

END $$

CREATE PROCEDURE mostRecentStockAvailByType(IN e_ssn INTEGER,IN stockTy VARCHAR(32))
BEGIN
		SELECT S.StockSymbol,S.StockName,S.StockType,S.NumberOfSharesAvaliable,O.SocialSecurityNumber,O.AccountNumber,O.NumberOfShares,O.SharePrice,O.OrderType
		FROM Orders O
		INNER JOIN StockTable S 
		ON O.StockSymbol = S.StockSymbol
		WHERE O.SocialSecurityNumber = e_ssn AND S.StockType = stockty
		ORDER BY O.OrderTime DESC,O.OrderDate DESC
		LIMIT 1;
END $$

CREATE PROCEDURE getCurrentStockHoldings(IN c_ssn INTEGER)
BEGIN

	DROP TABLE IF EXISTS bought;
	CREATE TEMPORARY TABLE bought(
		StockSymbol VARCHAR(10),
		S INTEGER
		);

	DROP TABLE IF EXISTS sold;
	CREATE TEMPORARY TABLE sold (
		StockSymbol VARCHAR(10),
		S INTEGER
		);

	INSERT INTO bought
		SELECT O.StockSymbol, SUM(O.NumberOfShares)
		FROM Orders O, Transaction T
		WHERE T.TransID = O.OrderID AND O.SocialSecurityNumber = c_ssn AND O.OrderType = 'buy'
		GROUP BY O.StockSymbol;

	INSERT INTO sold
		SELECT O.StockSymbol, SUM(O.NumberOfShares)
		FROM Orders O, Transaction T
		WHERE T.TransID = O.OrderID AND O.SocialSecurityNumber = c_ssn AND O.OrderType = 'sell'
		GROUP BY O.StockSymbol;


	-- IF ( EXISTS(SELECT 1 FROM bought))  THEN 
		IF EXISTS (SELECT 1 FROM sold) THEN
			SELECT DISTINCT O.StockSymbol, bought.S - sold.S AS TotalShares, O.AccountNumber
			FROM Orders O,bought
			INNER JOIN sold
			ON bought.StockSymbol = sold.StockSymbol 
			WHERE O.StockSymbol = bought.StockSymbol;
		ELSE 
			SELECT DISTINCT O.StockSymbol, bought.S AS TotalShares, O.AccountNumber
			FROM Orders O
			INNER JOIN bought 
			ON bought.StockSymbol = O.StockSymbol;
		END IF;

END $$


CREATE PROCEDURE getStocksByKeyword(IN keyword VARCHAR(50), IN c_ssn INTEGER)
BEGIN

	SELECT s.StockName, o.*
	FROM StockTable s
	INNER JOIN Orders o 
	ON o.StockSymbol = s.StockSymbol
	WHERE s.StockName LIKE CONCAT("%", keyword, "%") AND o.SocialSecurityNumber=c_ssn;
END $$

	CREATE PROCEDURE getStockHistory(IN pastDate DATE, IN ss VARCHAR(10))
BEGIN
	SELECT s.SharePrice, s.StockDate
	FROM StockHistory s
	WHERE (s.StockDate <= CURDATE() 
	AND s.StockDate >= pastDate)
	AND s.StockSymbol = ss;
END $$

CREATE PROCEDURE getConditionalOrderHistory(IN o_id INTEGER)
BEGIN	
	DECLARE ss VARCHAR(10);
	DECLARE tDate DATE;
	
	call queryOrderDate(o_id);
	
	SELECT o.StockSymbol INTO ss
	FROM Orders o
	WHERE o.OrderID = o_id;
	
	SELECT t.DateProcessed INTO tDate
	FROM Transaction t
	WHERE t.TransID = o_id;
	
	IF(tDate IS NULL) THEN 
		SELECT s.SharePrice, s.StockDate
		FROM StockHistory s
		WHERE (s.StockDate <= CURDATE() 
		AND s.StockDate >= @oDate)
		AND s.StockSymbol = ss;
	ELSE
		SELECT s.SharePrice, s.StockDate
		FROM StockHistory s
		WHERE (s.StockDate <= tDate 
		AND s.StockDate >= @oDate)
		AND s.StockSymbol = ss;
	END IF;
END $$

DELIMITER ;

-- CREATE VIEW CapitaBay.ShowStockHistory(StockSymbol, SharePrice, StockName, StockType)
-- 	AS SELECT ST.StockSymbol, S.SharePrice, ST.StockName, ST.StockType
-- 	From  StockHistory S, StockTable ST
-- 	WHERE ST.StockSymbol. = S.StockSymbol


-- CREATE VIEW CapitaBay.ShowCurrentHoldings (AccountNumber, StockSymbol) AS		 
-- SELECT S.AccountNumber, S.StockSymbol
-- FROM Customer.C , StockPortfolio S
-- WHERE C.AccountNumber = S.AccountNumber;
	

-- CREATE VIEW CapitaBay.MakeEmailList (FirstName, LastName, Email) AS
--  SELECT C.FirstName, C.LastName, C.Email
-- From Customer C;
