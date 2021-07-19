/* all maked_ornaments_orders list: */
SELECT * 
FROM vyaparalavadevi_schema.ornaments_making_info
ORDER BY date DESC, auto_incr_for_same_d_n DESC;

/* ornaments_orders in making process list: */
SELECT * 
FROM vyaparalavadevi_schema.ornaments_making_info
WHERE total_ornaments_weight IS NULL
ORDER BY date DESC, auto_incr_for_same_d_n DESC;

/* making_ornaments_orders ready for sale (not yet sold) list: */
SELECT DISTINCT omi.*
FROM vyaparalavadevi_schema.ornaments_making_info AS omi, vyaparalavadevi_schema.maked_ornaments_selled_info AS mosi
WHERE NOT (omi.auto_incr_for_same_d_n = mosi.auto_incr_for_same_d_n AND omi.date = mosi.date AND omi.worker_name = mosi.worker_name) 
AND omi.total_ornaments_weight IS NOT NULL 
ORDER BY omi.date DESC, omi.auto_incr_for_same_d_n DESC;

/* maked_ornaments_orders solded list: */
SELECT DISTINCT omi.*
FROM vyaparalavadevi_schema.ornaments_making_info AS omi, vyaparalavadevi_schema.maked_ornaments_selled_info AS mosi
WHERE omi.auto_incr_for_same_d_n = mosi.auto_incr_for_same_d_n AND omi.date = mosi.date AND omi.worker_name = mosi.worker_name
AND omi.total_ornaments_weight IS NOT NULL 
ORDER BY omi.date DESC, omi.auto_incr_for_same_d_n DESC;

/* SPECIFIC maked_ornaments_order PERCENT ESTIMATE BEFORE SALE AND PROFIT CALCULATION AFTER SALE: */
/* ================================================================================= */ (
with 
o_id AS (
SELECT auto_incr_for_same_d_n AS aifsdn, date AS d, worker_name AS wn
FROM vyaparalavadevi_schema.ornaments_making_info
WHERE auto_incr_for_same_d_n = "1" AND date = "2021-06-14" AND worker_name = "శివ"
),
mpp_g24k AS (
SELECT metal_purity_percentage 
FROM vyaparalavadevi_schema.metal_types 
WHERE metal_type="GLD-24k"
),
mpp_g22k AS (
SELECT metal_purity_percentage 
FROM vyaparalavadevi_schema.metal_types  
WHERE metal_type="GLD-22k"
),
/* at time of making_ornaments_order ready: */
t100gwt AS (
SELECT SUM(ROUND(omci.metal_weight * ROUND(mt.metal_purity_percentage/100, 3), 3)) AS total_100_percnt_metal_weight
FROM vyaparalavadevi_schema.ornaments_making_cost_info omci, vyaparalavadevi_schema.metal_types mt, o_id
WHERE omci.auto_incr_for_same_d_n = o_id.aifsdn AND omci.date = o_id.d AND omci.worker_name = o_id.wn 
AND mt.metal_type = omci.metal_type AND mt.metal_type REGEXP "GLD" = 1
),
cgwt AS (
SELECT ROUND(t100gwt.total_100_percnt_metal_weight / ROUND(mt.metal_purity_percentage/100, 3), 3) AS converted_metal_weight
FROM vyaparalavadevi_schema.ornaments_making_info omi, mpp_g22k, t100gwt, o_id, vyaparalavadevi_schema.metal_types mt
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn AND omi.date = o_id.d AND omi.worker_name = o_id.wn 
AND omi.ornaments_metal_type = mt.metal_type
),
twp AS (
SELECT ROUND(avg(omwpi.worker_percentage), 2) AS total_workers_percentage
FROM vyaparalavadevi_schema.ornaments_making_worker_percentages_info omwpi
),
wgwt AS (
SELECT ROUND(ROUND(twp.total_workers_percentage/100, 2) * cgwt.converted_metal_weight, 3) AS workers_taken_metal_weight
FROM twp, cgwt
),
gwtfw AS (
SELECT (cgwt.converted_metal_weight - wgwt.workers_taken_metal_weight) AS metal_weight_for_work
FROM cgwt, wgwt
),
tstwt AS (
SELECT SUM(omci.metal_weight) AS total_stone_weight
FROM vyaparalavadevi_schema.ornaments_making_cost_info omci, o_id
WHERE omci.metal_type="STN"  
AND omci.auto_incr_for_same_d_n = o_id.aifsdn AND omci.date = o_id.d AND omci.worker_name = o_id.wn
),
tomcst AS (
SELECT IFNULL(SUM(omci.metal_cost), 0) AS total_ornaments_metal_cost 
FROM vyaparalavadevi_schema.ornaments_making_cost_info omci, o_id
WHERE omci.auto_incr_for_same_d_n = o_id.aifsdn AND omci.date = o_id.d AND omci.worker_name = o_id.wn
),
toocst AS (
SELECT IFNULL(SUM(omoci.rupees), 0) AS total_ornaments_other_costs 
FROM vyaparalavadevi_schema.ornaments_making_other_costs_info omoci, o_id
WHERE omoci.auto_incr_for_same_d_n = o_id.aifsdn AND omoci.date = o_id.d AND omoci.identified_worker_name = o_id.wn
),
tocst AS (
SELECT (tomcst.total_ornaments_metal_cost + toocst.total_ornaments_other_costs) AS total_ornaments_cost 
FROM tomcst, toocst, o_id
),
onegrm_mcst AS (
SELECT ROUND(SUM(ROUND(omci.metal_cost * ROUND(mt.metal_purity_percentage/100, 3), 2))/
SUM(ROUND(omci.metal_weight * ROUND(mt.metal_purity_percentage/100, 3), 3)), 2) AS one_gram_metal_cost
FROM vyaparalavadevi_schema.ornaments_making_cost_info omci, vyaparalavadevi_schema.metal_types mt, o_id
WHERE omci.auto_incr_for_same_d_n = o_id.aifsdn AND omci.date = o_id.d AND omci.worker_name = o_id.wn 
AND mt.metal_type = omci.metal_type AND mt.metal_type REGEXP "GLD" = 1
),
safe_prcnt AS (
SELECT ROUND(tocst.total_ornaments_cost/(omi.total_ornaments_weight * 5200.00) * 100, 2) AS money_safe_percent,
ROUND(tocst.total_ornaments_cost/(omi.total_ornaments_weight * onegrm_mcst.one_gram_metal_cost) * 100, 2) AS metal_safe_percent
FROM vyaparalavadevi_schema.ornaments_making_info omi, tocst, onegrm_mcst, o_id
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn AND omi.date = o_id.d AND omi.worker_name = o_id.wn
),
onc AS ( 
SELECT GROUP_CONCAT(CONCAT(" ", ornament_name ,"-", ornament_count)) AS ornaments_list
FROM vyaparalavadevi_schema.ornaments_making_name_AND_count_info omnaci, o_id
WHERE omnaci.auto_incr_for_same_d_n = o_id.aifsdn AND omnaci.date = o_id.d AND omnaci.worker_name = o_id.wn
),
watp AS ( 
SELECT GROUP_CONCAT(CONCAT(" ", worker_name ,"-", worker_percentage, "%")) AS workers_AND_their_percentages
FROM vyaparalavadevi_schema.ornaments_making_worker_percentages_info omwpi, o_id
WHERE omwpi.auto_incr_for_same_d_n = o_id.aifsdn AND omwpi.date = o_id.d AND omwpi.identified_worker_name = o_id.wn
),
/* After maked_ornaments_order sold: */
sld_o AS (
SELECT SUM(mosi.ornaments_sold_weight) AS sold_total_ornaments_weight, 
ROUND(avg(mosi.ornaments_sold_percentage), 2) AS sold_ornaments_avg_percentage
FROM vyaparalavadevi_schema.maked_ornaments_selled_info mosi, o_id
WHERE mosi.auto_incr_for_same_d_n = o_id.aifsdn AND mosi.date = o_id.d AND mosi.worker_name = o_id.wn
),
sld_tog100wt AS (
SELECT ROUND(sld_o.sold_total_ornaments_weight * ROUND(sld_o.sold_ornaments_avg_percentage / 100, 2), 2) AS sold_total_ornaments_metal_100_weight
FROM sld_o
),
pft_calc AS (
SELECT (sld_tog100wt.sold_total_ornaments_metal_100_weight * onegrm_mcst.one_gram_metal_cost) AS sold_ornaments_cost,
ROUND(tocst.total_ornaments_cost * ROUND(sld_o.sold_total_ornaments_weight/omi.total_ornaments_weight, 2) , 2) AS sold_ornaments_making_cost
FROM sld_tog100wt, onegrm_mcst, tocst, sld_o, vyaparalavadevi_schema.ornaments_making_info omi, o_id
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn AND omi.date = o_id.d AND omi.worker_name = o_id.wn
)

/* After maked_ornaments_orders sold - to check specific maked_ornaments_order profit after sale AND remaining weight not yet sold: */
SELECT omi.auto_incr_for_same_d_n, omi.date, omi.worker_name, onc.ornaments_list, watp.workers_AND_their_percentages, 
t100gwt.total_100_percnt_metal_weight, omi.ornaments_metal_type, cgwt.converted_metal_weight, 
twp.total_workers_percentage, wgwt.workers_taken_metal_weight, 
gwtfw.metal_weight_for_work, tstwt.total_stone_weight,
(gwtfw.metal_weight_for_work + tstwt.total_stone_weight) AS estimated_ornaments_weight, omi.total_ornaments_weight AS real_ornaments_weight,
tocst.total_ornaments_cost, safe_prcnt.money_safe_percent, safe_prcnt.metal_safe_percent
FROM vyaparalavadevi_schema.ornaments_making_info omi, t100gwt, cgwt, twp, wgwt, gwtfw, tstwt, tocst, safe_prcnt, sld_o, sld_tog100wt, pft_calc, onc, watp, o_id
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn AND omi.date = o_id.d AND omi.worker_name = o_id.wn;

/* specific maked_ornaments_order making charges: */
SELECT omci.*
FROM vyaparalavadevi_schema.ornaments_making_cost_info omci, o_id
WHERE omci.auto_incr_for_same_d_n = o_id.aifsdn AND omci.date = o_id.d AND omci.worker_name = o_id.wn
ORDER BY omci.date DESC, omci.auto_incr_for_same_d_n DESC;

/* After maked_ornaments_orders sold - to check specific maked_ornaments_order profit after sale AND remaining weight not yet sold: */
SELECT omi.auto_incr_for_same_d_n, omi.date, omi.worker_name, onc.ornaments_list, watp.workers_AND_their_percentages, 
t100gwt.total_100_percnt_metal_weight, omi.ornaments_metal_type, cgwt.converted_metal_weight, 
twp.total_workers_percentage, wgwt.workers_taken_metal_weight, 
gwtfw.metal_weight_for_work, tstwt.total_stone_weight,
(gwtfw.metal_weight_for_work + tstwt.total_stone_weight) AS estimated_ornaments_weight, omi.total_ornaments_weight AS real_ornaments_weight,
tocst.total_ornaments_cost, safe_prcnt.money_safe_percent, safe_prcnt.metal_safe_percent, 
sld_o.sold_total_ornaments_weight, sld_o.sold_ornaments_avg_percentage, 
sld_tog100wt.sold_total_ornaments_metal_100_weight, pft_calc.sold_ornaments_cost, pft_calc.sold_ornaments_making_cost,
(pft_calc.sold_ornaments_cost - pft_calc.sold_ornaments_making_cost) AS profit,
(omi.total_ornaments_weight - sld_o.sold_total_ornaments_weight) AS remaining_ornaments_weight
FROM vyaparalavadevi_schema.ornaments_making_info omi, t100gwt, cgwt, twp, wgwt, gwtfw, tstwt, tocst, safe_prcnt, sld_o, sld_tog100wt, pft_calc, onc, watp, o_id
WHERE omi.auto_incr_for_same_d_n = o_id.aifsdn AND omi.date = o_id.d AND omi.worker_name = o_id.wn;

/* specific maked_ornaments_order sold to list: */
SELECT mosi.*
FROM vyaparalavadevi_schema.maked_ornaments_selled_info mosi, o_id
WHERE mosi.auto_incr_for_same_d_n = o_id.aifsdn AND mosi.date = o_id.d AND mosi.worker_name = o_id.wn
ORDER BY mosi.date DESC, mosi.auto_incr_for_same_d_n DESC;
)