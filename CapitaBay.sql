/*******************************************************************************
* CSE 305: Spring 2016: Online Stock Exchange
* Team: Capita Bay
* Members: Patrick Sullivan, Hui Liang
*******************************************************************************/
drop database if exists CapitaBay;
create database CapitaBay;
use CapitaBay;

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
CreditCardNumber 	INT			NOT NULL,
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
AccountNumber 	CHAR(12)		NOT NULL,
AccountCreateDate	DATE			NOT NULL,
PRIMARY KEY(AccountNumber),
FOREIGN KEY(SocialSecurityNumber) REFERENCES   
Customer(SocialSecurityNumber)
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
	StockSymbol			VARCHAR(32),
	Stockdate				TIMESTAMP,
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
NumberOfShares	 INTEGER,
PricePerShare	 FLOAT,
Percentage		 FLOAT,
Time 			TIMESTAMP,
OrderID			INTEGER,
EmployeeID		INTEGER		NOT NULL,
AccountNumber	CHAR(12)		NOT NULL,
StockSymbol		VARCHAR(10)		NOT NULL,
Orderdate		DATE	NOT NULL,
PRIMARY KEY(OrderID),
FOREIGN KEY(AccountNumber) REFERENCES StockAccount(AccountNumber)
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
Market: information market order *******************************************************************************/
CREATE TABLE Market (
	OrderID 		INTEGER,
OrderType		VARCHAR(32),
PRIMARY KEY(OrderID),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
ON DELETE NO ACTION
ON UPDATE CASCADE
	
);
/*******************************************************************************  
MarketOnClose: information Market on Close order *******************************************************************************/
CREATE TABLE MarketOnClose (
	OrderID 		INTEGER,
OrderType		VARCHAR(32),
PRIMARY KEY(OrderID),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
ON DELETE NO ACTION
ON UPDATE CASCADE
	
);
/*******************************************************************************  
TrailingStop: information Trailing Stop order *******************************************************************************/
CREATE TABLE TrailingStop (
	OrderID 		INTEGER,
OrderType		VARCHAR(32),
Percentage		FLOAT,
PRIMARY KEY(OrderID),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
ON DELETE NO ACTION
ON UPDATE CASCADE
	
);
/*******************************************************************************  
Hidden Stop: information hidden stop order *******************************************************************************/
CREATE TABLE HiddenStop (
	OrderID 		INTEGER,
PricePerShare		FLOAT,
OrderType		VARCHAR(32),
PRIMARY KEY(OrderID),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
ON DELETE NO ACTION
ON UPDATE CASCADE
	
);

-- CREATE ASSERTION PositiveOrderPrice
-- CHECK(NOT EXIST(
-- SELECT * FROM Order O
-- WHERE O.Fee < 0)
-- ); 


/*******************************************************************************  
Stock Portfolio: information relating to a Customer’s stock holdings 
*******************************************************************************/
CREATE TABLE StockPortfolio (
TotalSharesOwned	INTEGER,
OrderID		INTEGER,
AccountNumber	CHAR(12),
StockSymbol		VARCHAR(10),
PRIMARY KEY(AccountNumber,StockSymbol),
FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
FOREIGN KEY(AccountNumber) REFERENCES StockAccount(AccountNumber)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
FOREIGN KEY(StockSymbol) REFERENCES StockTable(StockSymbol)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
);