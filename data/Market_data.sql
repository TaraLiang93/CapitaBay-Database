-- CREATE PROCEDURE addMarket(IN m_oid INTEGER,IN m_ot VARCHAR(32))
-- BEGIN
-- 	INSERT INTO CAPITABAY.Market(OrderID,OrderType)
--   	VALUES(m_oid,m_ot);
-- End ^_^

call addMarket(1,'buy');