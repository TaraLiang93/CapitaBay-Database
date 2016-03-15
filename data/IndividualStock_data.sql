-- addIndividualStock(IN is_sp FLOAT,IN is_ss VARCHAR(10),IN is_sd TIMESTAMP,IN is_nosa INTEGER)


-- WE DON"T KNOW THE times for the stocks, DATE: YYYY-MM-DD HH:MI:SS
call addIndividualStock(34.23,'GM','1970-01-01', '12:45:00',1000);
call addIndividualStock(91.41,'IBM','1988-01-01', '11:00:55',500);
call addIndividualStock(9.0,'F','2016-01-01', '10:45:12',750);
