-- CREATE PROCEDURE addTrailingStop(IN m_oid INTEGER,IN m_ot VARCHAR(32),IN  m_percent FLOAT)
-- BEGIN
-- 	INSERT INTO CAPITABAY.TrailingStop(OrderID,OrderType,Percentage)
--   	VALUES(m_oid,m_ot,m_percent);
-- End ^_^


call addTrailingStop(222222222,10,'21:10:15',123456789,1,'IBM','2016-02-29','sell', .10);