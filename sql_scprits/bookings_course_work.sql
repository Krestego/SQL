
-- Выведите названия самолётов, которые имеют менее 50 посадочных мест.

EXPLAIN ANALYZE -- 34,5 / 1,8 ms

SELECT model , COUNT (s.seat_no)
FROM aircrafts a 
LEFT JOIN seats s ON a.aircraft_code = s.aircraft_code 
GROUP BY a.model 
HAVING (COUNT (s.seat_no)) < 50

-- Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.

EXPLAIN ANALYZE -- 30701 / 137 ms

SELECT * ,
LEAD (SUM) OVER (ORDER BY date_trunc),
ROUND(((SUM - LAG(SUM) OVER (ORDER BY date_trunc)) / (LAG(SUM) OVER (ORDER BY date_trunc)) * 100.), 2)
FROM (
SELECT date_trunc ('month', book_date)::date, sum(total_amount)
FROM bookings
GROUP BY date_trunc ('month', book_date)::date )b


-- Выведите названия самолётов без бизнес-класса. 
-- Используйте в решении функцию array_agg.

EXPLAIN ANALYZE -- 36 / 1.3 ms

SELECT m.model , array_agg(m.fare_conditions) AS fc
FROM (
	SELECT a.model  , s.fare_conditions 
	FROM seats s
	JOIN aircrafts a ON a.aircraft_code = s.aircraft_code 
	GROUP BY a.model  , s.fare_conditions 
		) m
GROUP BY m.model
HAVING 'Business' != ALL (array_agg(m.fare_conditions))


-- Найдите процентное соотношение перелётов по маршрутам от общего количества перелётов. 
-- Выведите в результат названия аэропортов и процентное отношение.
-- Используйте в решении оконную функцию.

EXPLAIN ANALYZE -- 1563 / 55 ms

SELECT fv.airport_names, fv.count_flight, 
round(fv.count_flight * 100. / sum(fv.count_flight) OVER () , 2)
FROM (
		SELECT concat(departure_airport_name,' - ', arrival_airport_name)  AS airport_names , count (flight_no) AS count_flight 
		FROM flights_v 
		GROUP BY concat(departure_airport_name,' - ', arrival_airport_name)
	) fv
	

-- Классифицируйте финансовые обороты (сумму стоимости перелетов) по маршрутам:
-- до 50 млн – low
-- от 50 млн включительно до 150 млн – middle
-- от 150 млн включительно – high
-- Выведите в результат количество маршрутов в каждом полученном классе.

EXPLAIN ANALYZE -- 23208 / 791 ms

SELECT class_fl, count(class_fl)
FROM (
SELECT concat(fv.departure_airport, ' - ', fv.arrival_airport), sum(tf.amount) ,
CASE
	WHEN sum(tf.amount) < 50000000 THEN 'low'
	WHEN sum(tf.amount) >= 50000000 AND sum(tf.amount) < 150000000 THEN 'middle'
	ELSE 'high'
END AS "class_fl" 
FROM flights_v fv  
JOIN ticket_flights tf ON tf.flight_id = fv.flight_id 
GROUP BY concat(fv.departure_airport, ' - ', fv.arrival_airport)) fv2
GROUP BY class_fl


-- Вычислите медиану стоимости перелетов, 
-- медиану стоимости бронирования 
-- и отношение медианы бронирования к медиане стоимости перелетов, 
-- результат округлите до сотых. 

EXPLAIN ANALYZE -- 30116 / 912 ms

WITH amount AS (
		SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY tf.amount) AS median_amount
		FROM ticket_flights tf
						) ,
		total_amount AS (
		SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY b.total_amount) AS median_total_amount
		FROM bookings b )

SELECT a.median_amount , ta.median_total_amount , round (CAST ((ta.median_total_amount / a.median_amount) AS numeric ) , 2)
FROM amount a , total_amount ta


-- Найдите значение минимальной стоимости одного километра полёта для пассажира. 
-- Для этого определите расстояние между аэропортами и учтите стоимость перелета.
-- Для поиска расстояния между двумя точками на поверхности Земли 
-- использовался дополнительный модуль earthdistance. 
-- Для работы данного модуля устанавливался модуль – cube.


EXPLAIN ANALYZE -- 826228 / 21862 ms 

SELECT ROUND(min((f3.amount / (f3.distance/1000))), 2) AS amount_one_km
FROM (	
	SELECT f2.departure_airport , f2.arrival_airport , f2.amount , 
	CAST(earth_distance((ll_to_earth(a.latitude, a.longitude)) , (ll_to_earth(a2.latitude, a2.longitude)))AS NUMERIC) AS distance
	FROM (  	
		SELECT  f.departure_airport , f.arrival_airport , tf.amount 
		FROM flights f 
		LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id 
	) f2
	LEFT JOIN airports a ON f2.departure_airport = a.airport_code 
	LEFT JOIN airports a2 ON f2.arrival_airport = a2.airport_code 
) f3
 



