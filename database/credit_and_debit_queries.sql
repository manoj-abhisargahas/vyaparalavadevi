/* SELECT TODAY CREDITS: */
/* ===================== */ (
/* own money: */
SELECT date, description, rupees 
FROM vyaparalavadevi_schema.daily_credits where date=CURRENT_DATE();

/* debts taken: */
SELECT date, debts_taker_or_giver_name AS debt_giver_name, rupees 
FROM vyaparalavadevi_schema.debts 
where debt_type_AND_status="T" AND date=CURRENT_DATE();

/* interests paid for given debts: */
SELECT paid_date AS date, name AS debt_taker_name, rupees 
FROM vyaparalavadevi_schema.debts_interest_payments 
where paid_date=CURRENT_DATE() AND debt_type_AND_status="G";

/* gold taken from business men -
   converted to money with today gold_rate: */
WITH mt AS (
SELECT mt.metal_purity_percentage 
FROM vyaparalavadevi_schema.metal_types mt 
WHERE mt.metal_type="GLD-24k"
)
SELECT twbm.date, twbm.business_man_name
twbm.metal_weight AS rupees 
FROM vyaparalavadevi_schema.transactions_with_business_men twbm, mt
WHERE twbm.date=CURRENT_DATE() AND twbm.transaction_type="T";

/* SELECT TODAY DEBITS: */
/* ==================== */ (
/* own money: */
SELECT date, description, rupees 
FROM vyaparalavadevi_schema.daily_debits 
where date=CURRENT_DATE();

/* debts given: */
SELECT date, debts_taker_or_giver_name AS debt_taker_name, rupees 
FROM vyaparalavadevi_schema.debts 
where debt_type_AND_status="G" AND date=CURRENT_DATE();

/* interests paid for taken debts: */
SELECT paid_date AS date, name AS debt_taker_name, rupees 
FROM vyaparalavadevi_schema.debts_interest_payments 
where paid_date=CURRENT_DATE() AND debt_type_AND_status="T";

/* gold given to business men -
   converted to money with today gold_rate: */
WITH mt AS (
SELECT mt.metal_purity_percentage 
FROM vyaparalavadevi_schema.metal_types mt 
WHERE mt.metal_type="GLD-24k"
)
SELECT twbm.date, twbm.business_man_name,
twbm.metal_weight AS rupees 
FROM vyaparalavadevi_schema.transactions_with_business_men twbm, mt
WHERE twbm.date=CURRENT_DATE() AND twbm.transaction_type="G";

/* money spent for ornaments making */
SELECT date_given_for_work AS date, worker_name, metal_cost 
FROM vyaparalavadevi_schema.ornaments_making_cost_info 
where date=CURRENT_DATE();
)