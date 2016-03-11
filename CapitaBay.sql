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
Person: represents a user who will access our database  *******************************************************************************/
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
Employee: represents a user who will facilitate the buying and selling of stocks  *******************************************************************************/
CREATE TABLE Employee (
SocialSecurityNumber	 INTEGER,
Position 		VARCHAR(12) 		NOT NULL,
StartDate 		DATE			NOT NULL,
HourlyRate 		FLOAT			NOT NULL,
EmployeeID 		INTEGER,
PRIMARY KEY(EmployeeID),
UNIQUE(SocialSecurityNumber),
FOREIGN KEY(SocialSecurityNumber) REFERENCES Person(SocialSecurityNumber)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
);

-- -- CREATE DOMAIN POSITION  VARCHAR(12)
-- -- 	CHECK ( VALUE IN ( “CustomerRep”, “Manager” ) )

/*******************************************************************************  
Customer: represents a user who will be buying and selling stocks  *******************************************************************************/
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
	PRIMARY KEY(StockSymbol)
);

/*********************************************************************************
Individual Stock: represents a stock price and share number at a certain period of time.
*********************************************************************************/
CREATE TABLE IndividualStock (
	SharePrice			FLOAT,
	StockSymbol			VARCHAR(10),
	Stockdate				TIME,
	NumberOfSharesAvaliable	INTEGER,
	PRIMARY KEY(StockSymbol,StockDate),
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
Time 			TIME,
OrderID			INTEGER,
EmployeeID		INTEGER		NOT NULL,
AccountNumber	INTEGER,
StockSymbol		VARCHAR(10)		NOT NULL,
Orderdate		DATE	NOT NULL,
PRIMARY KEY(OrderID),
FOREIGN KEY(SocialSecurityNumber,AccountNumber) REFERENCES StockAccount(SocialSecurityNumber,AccountNumber)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
FOREIGN KEY(EmployeeID) REFERENCES Employee(EmployeeID)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
FOREIGN KEY(StockSymbol) REFERENCES StockTable(StockSymbol)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
-- FOREIGN KEY(Orderdate) REFERENCES IndividualStock(Stockdate)
-- 	ON DELETE NO ACTION
-- 	ON UPDATE CASCADE
);	

/*******************************************************************************  
Market: information market order 
*******************************************************************************/
CREATE TABLE Market (
OrderID 		INTEGER,
OrderType		VARCHAR(32),
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
OrderType		VARCHAR(32),
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
OrderType		VARCHAR(32),
Percentage		FLOAT,
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
OrderType		VARCHAR(32),
PRIMARY KEY(OrderID),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
ON DELETE NO ACTION
ON UPDATE CASCADE
	
);

/*******************************************************************************
Transaction: information when a order is processed and carried out
*******************************************************************************/
CREATE TABLE Transaction(
TransID		INTEGER,
OrderID		INTEGER,
EmployeeID INTEGER,
SocialSecurityNumber INTEGER,
AccountNumber INTEGER,
StockSymbol		VARCHAR(10),
Fee			FLOAT NOT NULL,
DateProcessed 	TIME,
PricePerShare	FLOAT CHECK(PricePerShare>=0),
PRIMARY KEY(TransID),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID) ON DELETE NO ACTION ON UPDATE CASCADE,
FOREIGN KEY(EmployeeID) REFERENCES Employee(EmployeeID) ON DELETE NO ACTION ON UPDATE CASCADE,
FOREIGN KEY(SocialSecurityNumber,AccountNumber) REFERENCES StockAccount(SocialSecurityNumber,AccountNumber)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
FOREIGN KEY(StockSymbol) REFERENCES StockTable(StockSymbol) ON DELETE NO ACTION ON UPDATE CASCADE

);




DELIMITER ^_^


/*Addss the locations*/
CREATE PROCEDURE addLocation(IN lcl_zipCode INTEGER,IN lcl_city VARCHAR(32),lcl_state VARCHAR(20))
BEGIN
	INSERT INTO CAPITABAY.Location(ZipCode, City, State)
  	VALUES(lcl_zipCode,lcl_city,lcl_state);
End ^_^


CREATE PROCEDURE addPerson(IN p_fname VARCHAR(32),IN p_lname VARCHAR(32),IN p_addr VARCHAR(128),IN p_tele CHAR(13), IN p_zipcode INTEGER,IN p_ssn INTEGER)
BEGIN
	INSERT INTO CAPITABAY.Person(FirstName, LastName, Address,Telephone, ZipCode, SocialSecurityNumber)
  	VALUES(p_fname,p_lname,p_addr,p_tele,p_zipcode,p_ssn);
End ^_^


CREATE PROCEDURE addEmployee(IN e_ssn INTEGER,IN e_pos VARCHAR(12),IN e_date DATE,IN e_hrRate FLOAT,IN e_id INTEGER)
BEGIN
	INSERT INTO CAPITABAY.Employee(SocialSecurityNumber,Position,StartDate,HourlyRate,EmployeeID)
  	VALUES(e_ssn,e_pos,e_date,e_hrRate,e_id);
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


CREATE PROCEDURE addStockTable(IN st_ss VARCHAR(10),IN st_st VARCHAR(32),IN st_sn VARCHAR(32))
BEGIN
	INSERT INTO CAPITABAY.StockTable(StockSymbol,StockType,StockName)
  	VALUES(st_ss,st_st,st_sn);
End ^_^


CREATE PROCEDURE addIndividualStock(IN is_sp FLOAT,IN is_ss VARCHAR(10),IN is_sd TIME,IN is_nosa INTEGER)
BEGIN
	INSERT INTO CAPITABAY.IndividualStock(SharePrice,StockSymbol,Stockdate,NumberOfSharesAvaliable)
  	VALUES(is_sp,is_ss,is_sd,is_nosa);
End ^_^


CREATE PROCEDURE addOrder(IN o_nos INTEGER, IN o_time TIME, IN o_oid INTEGER,IN o_eid INTEGER
	,IN o_acctNum CHAR(12),IN o_ss VARCHAR(10),IN o_od DATE, IN o_ssn INTEGER)
BEGIN
	INSERT INTO CAPITABAY.Orders(NumberOfShares,Time,OrderID,EmployeeID ,AccountNumber,StockSymbol,Orderdate,SocialSecurityNumber )
  	VALUES(o_nos,o_time,o_oid,o_eid,o_acctNum,o_ss,o_od, o_ssn;
End ^_^

CREATE PROCEDURE addMarket(IN m_oid INTEGER,IN m_ot VARCHAR(32))
BEGIN
	INSERT INTO CAPITABAY.Market(OrderID,OrderType)
  	VALUES(m_oid,m_ot);
End ^_^

CREATE PROCEDURE addMarketOnClose(IN m_oid INTEGER,IN m_ot VARCHAR(32))
BEGIN
	INSERT INTO CAPITABAY.MarketOnClose(OrderID,OrderType)
  	VALUES(m_oid,m_ot);
End ^_^

CREATE PROCEDURE addTrailingStop(IN m_oid INTEGER,IN m_ot VARCHAR(32),IN  m_percent FLOAT)
BEGIN
	INSERT INTO CAPITABAY.TrailingStop(OrderID,OrderType,Percentage)
  	VALUES(m_oid,m_ot,m_percent);
End ^_^

CREATE PROCEDURE addHiddenStop(IN m_oid INTEGER,IN  m_pps FLOAT,IN m_ot VARCHAR(32))
BEGIN
	INSERT INTO CAPITABAY.HiddenStop(OrderID,PricePerShare,PricePerShare)
  	VALUES(m_oid,m_pps,m_ot);
End ^_^

CREATE PROCEDURE addTransaction(IN t_tid INTEGER, IN t_oid INTEGER, IN t_eid INTEGER, IN t_ssn INTEGER, IN t_accNum INTEGER,
	IN t_ss VARCHAR(10), IN t_fee FLOAT, IN t_dp TIME, IN t_pps FLOAT)
BEGIN 
	INSERT INTO CAPITABAY.Transaction(TransID, OrderID, EmployeeID, SocialSecurityNumber, AccountNumber, StockSymbol, Fee, DateProcessed,PricePerShare)
	VALUES(t_tid, t_oid, t_eid, t_ssn, t_accNum, t_ss, t_fee, t_dp,t_pps);
END ^_^

DELIMITER ;

-- CREATE VIEW CapitaBay.ShowStockHistory(StockSymbol, SharePrice, StockName, StockType)
-- 	AS SELECT ST.StockSymbol, S.SharePrice, ST.StockName, ST.StockType
-- 	From  IndividualStock S, StockTable ST
-- 	WHERE ST.StockSymbol. = S.StockSymbol


-- CREATE VIEW CapitaBay.ShowCurrentHoldings (AccountNumber, StockSymbol) AS		 
-- SELECT S.AccountNumber, S.StockSymbol
-- FROM Customer.C , StockPortfolio S
-- WHERE C.AccountNumber = S.AccountNumber;
	

-- CREATE VIEW CapitaBay.MakeEmailList (FirstName, LastName, Email) AS
--  SELECT C.FirstName, C.LastName, C.Email
-- From Customer C;

