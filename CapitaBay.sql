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
ZipCode	INTEGER,
SocialSecurityNumber	 INTEGER,
PRIMARY KEY(SocialSecurityNumber),
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
	ON DELETE NO ACTION
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
	UNIQUE KEY(StockDate),
	UNIQUE KEY(StockTime)
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
	PRIMARY KEY(StockSymbol,StockDate,StockTime),
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




DELIMITER ^_^
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
END ^_^

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
END ^_^


CREATE PROCEDURE addLocation(IN lcl_zipCode INTEGER,IN lcl_city VARCHAR(32),lcl_state VARCHAR(20))
BEGIN
	INSERT INTO CAPITABAY.Location(ZipCode, City, State)
  	VALUES(lcl_zipCode,lcl_city,lcl_state);
End ^_^


CREATE PROCEDURE addPerson(IN p_fname VARCHAR(32),IN p_lname VARCHAR(32),IN p_addr VARCHAR(128),IN p_tele CHAR(13),
 IN p_zipcode INTEGER,IN p_ssn INTEGER)
BEGIN
	INSERT INTO CAPITABAY.Person(FirstName, LastName, Address,Telephone, ZipCode, SocialSecurityNumber)
  	VALUES(p_fname,p_lname,p_addr,p_tele,p_zipcode,p_ssn);
End ^_^


CREATE PROCEDURE addEmployee(IN e_ssn INTEGER,IN e_pos VARCHAR(12),IN e_date DATE,IN e_hrRate FLOAT)
BEGIN
	INSERT INTO CAPITABAY.Employee(SocialSecurityNumber,Position,StartDate,HourlyRate)
  	VALUES(e_ssn,e_pos,e_date,e_hrRate);
End ^_^
	
CREATE PROCEDURE addCustomer(IN c_ssn INTEGER,IN c_rate FLOAT,IN c_ccn CHAR(20),IN c_email VARCHAR(50))
BEGIN
	INSERT INTO CAPITABAY.Customer(SocialSecurityNumber,Rating,CreditCardNumber,Email)
  	VALUES(c_ssn,c_rate ,c_ccn,c_email);
End ^_^


CREATE PROCEDURE addStockAccount(IN sa_ssn INTEGER,IN sa_acctNum CHAR(12),IN sa_acctDate DATE)
BEGIN
	INSERT INTO CAPITABAY.StockAccount(SocialSecurityNumber,AccountNumber,AccountCreateDate)
  	VALUES(sa_ssn,sa_acctNum,sa_acctDate );
End ^_^


CREATE PROCEDURE addStockTable(IN st_ss VARCHAR(10),IN st_st VARCHAR(32),IN st_sn VARCHAR(32),
	IN price FLOAT, IN s_date DATE, IN s_time TIME, IN NumberOfShares INTEGER)
BEGIN
	INSERT INTO CAPITABAY.StockTable(StockSymbol,StockType,StockName, SharePrice,
		 StockDate, StockTime, NumberOfSharesAvaliable)
  	VALUES(st_ss,st_st,st_sn, price, s_date, s_time, NumberOfShares);
	call addStockHistory(price, st_ss, s_date, s_time, NumberOfShares);
End ^_^


CREATE PROCEDURE addStockHistory(IN is_sp FLOAT,IN is_ss VARCHAR(10),IN is_dat DATE, IN is_time TIME,IN is_nosa INTEGER)
BEGIN
	INSERT INTO CAPITABAY.StockHistory(SharePrice,StockSymbol,StockDate, StockTime, NumberOfSharesAvaliable)
  	VALUES(is_sp,is_ss,is_dat, is_time,is_nosa);
End ^_^

CREATE PROCEDURE addOrder(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN price FLOAT, IN o_type VARCHAR(32))
BEGIN 

	INSERT INTO CAPITABAY.Orders(SocialSecurityNumber, NumberOfShares, 
		OrderTime, EmployeeSSN, AccountNumber, StockSymbol, OrderDate, SharePrice, OrderType)
	VALUES(ssn, nos, o_time, e_ssn, an, ss, dat, price, o_type);
END ^_^



CREATE PROCEDURE addMarket(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN m_ot VARCHAR(32) )
BEGIN
  	call queryCurrentPricePerShare(ss);
	call addOrder(ssn, nos, o_time, e_ssn, an, ss, dat, @price, 'Market');
	call queryOrderId(ssn, o_time, e_ssn, an, ss, dat);
  	call CalcFee(@price, nos);
  	call addTransaction(@o_id, e_ssn, ssn, an, ss, @fee, dat, o_time, @price, m_ot);
End ^_^

CREATE PROCEDURE addMarketOnClose(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN m_ot VARCHAR(32))
BEGIN
  	call queryCurrentPricePerShare(ss);
	call addOrder(ssn, nos, o_time, e_ssn, an, ss, dat, @price, 'MarketOnClose');
	call queryOrderId(ssn, o_time, e_ssn, an, ss, dat);
  	call CalcFee(@price, nos);
  	call addTransaction(@o_id, e_ssn, ssn, an, ss, @fee, dat, o_time, @price, m_ot);
End ^_^

CREATE PROCEDURE addTrailingStop(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN m_ot VARCHAR(32),IN  m_percent FLOAT)
BEGIN
	call addOrder(ssn, nos, o_time, e_ssn, an, ss, dat, NULL, 'TrailingStop');
	call queryOrderId(ssn, o_time, e_ssn, an, ss, dat);
End ^_^

CREATE PROCEDURE addHiddenStop(IN ssn INTEGER, IN nos INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE, IN  m_pps FLOAT,IN m_ot VARCHAR(32))
BEGIN
	call addOrder(ssn, nos, o_time, e_ssn, an, ss, dat, NULL, 'HiddenStop');
	call queryOrderId(ssn, nos, o_time, e_ssn, an, ss, dat);
End ^_^

/*****************************************************************************  
Supplment QUERIES for inserting
 *****************************************************************************/

CREATE PROCEDURE queryOrderId(IN ssn INTEGER, IN o_time TIME, 
		IN e_ssn INTEGER,IN an INTEGER, IN ss VARCHAR(10), IN dat DATE)
BEGIN 
	SELECT o.OrderID INTO @o_id FROM Orders o WHERE (o.SocialSecurityNumber = ssn AND 
		(o.OrderTime = o_time AND (o.EmployeeSSN = e_ssn AND
		(o.AccountNumber = an AND (o.StockSymbol = ss)))));
END ^_^

CREATE PROCEDURE CalcFee(IN price FLOAT, IN numShare INTEGER)
BEGIN
	SELECT (price * numShare)*0.05 INTO @fee;
END ^_^

CREATE PROCEDURE queryPricePerShare(IN o_time TIME, IN dat DATE)
BEGIN 
	SELECT i.SharePrice INTO @price
	FROM StockHistory i 
	Where i.StockDate < dat AND i.StockTime < o_time 
	ORDER BY i.StockDate DESC LIMIT 1;
END ^_^

CREATE PROCEDURE queryCurrentPricePerShare(IN o_ss VARCHAR(10))
BEGIN 
	SELECT i.SharePrice INTO @price
	FROM StockTable i 
	Where i.StockSymbol = o_ss; 
END ^_^

CREATE PROCEDURE queryNumShareAva(IN stockSym VARCHAR(10))
BEGIN 
	SELECT i.NumberOfSharesAvaliable INTO @numShareAva
	FROM StockTable i
	Where i.StockSymbol = stockSym;
END ^_^

CREATE PROCEDURE queryOrderShares(IN o_id INTEGER)
BEGIN 
	SELECT o.NumberOfShares INTO @oShare
	FROM Orders o
	Where o.OrderID = o_id;
END ^_^

CREATE PROCEDURE queryOrderDate(IN o_id INTEGER)
BEGIN 
	SELECT o.OrderDate INTO @oDate
	FROM Orders o
	Where o.OrderID = o_id;
END ^_^

CREATE PROCEDURE queryOrderTime(IN o_id INTEGER)
BEGIN 
	SELECT o.OrderTime INTO @oTime
	FROM Orders o
	Where o.OrderID = o_id;
END ^_^

CREATE PROCEDURE queryStockType(IN stockSym VARCHAR(10))
BEGIN	
	SELECT DISTINCT s.StockType INTO @st_type
	FROM StockTable s
	WHERE stockSym = s.StockSymbol;
END ^_^

CREATE PROCEDURE queryCustomerStocks(IN c_ssn INTEGER)
BEGIN 
	SELECT o.StockSymbol INTO @oSS
	FROM Orders o
	Where o.SocialSecurityNumber = c_ssn;
END ^_^

/******************************************************************************  
UPDATE QUERIES
 ******************************************************************************/
CREATE PROCEDURE editEmployee(IN e_ssn INTEGER,IN e_pos VARCHAR(12),IN e_date DATE,IN e_hrRate FLOAT)
BEGIN
	UPDATE Employee
	SET Position=e_pos, StartDate=e_date, HourlyRate=e_hrRate
  	WHERE SocialSecurityNumber = e_ssn; 
End ^_^

CREATE PROCEDURE updateStockTablePrice(IN stockSym VARCHAR(10), IN price FLOAT, IN s_date DATE,
	IN s_time TIME)
BEGIN
	UPDATE StockTable
	SET SharePrice = price, StockDate = s_date, StockTime = s_time
	WHERE StockSymbol = stockSym;
	call queryNumShareAva(stockSym);
	call addStockHistory(price, stockSym, s_date, s_time, @numShareAva);
END ^_^

CREATE PROCEDURE updateStockTableNumShare(IN stockSym VARCHAR(10), IN shareAvaliable INTEGER,
	IN s_date DATE, IN s_time TIME)
BEGIN
	UPDATE StockTable
	SET NumberOfSharesAvaliable = shareAvaliable, StockDate = s_date, StockTime = s_time
	WHERE StockSymbol = stockSym;
	call queryCurrentPricePerShare(stockSym);
	call addStockHistory(@price, stockSym, s_date, s_time, shareAvaliable);
END^_^

CREATE PROCEDURE editPerson(IN p_fname VARCHAR(32),IN p_lname VARCHAR(32),IN p_addr VARCHAR(128),IN p_tele CHAR(13), IN p_zipcode INTEGER,IN p_ssn INTEGER)
BEGIN
	UPDATE Customer
	SET FirstName = p_fname, LastName = p_lname, Address = p_addr, Telephone = p_tele, ZipCode = p_zipcode 
	WHERE SocialSecurityNumber = p_ssn;
End ^_^
 
CREATE PROCEDURE editCustomer(IN c_ssn INTEGER,IN c_rate FLOAT,IN c_ccn CHAR(20),IN c_email VARCHAR(50))
BEGIN
	UPDATE Customer
	SET Rating = c_rate, CreditCardNumber = c_ccn, Email = c_email 
	WHERE SocialSecurityNumber = c_ssn;
End ^_^


/******************************************************************************  
DELETE QUERIES 
 ******************************************************************************/
CREATE PROCEDURE deleteEmployee(IN e_ssn INTEGER)
BEGIN
	DELETE FROM Employee
	WHERE SocialSecurityNumber = e_ssn;
End ^_^

CREATE PROCEDURE deleteStockTable(IN stockSym VARCHAR(10))
BEGIN 
	DELETE FROM StockTable
	WHERE StockSymbol = stockSym;
END ^_^





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
		WHERE StockSymbol = is_ss;
	END IF;

END ^_^


CREATE PROCEDURE manageEmployees(IN reqeust VARCHAR(12),IN e_ssn1 INTEGER,IN e_ssn2 INTEGER,IN e_pos VARCHAR(12),IN e_date DATE,IN e_hrRate FLOAT)
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
			call editEmployee(e_ssn2,e_pos,e_date,e_hrRate);
		ELSEIF reqeust = 'DELETE' THEN
			call deleteEmployee(e_ssn2);
		END IF;
	END IF;

END ^_^

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

END ^_^

CREATE PROCEDURE listAllStocks(IN e_ssn INTEGER)
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		SELECT DISTINCT S.StockSymbol, S.StockType,S.StockName, I.SharePrice, I.StockDate,I.NumberOfSharesAvaliable
		FROM StockTable S, StockHistory I
		WHERE S.StockSymbol = I.StockSymbol;
	END IF;

END ^_^

CREATE PROCEDURE listOrders(IN e_ssn INTEGER,IN ssn1 INTEGER,IN ss VARCHAR(10))
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE ) 
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'Manager' THEN
		IF ssn1 <> -1 THEN 
			SELECT *
			FROM Orders
			WHERE SocialSecurityNumber = ssn1;
		ELSEIF ss <> "" THEN
			SELECT * 
			FROM Orders
			WHERE StockSymbol = ss;
		END IF; 
	END IF;

END ^_^


-- recommendation for employees
-- select StockTable.StockType, COUNT(StockTable.StockType) AS NumberOfType FROM StockTable LEFT JOIN Transaction ON StockTable.StockSymbol = Transaction.StockSymbol WHERE Transaction.SocialSecurityNumber = 222222222 GROUP BY StockType ;

/******************************************************************************  
CustomerRep QUERIES
 ******************************************************************************/
CREATE PROCEDURE makeCustomerMailingList(IN e_ssn INTEGER)
BEGIN
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'CustomerRep' THEN
		SELECT C.Email  
		FROM Customer C;
	END IF;
	
	
END ^_^

CREATE PROCEDURE makeStockSuggestionList(IN e_ssn INTEGER, IN c_ssn INTEGER)
BEGIN
	DECLARE currentEmployeePosition VARCHAR(12);

	SELECT E.Position INTO currentEmployeePosition
	FROM Employee E
	WHERE E.SocialSecurityNumber = e_ssn;

	IF currentEmployeePosition = 'CustomerRep' THEN
		call queryCustomerStocks(c_ssn);
		call queryStockType(@oSS);
		SELECT s.StockSymbol
		FROM StockTable s
		WHERE s.StockType = @st_type;
	END IF;
	
	
END ^_^


/******************************************************************************  
Customer QUERIES
 ******************************************************************************/
CREATE PROCEDURE getStockSuggestionList(IN c_ssn INTEGER)
BEGIN
	call queryCustomerStocks(c_ssn);
	call queryStockType(@oSS);
	SELECT s.StockSymbol
	FROM StockTable s
	WHERE s.StockType = @st_type;
END ^_^


CREATE PROCEDURE recentOrderInfo(IN e_ssn INTEGER)
BEGIN
	-- IF(SELECT E.SocialSecurityNumber FROM Employee E WHERE )

	DECLARE customer	 INTEGER;

	SELECT COUNT(*) INTO customer
	FROM Customer C
	WHERE C.SocialSecurityNumber = e_ssn;

	-- If there is atleast one customer 
	IF customer > 0 THEN
		SELECT *
		FROM Orders O 
		WHERE O.SocialSecurityNumber = e_ssn
		ORDER BY OrderTime ASC,OrderDate DESC
		LIMIT 10;

	END IF;

END ^_^

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