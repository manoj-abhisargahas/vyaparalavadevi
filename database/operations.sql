INSERT INTO `vyaparalavadevi_schema`.`debts` (`auto_incr_for_same_d_n`, `date`, `debts_taker_or_giver_name`, `rupees`, `interest_rate`, `interest_period_type`, `interest_period_type_count`, `interest_type`, `debt_type_and_status`) 
VALUES (
	(SELECT * FROM 
		(SELECT IFNULL(max(auto_incr_for_same_d_n), 0)+1  
			from `vyaparalavadevi_schema`.`debts`  
			where debts_taker_or_giver_name='సుధాకర్' and date=current_date()) 
	DUMP), 
	current_date(),  'సుధాకర్',  '10000.00',  '2.00',  'M',  '1',  'S',  'T' 
);