-- CREATE PROCEDURE addTrailingStop(IN m_oid INTEGER,IN m_ot VARCHAR(32),IN  m_percent FLOAT)
-- BEGIN
-- 	INSERT INTO CAPITABAY.TrailingStop(OrderID,OrderType,Percentage)
--   	VALUES(m_oid,m_ot,m_percent);
-- End ^_^


call addTrailingStop(2, 'sell', .10);