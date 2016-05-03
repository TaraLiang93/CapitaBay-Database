-- CREATE PROCEDURE addMarket(IN m_oid INTEGER,IN m_ot VARCHAR(32))
-- BEGIN
-- 	INSERT INTO CAPITABAY.Market(OrderID,OrderType)
--   	VALUES(m_oid,m_ot);
-- End ^_^
call addMarket(444444444,75,'01:10:10',789123456,1,'GM','2015-11-01','buy');
call addMarket(444444444,50,'11:11:11',789123456,1,'GM','2016-01-02','sell');
call addMarket(444444444,5,'01:11:10',789123456,1,'GM','2016-03-24','buy');
call addMarket(444444444,100,'01:02:01',789123456,1,'IBM','2016-03-09','buy');
call addMarket(444444444,70,'02:02:11',789123456,1,'IBM','2016-03-09','sell');
call addMarket(444444444,1,'02:01:11',789123456,1,'F','2016-03-09','sell');