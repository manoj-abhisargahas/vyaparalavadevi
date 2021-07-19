/* all purchased ornaments list: */
SELECT * 
FROM vyaparalavadevi_schema.ornaments_purchased_info
ORDER BY date DESC, auto_incr_for_same_d_n DESC;

/* purchased ornaments ready for sale list: */
SELECT DISTINCT opi.*
FROM vyaparalavadevi_schema.ornaments_purchased_info AS opi, vyaparalavadevi_schema.purchased_ornaments_selled_info AS posi
WHERE NOT (opi.auto_incr_for_same_d_n = posi.auto_incr_for_same_d_n AND opi.date = posi.date AND opi.business_man_name = posi.identified_business_man_name) 
ORDER BY opi.date DESC, opi.auto_incr_for_same_d_n DESC;

/* purchased ornaments solded list: */
SELECT DISTINCT opi.*
FROM vyaparalavadevi_schema.ornaments_purchased_info AS opi, vyaparalavadevi_schema.purchased_ornaments_selled_info AS posi
WHERE opi.auto_incr_for_same_d_n = posi.auto_incr_for_same_d_n AND opi.date = posi.date AND opi.business_man_name = posi.identified_business_man_name
ORDER BY opi.date DESC, opi.auto_incr_for_same_d_n DESC;

/* SPECIFIC purchased ORNAMENT PROFIT CALCULATION AFTER SALE: */
/* ========================================================= */ (
with 
o_id AS (
SELECT auto_incr_for_same_d_n AS aifsdn, date AS d, business_man_name AS wn
FROM vyaparalavadevi_schema.ornaments_purchased_info
WHERE auto_incr_for_same_d_n = "1" AND date = "2021-06-19" AND business_man_name = "మస్తాన్"
),
tocst AS (
SELECT ROUND(opi.total_ornaments_weight * ROUND(opi.ornaments_purchased_percentage/100, 3) * opi.metal_rate_1_gram, 3) AS total_ornaments_cost 
FROM vyaparalavadevi_schema.ornaments_purchased_info opi, o_id
WHERE opi.auto_incr_for_same_d_n = o_id.aifsdn AND opi.date = o_id.d AND opi.business_man_name = o_id.wn
),
onc AS ( 
SELECT GROUP_CONCAT(CONCAT(" ", ornament_name ,"-", ornament_count)) AS ornaments_list
FROM vyaparalavadevi_schema.ornaments_purchased_name_AND_count_info opnaci, o_id
WHERE opnaci.auto_incr_for_same_d_n = o_id.aifsdn AND opnaci.date = o_id.d AND opnaci.business_man_name = o_id.wn
),
/* After purchased ornaments sold: */
sld_o AS (
SELECT SUM(posi.ornaments_sold_weight) AS sold_total_ornaments_weight, 
ROUND(avg(posi.ornaments_sold_percentage), 3) AS sold_ornaments_avg_percentage
FROM vyaparalavadevi_schema.purchased_ornaments_selled_info posi, o_id
WHERE posi.auto_incr_for_same_d_n = o_id.aifsdn AND posi.date = o_id.d AND posi.identified_business_man_name = o_id.wn
),
sld_tog100wt AS (
SELECT ROUND(sld_o.sold_total_ornaments_weight * ROUND(sld_o.sold_ornaments_avg_percentage/100, 3), 2) AS sold_total_ornaments_metal_100_weight
FROM sld_o
),
pft_calc AS (
SELECT (sld_tog100wt.sold_total_ornaments_metal_100_weight * opi.metal_rate_1_gram) AS sold_ornaments_cost,
ROUND(tocst.total_ornaments_cost * ROUND(sld_o.sold_total_ornaments_weight/opi.total_ornaments_weight, 2) , 2) AS sold_ornaments_purchased_cost
FROM tocst, sld_tog100wt, sld_o, vyaparalavadevi_schema.ornaments_purchased_info opi, o_id
WHERE opi.auto_incr_for_same_d_n = o_id.aifsdn AND opi.date = o_id.d AND opi.business_man_name = o_id.wn
)

/* After purchased ornaments sold - to check specific ornament profit after sale AND remaining weight not yet sold: */
SELECT opi.auto_incr_for_same_d_n, opi.date, onc.ornaments_list, 
opi.ornaments_metal_type, opi.total_ornaments_weight,
sld_o.sold_total_ornaments_weight, sld_o.sold_ornaments_avg_percentage, 
sld_tog100wt.sold_total_ornaments_metal_100_weight, pft_calc.sold_ornaments_cost, pft_calc.sold_ornaments_purchased_cost,
(pft_calc.sold_ornaments_cost - pft_calc.sold_ornaments_purchased_cost) AS profit,
(opi.total_ornaments_weight - sld_o.sold_total_ornaments_weight) AS remaining_ornaments_weight
FROM vyaparalavadevi_schema.ornaments_purchased_info opi, sld_o, sld_tog100wt, pft_calc, onc, o_id
WHERE opi.auto_incr_for_same_d_n = o_id.aifsdn AND opi.date = o_id.d AND opi.business_man_name = o_id.wn;

/* specific purchased order sold to list: */
SELECT posi.*
FROM vyaparalavadevi_schema.purchased_ornaments_selled_info posi, o_id
WHERE posi.auto_incr_for_same_d_n = o_id.aifsdn AND posi.date = o_id.d AND posi.identified_business_man_name = o_id.wn
ORDER BY posi.date DESC, posi.auto_incr_for_same_d_n DESC;
)