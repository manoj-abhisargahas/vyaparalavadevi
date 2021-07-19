/* to sell to business man list: */
SELECT name FROM vyaparalavadevi_schema.contacts WHERE identity REGEXP "^(.*\\_)?GBM(\\_.*)?$" = 1;

/* purchased ornaments list with specific business man: */
WITH 
posi AS (SELECT auto_incr_for_same_d_n, date, identified_business_man_name, date_for_selled, 
SUM(ornaments_sold_weight) AS total_ornaments_sold_weight 
FROM vyaparalavadevi_schema.purchased_ornaments_selled_info 
GROUP BY identified_business_man_name, auto_incr_for_same_d_n, date, date_for_selled
)

SELECT opi.business_man_name, posi.date_for_selled, opi.ornaments_metal_type, 
posi.total_ornaments_sold_weight, opi.ornaments_purchased_percentage, 
SUBSTRING_INDEX(opi.ornaments_metal_type, "-", 1) AS ornaments_pure_metal_type, 
ROUND(posi.total_ornaments_sold_weight * ROUND(opi.ornaments_purchased_percentage/100, 3), 3) AS pure_metal_weight 
FROM vyaparalavadevi_schema.ornaments_purchased_info opi, posi
WHERE posi.auto_incr_for_same_d_n = opi.auto_incr_for_same_d_n AND posi.date = opi.date
AND posi.identified_business_man_name = opi.business_man_name AND posi.identified_business_man_name = "మస్తాన్" 
ORDER BY date_for_selled

/* metal transactions given to specific business man: */
SELECT twbm.transaction_type, twbm.date, twbm.pure_metal_type, twbm.metal_weight, twbm.description
FROM vyaparalavadevi_schema.transactions_with_business_men twbm, vyaparalavadevi_schema.metal_types mt
WHERE twbm.business_man_name = "మస్తాన్" AND twbm.transaction_type = "G"
AND mt.metal_type = twbm.pure_metal_type
ORDER BY date;

/* REMAINING METAL WEIGHT CALCULATION FOR SPECIFIC BUSINESS MAN: */
/* ============================================================ */ (
WITH 
bn AS ( 
SELECT distinct business_man_name 
FROM vyaparalavadevi_schema.transactions_with_business_men 
WHERE business_man_name = "మస్తాన్" 
),  
posi AS (SELECT auto_incr_for_same_d_n, date, identified_business_man_name, date_for_selled, 
SUM(ornaments_sold_weight) AS total_ornaments_sold_weight 
FROM vyaparalavadevi_schema.purchased_ornaments_selled_info 
GROUP BY identified_business_man_name, auto_incr_for_same_d_n, date, date_for_selled
),
t_p_pm_wt AS (
SELECT SUBSTRING_INDEX(opi.ornaments_metal_type, "-", 1) AS ornaments_pure_metal_type, 
SUM(ROUND(posi.total_ornaments_sold_weight * ROUND(opi.ornaments_purchased_percentage/100, 3), 3)) AS total_sold_pure_metal_weight 
FROM vyaparalavadevi_schema.ornaments_purchased_info opi, posi
WHERE posi.auto_incr_for_same_d_n = opi.auto_incr_for_same_d_n AND posi.date = opi.date
AND posi.identified_business_man_name = opi.business_man_name AND posi.identified_business_man_name = "మస్తాన్" 
GROUP BY ornaments_pure_metal_type
),
t_pm_wt_gbbm AS (
SELECT SUBSTRING_INDEX(twbm.pure_metal_type, "-", 1) AS pure_metal_type, 
SUM(twbm.metal_weight) AS total_pure_metal_weight_given_to_business_man
FROM vyaparalavadevi_schema.transactions_with_business_men twbm, bn
WHERE twbm.business_man_name = bn.business_man_name AND twbm.transaction_type = "G"
GROUP BY pure_metal_type
) 

SELECT t_p_pm_wt.ornaments_pure_metal_type, t_p_pm_wt.total_sold_pure_metal_weight, 
IFNULL(t_pm_wt_gbbm.total_pure_metal_weight_given_to_business_man, 0) AS total_pure_metal_weight_given_to_business_man, 
(t_p_pm_wt.total_sold_pure_metal_weight - IFNULL(t_pm_wt_gbbm.total_pure_metal_weight_given_to_business_man, 0)) AS remaining_metal_weight_to_give
FROM t_p_pm_wt LEFT JOIN t_pm_wt_gbbm ON t_p_pm_wt.ornaments_pure_metal_type = t_pm_wt_gbbm.pure_metal_type
UNION
SELECT t_pm_wt_gbbm.pure_metal_type, IFNULL(t_p_pm_wt.total_sold_pure_metal_weight, 0), 
t_pm_wt_gbbm.total_pure_metal_weight_given_to_business_man AS total_pure_metal_weight_given_to_business_man, 
(IFNULL(t_p_pm_wt.total_sold_pure_metal_weight, 0) - t_pm_wt_gbbm.total_pure_metal_weight_given_to_business_man) AS remaining_metal_weight_to_give
FROM t_p_pm_wt RIGHT JOIN t_pm_wt_gbbm ON t_p_pm_wt.ornaments_pure_metal_type = t_pm_wt_gbbm.pure_metal_type