/* to sell to business man list: */
SELECT name FROM vyaparalavadevi_schema.contacts WHERE identity REGEXP "^(.*\\_)?TBM(\\_.*)?$" = 1;

/* maked and purchased ornaments selled list with specific business man: */
SELECT business_man_name, date_for_selled, ornaments_metal_type, ornaments_sold_weight, ornaments_sold_percentage, 
SUBSTRING_INDEX(ornaments_metal_type, "-", 1) AS pure_metal_type, 
ROUND(ornaments_sold_weight * ROUND(ornaments_sold_percentage/100, 3), 3) AS pure_metal_weight
FROM(
(SELECT mosi.*, omi.ornaments_metal_type
 FROM vyaparalavadevi_schema.maked_ornaments_selled_info mosi, vyaparalavadevi_schema.ornaments_making_info omi
 WHERE mosi.auto_incr_for_same_d_n = omi.auto_incr_for_same_d_n AND mosi.date = omi.date
 AND mosi.worker_name = omi.worker_name)
UNION
(SELECT posi.*, opi.ornaments_metal_type
 FROM vyaparalavadevi_schema.purchased_ornaments_selled_info posi, vyaparalavadevi_schema.ornaments_purchased_info opi
 WHERE posi.auto_incr_for_same_d_n = opi.auto_incr_for_same_d_n AND posi.date = opi.date
 AND posi.identified_business_man_name = opi.business_man_name)
) AS dump_table
WHERE business_man_name = "మహేష్"
ORDER BY date_for_selled;

/* metal transactions taken from specific business man: */
SELECT twbm.transaction_type, twbm.date, twbm.pure_metal_type, twbm.metal_weight, twbm.description
FROM vyaparalavadevi_schema.transactions_with_business_men twbm, vyaparalavadevi_schema.metal_types mt
WHERE twbm.business_man_name = "మహేష్" AND twbm.transaction_type = "T"
AND mt.metal_type = twbm.pure_metal_type
ORDER BY date;

/* REMAINING METAL WEIGHT CALCULATION; */
/* ================================== */ (
WITH 
bn AS ( 
SELECT distinct business_man_name 
FROM vyaparalavadevi_schema.transactions_with_business_men 
WHERE business_man_name = "మహేష్" 
), 
t_s_pm_wt AS ( 
SELECT SUBSTRING_INDEX(osi.ornaments_metal_type, "-", 1) AS ornaments_pure_metal_type, 
SUM(ROUND(osi.ornaments_sold_weight * ROUND(osi.ornaments_sold_percentage/100, 3), 3)) AS total_sold_pure_metal_weight
FROM(
(SELECT mosi.*, omi.ornaments_metal_type
 FROM vyaparalavadevi_schema.maked_ornaments_selled_info mosi, vyaparalavadevi_schema.ornaments_making_info omi
 WHERE mosi.auto_incr_for_same_d_n = omi.auto_incr_for_same_d_n AND mosi.date = omi.date
 AND mosi.worker_name = omi.worker_name)
UNION
(SELECT posi.*, opi.ornaments_metal_type
 FROM vyaparalavadevi_schema.purchased_ornaments_selled_info posi, vyaparalavadevi_schema.ornaments_purchased_info opi
 WHERE posi.auto_incr_for_same_d_n = opi.auto_incr_for_same_d_n AND posi.date = opi.date
 AND posi.identified_business_man_name = opi.business_man_name)
) AS osi, bn
WHERE osi.business_man_name = bn.business_man_name
GROUP BY ornaments_metal_type
), 
t_pm_wt_gbbm AS (
SELECT SUBSTRING_INDEX(twbm.pure_metal_type, "-", 1) AS pure_metal_type, 
SUM(twbm.metal_weight) AS total_pure_metal_weight_given_by_business_man
FROM vyaparalavadevi_schema.transactions_with_business_men twbm, bn
WHERE twbm.business_man_name = bn.business_man_name AND transaction_type = "T" 
GROUP BY pure_metal_type
) 

SELECT t_s_pm_wt.ornaments_pure_metal_type, t_s_pm_wt.total_sold_pure_metal_weight, 
IFNULL(t_pm_wt_gbbm.total_pure_metal_weight_given_by_business_man, 0) AS total_pure_metal_weight_given_by_business_man, 
(t_s_pm_wt.total_sold_pure_metal_weight - IFNULL(t_pm_wt_gbbm.total_pure_metal_weight_given_by_business_man, 0)) AS remaining_metal_weight_to_receive
FROM t_s_pm_wt LEFT JOIN t_pm_wt_gbbm ON t_s_pm_wt.ornaments_pure_metal_type = t_pm_wt_gbbm.pure_metal_type
UNION ALL
SELECT t_pm_wt_gbbm.pure_metal_type, IFNULL(t_s_pm_wt.total_sold_pure_metal_weight, 0) AS total_sold_pure_metal_weight, 
t_pm_wt_gbbm.total_pure_metal_weight_given_by_business_man, 
(IFNULL(t_s_pm_wt.total_sold_pure_metal_weight, 0) - t_pm_wt_gbbm.total_pure_metal_weight_given_by_business_man) AS remaining_metal_weight_to_receive
FROM t_s_pm_wt RIGHT JOIN t_pm_wt_gbbm ON t_s_pm_wt.ornaments_pure_metal_type = t_pm_wt_gbbm.pure_metal_type 
WHERE t_s_pm_wt.ornaments_pure_metal_type IS NULL