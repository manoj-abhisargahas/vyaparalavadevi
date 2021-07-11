/* all purchased ornaments list: */
SELECT * 
FROM vyaparalavadevi_schema.ornaments_purchased_info
ORDER BY date DESC, auto_incr_for_same_d_n DESC;

/* purchased ornaments ready for sale list: */
SELECT DISTINCT opi.*
FROM vyaparalavadevi_schema.ornaments_purchased_info as opi, vyaparalavadevi_schema.purchased_ornaments_selled_info as posi
WHERE NOT (opi.auto_incr_for_same_d_n = posi.auto_incr_for_same_d_n and opi.date = posi.date and opi.worker_name = posi.worker_name) 
ORDER BY opi.date DESC, opi.auto_incr_for_same_d_n DESC;

/* purchased ornaments solded list: */
SELECT DISTINCT opi.*
FROM vyaparalavadevi_schema.ornaments_purchased_info as opi, vyaparalavadevi_schema.purchased_ornaments_selled_info as posi
WHERE opi.auto_incr_for_same_d_n = posi.auto_incr_for_same_d_n and opi.date = posi.date and opi.worker_name = posi.worker_name
ORDER BY opi.date DESC, opi.auto_incr_for_same_d_n DESC;

/* SPECIFIC PURCHASED ORNAMENT PROFIT CALCULATION AFTER SALE: */
/* ========================================================= */ (
with 
o_id as (
SELECT auto_incr_for_same_d_n AS aifsdn, date AS d, worker_name AS wn
FROM vyaparalavadevi_schema.ornaments_purchased_info
WHERE auto_incr_for_same_d_n = "1" and date = "2021-07-22" and worker_name = "మస్తాన్"
),
tocst as (
SELECT truncate(opi.total_ornaments_weight * truncate(opi.purchased_percentage/100, 2) * opi.metal_rate_1_gram, 3) as total_ornaments_cost 
FROM vyaparalavadevi_schema.ornaments_purchased_info opi, o_id
WHERE opi.auto_incr_for_same_d_n = o_id.aifsdn and opi.date = o_id.d and opi.worker_name = o_id.wn
),
/* After purchased ornaments sold: */
sld_o as (
SELECT SUM(posi.ornaments_sold_weight) as sold_total_ornaments_weight, 
truncate(avg(posi.ornaments_sold_percentage), 2) as sold_ornaments_avg_percentage
FROM vyaparalavadevi_schema.purchased_ornaments_selled_info posi, o_id
WHERE posi.auto_incr_for_same_d_n = o_id.aifsdn and posi.date = o_id.d and posi.worker_name = o_id.wn
),
sld_tog100wt as (
SELECT truncate(sld_o.sold_total_ornaments_weight * truncate(sld_o.sold_ornaments_avg_percentage/100, 2), 2) as sold_total_ornaments_gold_100_weight
FROM sld_o
),
pft_calc as (
SELECT (sld_tog100wt.sold_total_ornaments_gold_100_weight * opi.metal_rate_1_gram) as sold_ornaments_cost,
truncate(tocst.total_ornaments_cost * truncate(sld_o.sold_total_ornaments_weight/opi.total_ornaments_weight, 2) , 2) as sold_ornaments_purchased_cost
FROM tocst, sld_tog100wt, sld_o, vyaparalavadevi_schema.ornaments_purchased_info opi, o_id
WHERE opi.auto_incr_for_same_d_n = o_id.aifsdn and opi.date = o_id.d and opi.worker_name = o_id.wn
)


/* After purchased ornaments sold - to check specific ornament profit after sale and remaining weight not yet sold: */
SELECT opi.auto_incr_for_same_d_n, opi.date, opi.ornament_name, opi.ornament_count, 
opi.metal_purity_percentage, opi.total_ornaments_weight,
sld_o.sold_total_ornaments_weight, sld_o.sold_ornaments_avg_percentage, 
sld_tog100wt.sold_total_ornaments_gold_100_weight, pft_calc.sold_ornaments_cost, pft_calc.sold_ornaments_purchased_cost,
(pft_calc.sold_ornaments_cost - pft_calc.sold_ornaments_purchased_cost) as profit,
(opi.total_ornaments_weight - sld_o.sold_total_ornaments_weight) as remaining_ornaments_weight
FROM vyaparalavadevi_schema.ornaments_purchased_info opi, sld_o, sld_tog100wt, pft_calc, o_id
WHERE opi.auto_incr_for_same_d_n = o_id.aifsdn and opi.date = o_id.d and opi.worker_name = o_id.wn;

/* specific purchased ornament sold to list: */
SELECT posi.*
FROM vyaparalavadevi_schema.purchased_ornaments_selled_info posi, o_id
WHERE posi.auto_incr_for_same_d_n = o_id.aifsdn and posi.date = o_id.d and posi.worker_name = o_id.wn
ORDER BY posi.date DESC, posi.auto_incr_for_same_d_n DESC;
)