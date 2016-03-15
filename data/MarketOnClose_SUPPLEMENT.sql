-- CREATE PROCEDURE addMarketOnClose(IN m_ot VARCHAR(32))
-- BEGIN
-- 	INSERT INTO CAPITABAY.MarketOnClose(OrderID,OrderType)
--   	VALUES(m_oid,m_ot);
-- End ^_^

call addMarketOnClose(222222222, 10, '01:10:10',123456789,1,'IBM','2016-02-29','buy');


