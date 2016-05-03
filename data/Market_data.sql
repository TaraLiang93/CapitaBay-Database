-- CREATE PROCEDURE addMarket(IN m_oid INTEGER,IN m_ot VARCHAR(32))
-- BEGIN
-- 	INSERT INTO CAPITABAY.Market(OrderID,OrderType)
--   	VALUES(m_oid,m_ot);
-- End ^_^
call addMarket(444444444,10,'01:10:10',789123456,1,'GM','2016-03-09','buy');
call addMarket(222222222,10,'01:10:15',789123456,1,'IBM','2016-02-09','buy');