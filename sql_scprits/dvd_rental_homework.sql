--Выведите уникальные названия городов из таблицы городов.

SELECT DISTINCT city 
FROM city 


--Получите из таблицы платежей за прокат фильмов информацию по платежам, которые выполнялись 
--в промежуток с 17 июня 2005 года по 19 июня 2005 года включительно, 
--и стоимость которых превышает 1.00.
--Платежи нужно отсортировать по дате платежа.

SELECT payment_id, payment_date, amount 
FROM payment 
WHERE payment_date BETWEEN '2005-06-17 00:00:00' AND '2005-06-19 23:59:59' AND amount >=1
ORDER BY payment_date


--Выведите одним запросом только активных покупателей, имена которых KELLY или WILLIE.
--Все буквы в фамилии и имени из верхнего регистра должны быть переведены в нижний регистр.

SELECT lower(last_name) , lower(first_name) , active 
FROM customer 
WHERE (first_name = 'KELLY' OR first_name = 'WILLIE') AND active = 1


--Выведите информацию о фильмах, у которых рейтинг “R” и стоимость аренды указана от 
--0.00 до 3.00 включительно, а также фильмы c рейтингом “PG-13” и стоимостью аренды больше или равной 4.00.

SELECT film_id , title , description , rating , rental_rate 
FROM film 
WHERE rating = 'R' AND rental_rate BETWEEN 0. AND 3. OR rating = 'PG-13' AND rental_rate >=4.


--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

SELECT CONCAT(c.last_name, ' ' , c.first_name) AS "Customer name" , a.address , c2.city , c3.country 
FROM customer c 
INNER JOIN address a ON c.address_id = a.address_id 
INNER JOIN city c2 ON a.city_id = c2.city_id 
INNER JOIN country c3 ON c2.country_id = c3.country_id 


--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

SELECT s.store_id , COUNT(c.store_id)
FROM store s 
INNER JOIN customer c ON s.store_id = c.store_id 
GROUP BY s.store_id 


--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

SELECT s.store_id , COUNT(c.customer_id)
FROM store s 
INNER JOIN customer c ON s.store_id = c.store_id 
GROUP BY s.store_id
HAVING COUNT(c.customer_id) > 300


--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

SELECT CONCAT(c.last_name, ' ' , c.first_name) AS "Фамилия и имя покупателя" ,
COUNT(r.rental_id) AS "Количество фильмов",
ROUND (SUM (p.amount) , 0) AS "Общая стоимость платежей",
MIN(p.amount) AS "Минимальная стоимость платежа", 
MAX (p.amount) AS "Максимальная стоимость платежа"
FROM customer c 
LEFT JOIN rental r ON c.customer_id = r.customer_id 
LEFT JOIN payment p ON r.rental_id  = p.rental_id  
GROUP BY  c.customer_id  

SELECT 
f.title AS "Название фильма", 
f.rating AS "Рейтинг",
c."name" AS "Жанр",
f.release_year AS "Год выпуска",
l."name" AS "Язык",
COUNT(p.rental_id) AS "Количество аренд", 
SUM(p.amount) AS "Общая стоимость аренды"
FROM film f 
LEFT JOIN inventory i ON f.film_id = i.film_id 
LEFT JOIN rental r ON i.inventory_id = r.inventory_id 
LEFT JOIN payment p ON r.rental_id = p.rental_id 
LEFT JOIN film_category fc ON f.film_id = fc.film_id 
LEFT JOIN category c ON fc.category_id = c.category_id 
LEFT JOIN "language" l ON f.language_id = l.language_id 
GROUP BY f.film_id, l.language_id, c.category_id


--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.

SELECT customer_id, payment_id, payment_date,
ROW_NUMBER () OVER (ORDER BY payment_date) AS column1,
ROW_NUMBER () OVER (PARTITION BY customer_id ORDER BY payment_date) AS column2,
sum(amount) OVER (PARTITION BY customer_id ORDER BY payment_date, amount ASC) AS column3,
RANK () OVER (PARTITION BY customer_id ORDER BY amount DESC) AS column4
FROM payment p 


--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

SELECT customer_id, payment_id, payment_date, amount 
FROM (
SELECT *,
LAST_VALUE (rental_id) OVER (PARTITION BY customer_id)
FROM (
SELECT *
FROM payment p 
ORDER BY customer_id, payment_date ASC ) )
WHERE rental_id = LAST_VALUE


--Создайте новую таблицу film_new со следующими полями:
--·   	film_name - название фильма - тип данных varchar(255) и ограничение not null
--·   	film_year - год выпуска фильма - тип данных integer, условие, что значение должно быть больше 0
--·   	film_rental_rate - стоимость аренды фильма - тип данных numeric(4,2), значение по умолчанию 0.99
--·   	film_duration - длительность фильма в минутах - тип данных integer, 
--·     ограничение not null и условие, что значение должно быть больше 0

CREATE TABLE film_new (
film_id serial PRIMARY KEY ,
film_name VARCHAR(255) UNIQUE NOT NULL ,
film_year integer CHECK (film_year > 0) ,
film_rental_rate numeric(4,2) DEFAULT (0.99) ,
film_duration int NOT NULL CHECK (film_duration > 0) )


--Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
--·       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--·       film_year - array[1994, 1999, 1985, 1994, 1993]
--·       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--·   	  film_duration - array[142, 189, 116, 142, 195]

INSERT INTO film_new (film_name , film_year , film_rental_rate , film_duration)
VALUES 
('The Shawshank Redemption' , '1994' , '2.99' , '142') , 
('The Green Mile' , '1999' , '0.99' , '189') , 
('Back to the Future' , '1985' , '1.99' , '116') , 
('Forrest Gump' , '1994' , '2.99' , '142') , 
('Schindlers List' , '1993' , '3.99' , '195')


--Обновите стоимость аренды фильмов в таблице film_new с учетом информации, 
--что стоимость аренды всех фильмов поднялась на 1.41

UPDATE film_new 
SET film_rental_rate = (film_rental_rate + 1.41)


--Фильм с названием "Back to the Future" был снят с аренды, 
--удалите строку с этим фильмом из таблицы film_new

DELETE FROM film_new 
WHERE film_id = 3


--Добавьте в таблицу film_new запись о любом другом новом фильме

INSERT INTO film_new (film_name , film_year , film_rental_rate , film_duration)
VALUES ('Fight Club' , '1999' , '2.99' , '139')


--Удалите таблицу film_new

DROP TABLE film_new 