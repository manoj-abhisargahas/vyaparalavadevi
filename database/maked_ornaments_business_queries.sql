/* all maked ornaments list: */
SELECT * 
FROM vyaparalavadevi_schema.ornaments_making_info
ORDER BY date DESC, auto_incr_for_same_d_n DESC;

/* ornaments in making process list: */
SELECT * 
FROM vyaparalavadevi_schema.ornaments_making_info
WHERE total_ornaments_weight IS NULL
ORDER BY date DESC, auto_incr_for_same_d_n DESC;

/* making ornaments ready for sale list: */
SELECT DISTINCT omi.*
FROM vyaparalavadevi_schema.ornaments_making_info as omi, vyaparalavadevi_schema.maked_ornaments_selled_info as mosi
WHERE NOT (omi.auto_incr_for_same_d_n = mosi.auto_incr_for_same_d_n and omi.date = mosi.date and omi.worker_name = mosi.worker_name) 
and omi.total_ornaments_weight IS NOT NULL 
ORDER BY omi.date DESC, omi.auto_incr_for_same_d_n DESC;

/* maked ornaments solded list: */
SELECT DISTINCT omi.*
FROM vyaparalavadevi_schema.ornaments_making_info as omi, vyaparalavadevi_schema.maked_ornaments_selled_info as mosi
WHERE omi.auto_incr_for_same_d_n = mosi.auto_incr_for_same_d_n and omi.date = mosi.date and omi.worker_name = mosi.worker_name
and omi.total_ornaments_weight IS NOT NULL 
ORDER BY omi.date DESC, omi.auto_incr_for_same_d_n DESC;

/* SPECIFIC MAKED ORNAMENT PERCENT ESTIMATE BEFORE SALE AND PROFIT CALCULATION AFTER SALE: */
/* ================================================================================= */ (
with 
o_id as (
SELECT auto_incr_for_same_d_n AS aifsdn, date AS d, worker_name AS wn
FROM vyaparalavadevi_schema.ornaments_making_info
WHERE auto_incr_for_same_d_n = "1" and date = "2021-06-14" and worker_name = "శివ"
),
/* at time of making ornaments ready: */
t100gwt as (
SELECT SUM(truncate(truncate(omci.metal_purity_percentage/100, 2) * omci.metal_weight, 3)) as total_100_percnt_gold_weight
FROM vyaparalavadevi_schema.ornaments_making_cost_info omci, o_id
WHERE omci.metal_name="GLD" 
and omci.auto_incr_for_same_d_n = o_id.aifsdn and omci.date = o_id.d and omci.worker_name = o_id.wn
),
cgwt as (
SELECT truncate(t100gwt.total_100_percnt_gold_weight / truncate(omi.metal_purity_percentage/100, 2), 3) as converted_gold_weight
FROM vyaparalavadevi_schema.ornaments_making_info omi, t100gwt, o_id
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn and omi.date = o_id.d and omi.worker_name = o_id.wn
),
wgwt as (
SELECT truncate(truncate(omi.worker_percentage/100, 2) * cgwt.converted_gold_weight, 3) as worker_taken_gold_weight
FROM vyaparalavadevi_schema.ornaments_making_info omi, cgwt, o_id
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn and omi.date = o_id.d and omi.worker_name = o_id.wn
),
gwtfw as (
SELECT (cgwt.converted_gold_weight - wgwt.worker_taken_gold_weight) as gold_weight_for_work
FROM cgwt, wgwt
),
tstwt as (
SELECT SUM(omci.metal_weight) as total_stone_weight
FROM vyaparalavadevi_schema.ornaments_making_cost_info omci, o_id
WHERE metal_name="STN"  
and omci.auto_incr_for_same_d_n = o_id.aifsdn and omci.date = o_id.d and omci.worker_name = o_id.wn
),
tocst as (
SELECT SUM(omci.metal_cost) as total_ornaments_cost 
FROM vyaparalavadevi_schema.ornaments_making_cost_info omci, o_id
WHERE omci.auto_incr_for_same_d_n = o_id.aifsdn and omci.date = o_id.d and omci.worker_name = o_id.wn
),
onegrm_gcst as (
SELECT truncate(SUM(omci.metal_cost)/SUM(omci.metal_weight), 2) as one_gram_gold_cost
FROM vyaparalavadevi_schema.ornaments_making_cost_info omci, o_id
WHERE omci.metal_name="GLD"
and omci.auto_incr_for_same_d_n = o_id.aifsdn and omci.date = o_id.d and omci.worker_name = o_id.wn
),
safe_prcnt as (
SELECT truncate(tocst.total_ornaments_cost/(omi.total_ornaments_weight * 5200.00) * 100, 2) as money_safe_percent,
truncate(tocst.total_ornaments_cost/(omi.total_ornaments_weight * onegrm_gcst.one_gram_gold_cost) * 100, 2) as metal_safe_percent
FROM vyaparalavadevi_schema.ornaments_making_info omi, tocst, onegrm_gcst, o_id
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn and omi.date = o_id.d and omi.worker_name = o_id.wn
),
/* After maked ornaments sold: */
sld_o as (
SELECT SUM(mosi.ornaments_sold_weight) as sold_total_ornaments_weight, 
truncate(avg(mosi.ornaments_sold_percentage), 2) as sold_ornaments_avg_percentage
FROM vyaparalavadevi_schema.maked_ornaments_selled_info mosi, o_id
WHERE mosi.auto_incr_for_same_d_n = o_id.aifsdn and mosi.date = o_id.d and mosi.worker_name = o_id.wn
),
sld_tog100wt as (
SELECT truncate(sld_o.sold_total_ornaments_weight * truncate(sld_o.sold_ornaments_avg_percentage / 100, 2), 2) as sold_total_ornaments_gold_100_weight
FROM sld_o
),
pft_calc as (
SELECT (sld_tog100wt.sold_total_ornaments_gold_100_weight * onegrm_gcst.one_gram_gold_cost) as sold_ornaments_cost,
truncate(tocst.total_ornaments_cost * truncate(sld_o.sold_total_ornaments_weight/opi.total_ornaments_weight, 2) , 2) as sold_ornaments_making_cost
FROM sld_tog100wt, onegrm_gcst, tocst, sld_o, vyaparalavadevi_schema.ornaments_making_info omi, o_id
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn and omi.date = o_id.d and omi.worker_name = o_id.wn
)

/* At time of ornaments ready - to get specific ornament estimated_maked_percentage: */
SELECT omi.auto_incr_for_same_d_n, omi.date, omi.worker_name, omi.ornament_name, omi.ornament_count, 
t100gwt.total_100_percnt_gold_weight, omi.metal_purity_percentage, cgwt.converted_gold_weight, 
omi.worker_percentage, wgwt.worker_taken_gold_weight, 
gwtfw.gold_weight_for_work, tstwt.total_stone_weight,
(gwtfw.gold_weight_for_work + tstwt.total_stone_weight) as estimated_ornaments_weight, omi.total_ornaments_weight as real_ornaments_weight,
tocst.total_ornaments_cost, safe_prcnt.money_safe_percent, safe_prcnt.metal_safe_percent
FROM vyaparalavadevi_schema.ornaments_making_info omi, t100gwt, cgwt, wgwt, gwtfw, tstwt, tocst, safe_prcnt, o_id
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn and omi.date = o_id.d and omi.worker_name = o_id.wn;

/* specific maked ornament making charges: */
SELECT omci.*
FROM vyaparalavadevi_schema.ornaments_making_cost_info omci, o_id
WHERE omci.auto_incr_for_same_d_n = o_id.aifsdn and omci.date = o_id.d and omci.worker_name = o_id.wn
ORDER BY omci.date DESC, omci.auto_incr_for_same_d_n DESC;

/* After maked ornaments sold - to check specific ornament profit after sale and remaining weight not yet sold: */
SELECT omi.auto_incr_for_same_d_n, omi.date, omi.worker_name, omi.ornament_name, omi.ornament_count, 
t100gwt.total_100_percnt_gold_weight, omi.metal_purity_percentage, cgwt.converted_gold_weight, 
omi.worker_percentage, wgwt.worker_taken_gold_weight, 
gwtfw.gold_weight_for_work, tstwt.total_stone_weight,
(gwtfw.gold_weight_for_work + tstwt.total_stone_weight) as estimated_ornaments_weight, omi.total_ornaments_weight as real_ornaments_weight,
tocst.total_ornaments_cost, safe_prcnt.money_safe_percent, safe_prcnt.metal_safe_percent, 
sld_o.sold_total_ornaments_weight, sld_o.sold_ornaments_avg_percentage, 
sld_tog100wt.sold_total_ornaments_gold_100_weight, pft_calc.sold_ornaments_cost, pft_calc.sold_ornaments_making_cost,
(pft_calc.sold_ornaments_cost - pft_calc.sold_ornaments_making_cost) as profit,
(omi.total_ornaments_weight - sld_o.sold_total_ornaments_weight) as remaining_ornaments_weight
FROM vyaparalavadevi_schema.ornaments_making_info omi, t100gwt, cgwt, wgwt, gwtfw, tstwt, tocst, safe_prcnt, sld_o, sld_tog100wt, pft_calc, o_id
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn and omi.date = o_id.d and omi.worker_name = o_id.wn;

/* specific maked ornament sold to list: */
SELECT mosi.*
FROM vyaparalavadevi_schema.maked_ornaments_selled_info mosi, o_id
WHERE mosi.auto_incr_for_same_d_n = o_id.aifsdn and mosi.date = o_id.d and mosi.worker_name = o_id.wn
ORDER BY mosi.date DESC, mosi.auto_incr_for_same_d_n DESC;
)