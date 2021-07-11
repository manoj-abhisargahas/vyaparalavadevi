/* TAKEN DEBTS FROM OTHERS: */
/* ======================= */ (
/* taken debts info: */
SELECT *, truncate((truncate(rupees/100, 2) * interest_rate), 2) as interest 
FROM vyaparalavadevi_schema.debts 
where debt_type_and_status="T" and interest_type="s";
/* paid interests by us for specific taken_debt: */

SELECT paid_date, rupees 
FROM vyaparalavadevi_schema.debts_interest_payments 
where auto_incr_for_same_d_n=1 and date="2021-06-10" and name="సుధాకర్" and debt_type_and_status="T";
/* calculate presently remaining debt interest to pay: */
)

/* GIVEN DEBTS BY US: */
/* ================== */ (
/* given debts info: */
SELECT *, truncate((truncate(rupees/100, 2) * interest_rate), 2) as interest 
FROM vyaparalavadevi_schema.debts 
where debt_type_and_status="T" and interest_type="s";

/* paid interests by debt_takers for specific given_debt: */
SELECT paid_date, rupees 
FROM vyaparalavadevi_schema.debts_interest_payments 
where auto_incr_for_same_d_n=1 and date="2021-06-10" and name="మణి" and debt_type_and_status="G";
/* calculate presently remaining debt interest to receive: */
)