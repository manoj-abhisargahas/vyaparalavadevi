/* SELECT TODAY CREDITS: */
/* ===================== */ (
/* own money: */
SELECT date, description, rupees 
FROM vyaparalavadevi_schema.daily_credits where date=current_date();

/* debts taken: */
SELECT date, debts_taker_or_giver_name as debt_giver_name, rupees 
FROM vyaparalavadevi_schema.debts 
where debt_type_and_status="T" and date=currnet_date();

/* interests paid for given debts: */
SELECT paid_date as date, name as debt_taker_name, rupees 
FROM vyaparalavadevi_schema.debts_interest_payments 
where paid_date=current_date() and debt_type_and_status="G";

/* gold taken from business men -
   converted to money with today gold_rate: */
SELECT date, business_man_name, truncate((truncate(metal_purity_percentage/100, 2) * metal_weight * 5000), 2) as rupees 
FROM vyaparalavadevi_schema.transactions_with_business_men 
WHERE date=current_date() and metal_name="GLD" and transaction_type="T";
)

/* SELECT TODAY DEBITS: */
/* ==================== */ (
/* own money: */
SELECT date, description, rupees 
FROM vyaparalavadevi_schema.daily_debits 
where date=current_date();

/* debts given: */
SELECT date, debts_taker_or_giver_name as debt_taker_name, rupees 
FROM vyaparalavadevi_schema.debts 
where debt_type_and_status="G" and date=currnet_date();

/* interests paid for taken debts: */
SELECT paid_date as date, name as debt_taker_name, rupees 
FROM vyaparalavadevi_schema.debts_interest_payments 
where paid_date=current_date() and debt_type_and_status="T";

/* gold given to business men -
   converted to money with today gold_rate: */
SELECT date, business_man_name, truncate((truncate(metal_purity_percentage/100, 2) * metal_weight * 5000), 2) as rupees 
FROM vyaparalavadevi_schema.transactions_with_business_men 
WHERE date=current_date() and metal_name="GLD" and transaction_type="G";

/* money spent for ornaments making */
SELECT date_given_for_work as date, worker_name, metal_cost 
FROM vyaparalavadevi_schema.ornaments_making_cost_info 
where date=current_date();
)