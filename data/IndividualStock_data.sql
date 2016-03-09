-- addIndividualStock(IN is_sp FLOAT,IN is_ss VARCHAR(10),IN is_sd TIMESTAMP,IN is_nosa INTEGER)


-- WE DON"T KNOW THE times for the stocks
call addIndividualStock(34.23,'GM',CURTIME(),1000);
call addIndividualStock(91.41,'IBM',CURTIME(),500);
call addIndividualStock(9.0,'F',CURTIME(),750);
