USE kino;

/*
6. скрипты характерных выборок (включающие группировки, JOIN'ы,
вложенные таблицы);
 */

-- Вывод информации в профиле пользователя "Федор Кинопоисков"
SELECT * FROM profiles 
WHERE user_id = (SELECT id FROM users u
			WHERE first_name = 'Федор' AND last_name = 'Кинопоисков');

-- Вывод средней оценки на фильм 'Джуманджи'
SELECT round(avg(rating), 1) AS avg_rating FROM film_ratings
WHERE film_id = (SELECT id FROM films
				 WHERE name = 'Джуманджи');
				
-- Вывод жанров фильма "Зеленая миля"					
SELECT genre FROM genres
WHERE id IN (SELECT genre_id FROM film_genre fg
			WHERE film_id = (SELECT id FROM films
							 WHERE name = 'Зеленая миля'));							

-- Вывод пользьвателя написавшего больше всего рецензий
SELECT * FROM users u
JOIN profiles p
ON u.id = p.user_id
WHERE u.id = (SELECT user_id FROM reviews
	  				   GROUP BY user_id
	  				   ORDER BY count(*) DESC LIMIT 1);

/*
7. Представления (минимум 2)

Представления:
- Даныне таблицы films в отсотрировонном состоянии по колонке name
- Фильмы с категорией 16+
- Пользователи которые посмотрели тот или иной фильм
 */

-- Представление в котором будут представленны даныне таблицы films
-- в отсотрировонном состоянии по колонке name	  				  
CREATE OR REPLACE VIEW sort_films_name AS
SELECT * FROM films
ORDER BY name;

SELECT * FROM sort_films_name;

-- Представление в котором будут представленны фильмы с категорией 16+
CREATE OR REPLACE VIEW films_16 AS
SELECT name, released_year, country, age_category, movie_duration_min, description
FROM films
WHERE age_category = '16+';

SELECT * FROM films_16;

-- Представление в котором будут представленны рецензии
-- на фильм "Остров проклятых"
CREATE OR REPLACE VIEW rewiews_film AS
SELECT f.name, r.txt FROM reviews r
JOIN films f
ON f.id = r.film_id
WHERE f.name = 'Остров проклятых';

SELECT * FROM rewiews_film;

/*
8. Хранимые процедуры / триггеры

Процедуры:
- Подборка фильмов по указанному году выпуска
- Расчет полных лет пользователя

Триггеры:
- Создать лог таблицу в которой будет информация о пользователях,
которомыи меньше 18лет и которые написали рецензии на фильмы с категорией 18+
 */

-- Процедура которая будет принимать год выхода фильма,
-- а на выходе будем получать список фильмов этого года выпуска
DELIMITER //
DROP PROCEDURE IF EXISTS films_year//
CREATE PROCEDURE films_year (IN value INT)
BEGIN
	SET @year_of_birth = value;
	SELECT name, released_year, country, age_category, movie_duration_min, description
	FROM films
	WHERE released_year = @year_of_birth;
END//
DELIMITER ;

CALL films_year(1993);

-- Процедура которая будет принимать id пользователя,
-- а на выходе будем получать id, имя, фамилию, полных лет
DELIMITER //
DROP PROCEDURE IF EXISTS user_full_years//
CREATE PROCEDURE user_full_years (INOUT value int)
BEGIN
	SET @id = value;
	SET value = (SELECT YEAR(now()) - (SELECT YEAR(birthday) FROM profiles p 
		   							   WHERE user_id = @id) AS full_years); -- Полных лет пользователю
END//
DELIMITER ;

SET @user_id = 1; -- Помещаем в переменную айдтишник пользователя
CALL user_full_years(@user_id);

SELECT @id AS user_id, @user_id AS full_years;

-- Создать лог файл в котором будет информация о пользователях,
-- которым меньше 18 лет и которые оставили комментарии на фильмы
-- с категорией 18+

-- Создаем таблицу logs
DROP TABLE IF EXISTS logs;
CREATE TABLE logs (
	user_id bigint NOT NULL COMMENT 'id пользователя',
	first_name varchar(255) NOT NULL COMMENT 'Имя',
	last_name varchar(255) NOT NULL COMMENT 'Фамилия',
	full_years int NOT NULL COMMENT 'Полных лет',
	film_id int NOT NULL COMMENT 'id фильма',
	review_id int NOT NULL COMMENT 'id рецензии',
	created_at datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=ARCHIVE;

-- Создаем триггер
DELIMITER //
DROP TRIGGER IF EXISTS add_logs_users//
CREATE TRIGGER add_logs_users AFTER INSERT ON reviews
FOR EACH ROW 
BEGIN
	DECLARE log_first_name varchar(255);
	DECLARE log_last_name varchar(255);
	DECLARE log_full_years int;

	IF (SELECT YEAR(now()) - (SELECT YEAR(birthday) FROM profiles p 
		   					  WHERE user_id = NEW.user_id)) < 18
	THEN   					  
		SELECT first_name INTO log_first_name FROM users WHERE id = NEW.user_id;
		SELECT last_name INTO log_last_name FROM users WHERE id = NEW.user_id;
		SELECT YEAR(now()) - (SELECT YEAR(birthday) FROM profiles p 
		   					  WHERE user_id = NEW.user_id) INTO log_full_years; -- Полных лет пользователю
	
		INSERT INTO logs
		VALUES
		(NEW.user_id, log_first_name, log_last_name, log_full_years, NEW.film_id, NEW.id, DEFAULT);
	END IF;
END//
DELIMITER ;

-- Добавляем новую рецензию от несовершеннолетнего на фильм 18+
INSERT INTO reviews
VALUES
(DEFAULT, 6, 5, 'test');

SELECT * FROM logs;
