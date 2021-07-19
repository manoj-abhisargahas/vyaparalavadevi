/* TAKEN DEBTS FROM OTHERS: */
/* ======================= */ (
/* taken debts info: */
SELECT *, ROUND((ROUND(rupees/100, 2) * interest_rate), 2) AS interest 
FROM vyaparalavadevi_schema.debts 
WHERE debt_type_AND_status="T" AND interest_type="s";

/* paid interests by us for specific taken_debt: */
SELECT paid_date, rupees 
FROM vyaparalavadevi_schema.debts_interest_payments 
WHERE auto_incr_for_same_d_n=1 AND date="2021-06-10" AND name="సుధాకర్" AND debt_type_AND_status="T";

/* calculate presently remaining debt interest to pay: */
)

/* GIVEN DEBTS BY US: */
/* ================== */ (
/* given debts info: */
SELECT *, ROUND((ROUND(rupees/100, 2) * interest_rate), 2) AS interest 
FROM vyaparalavadevi_schema.debts 
WHERE debt_type_AND_status="T" AND interest_type="s";

/* paid interests by debt_takers for specific given_debt: */
SELECT paid_date, rupees 
FROM vyaparalavadevi_schema.debts_interest_payments 
WHERE auto_incr_for_same_d_n=1 AND date="2021-06-10" AND name="మణి" AND debt_type_AND_status="G";

/* calculate presently remaining debt interest to receive: */
)