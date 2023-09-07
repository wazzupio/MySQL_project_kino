/*
1. Текстовое описание БД:
	- Это модель хранения данных на приимере веб-сайта кинопоиск.
Хранение данных:
	- Пользователи и их профили
	- Актеры
	- Фильмы
	- Жанры
Хранение данных о фильмах:
	- В главхных ролях (какие актеры снимались в фильме)
	- Жанр фильма
Хранение данных о пользователях:
	- Какие фильмы у пользователей в избронном
	- Какие пользователи на какой фильм написали рецензии 
	- Какие пользователи на какие рецензии написали комментарии
	- Оценка пользователей на тот или иной фильм

2. Таблицы (11шт.):
- Пользователи (список)
- Профили (профиль:пользователь) 
- Актеры (список)
- Фильмы (список)
- Жанры (список)
- Жанр фильма (фильмы:жанры)
- В главных ролях (фильм:актеры)
- Избранное (пользователи:фильмы)
- Рецензии (пользователи:фильмы)
- Комментарии на рецензии (реценизия:пользователи)
- Оценки (пользователи:фильмы)
*/

/*
3. Скрипты создания структуры БД (с первичными ключами, индексами,
внешними ключами)
*/

DROP DATABASE IF EXISTS kino;
CREATE DATABASE kino;

USE kino;

-- Таблица пользователей.
DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id bigint UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	first_name varchar(145) NOT NULL,
	last_name varchar(145) NOT NULL,
	email varchar(145) NOT NULL,
	created_at datetime NOT NULL DEFAULT current_timestamp,
  	UNIQUE KEY email_idx (email)
);

-- Таблица профилей (связь 1:1).
DROP TABLE IF EXISTS profiles;
CREATE TABLE profiles(
	user_id bigint UNSIGNED NOT NULL PRIMARY KEY,
	gender enum ('f', 'm', 'x') NOT NULL,
	birthday date NOT NULL,
	city varchar(145),
	country varchar(145),
	phone char(11) NOT NULL,
	UNIQUE KEY phone_idx (phone),
	CONSTRAINT phone_check CHECK (regexp_like(phone, _utf8mb4'^[0-9]{11}$')),
	CONSTRAINT fk_profiles_users FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Таблица актеров.
DROP TABLE IF EXISTS actors;
CREATE TABLE actors (
	id bigint UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	first_name varchar(145) NOT NULL,
	last_name varchar(145) NOT NULL,
	birthday date NOT NULL,
	place_of_birth varchar(145) NOT NULL,
	created_at datetime NOT NULL DEFAULT current_timestamp
);

-- Таблица фильмов.
DROP TABLE IF EXISTS films;
CREATE TABLE films (
	id bigint UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name varchar(145) NOT NULL,
	released_year char(4) NOT NULL,
	country varchar(145) NOT NULL,
	age_category enum ('0+', '6+', '12+', '16+', '18+') NOT NULL,
	movie_duration_min bigint UNSIGNED NOT NULL, -- Продолжительность фильма в мин.
	description TEXT NOT NULL,
	created_at datetime NOT NULL DEFAULT current_timestamp
);

-- Таблица жанры.
DROP TABLE IF EXISTS genres;
CREATE TABLE genres (
	id bigint UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	genre varchar(145) NOT NULL
);

-- Таблица жанр фильма (связь мн:мн).
DROP TABLE IF EXISTS film_genre;
CREATE TABLE film_genre (
	film_id bigint UNSIGNED NOT NULL,
	genre_id bigint UNSIGNED NOT NULL,
	CONSTRAINT fk_film_genre_films FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE,
	CONSTRAINT fk_film_genre_genres FOREIGN KEY (genre_id) REFERENCES genres (id) ON DELETE CASCADE
);


-- В главных ролях (связь мн:мн).
DROP TABLE IF EXISTS starring;
CREATE TABLE starring (
	film_id bigint UNSIGNED NOT NULL,
	actor_id bigint UNSIGNED NOT NULL,
	CONSTRAINT fk_starring_films FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE,
	CONSTRAINT fk_starring_actors FOREIGN KEY (actor_id) REFERENCES actors (id) ON DELETE CASCADE
);

-- Таблица избранное (связь мн:мн).
DROP TABLE IF EXISTS favorites;
CREATE TABLE favorites (
	user_id bigint UNSIGNED NOT NULL,
	film_id bigint UNSIGNED NOT NULL,
	PRIMARY KEY (user_id, film_id), -- Пользователь не может добавить в избранное один фильм несколько раз.
	CONSTRAINT fk_favorites_users FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
	CONSTRAINT fk_favorites_films FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE
);

-- Таблица рецензии (связь 1:мн).
DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews (
	id bigint UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	user_id bigint UNSIGNED NOT NULL,
	film_id bigint UNSIGNED NOT NULL,
	txt TEXT NOT NULL,
	CONSTRAINT fk_reviews_users FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
	CONSTRAINT fk_reviews_films FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE
);

-- Таблица комментарии на рецензии (связь 1:мн).
DROP TABLE IF EXISTS comments_on_reviews;
CREATE TABLE comments_on_reviews (
	id bigint UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	user_id bigint UNSIGNED NOT NULL,
	review_id bigint UNSIGNED NOT NULL,
	txt TEXT NOT NULL,
	CONSTRAINT fk_comments_on_reviews_reviews FOREIGN KEY (review_id) REFERENCES reviews (id) ON DELETE CASCADE,
	CONSTRAINT fk_comments_on_reviews_users FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Таблица оценки (связь мн:мн)
DROP TABLE IF EXISTS film_ratings;
CREATE TABLE film_ratings (
	user_id bigint UNSIGNED NOT NULL,
	film_id bigint UNSIGNED NOT NULL,
	rating char(1) NOT NULL,
	PRIMARY KEY (user_id, film_id), -- Пользователь не может постваить оценку одному фильму несколько раз.
	CONSTRAINT fk_film_ratings_users FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
	CONSTRAINT fk_film_ratings_films FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE,
	CONSTRAINT rating_check CHECK (regexp_like(rating, _utf8mb4'^[1-5]{1}$'))
);
