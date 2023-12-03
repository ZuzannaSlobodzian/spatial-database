CREATE DATABASE lab7;
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

SELECT * FROM ndwi

SELECT ST_SRID(geom) FROM national_parks
SELECT ST_SRID(rast) FROM sent0332

--2
--raster2pgsql.exe -s 27700 -N -32767 -t 400x400 -I -C -M -d C:\Users\zuzka\Documents\studia\GEOINFA\
--Bazy_danych_przestrzennych\lab7\data\* public.uk_250k | psql -d lab7 -h localhost -U postgres -p 5799

--6
CREATE TABLE uk_lake_district AS
SELECT ST_Clip(uk.rast, np.geom, true), np.id
FROM uk_250k AS uk, national_parks AS np
WHERE ST_Intersects(uk.rast, np.geom) AND np.id=1;

--7
CREATE TABLE ndwi AS
WITH r3 AS (
	SELECT ST_Clip(s3.rast, ST_Transform(np.geom, 4326), true) AS rast
	FROM sent0332 AS s3, national_parks AS np
	WHERE np.id=1 and ST_Intersects(s3.rast, ST_Transform(np.geom, 4326))
),
r8 AS (
	SELECT ST_Clip(s8.rast, ST_Transform(np.geom, 4326), true) AS rast
	FROM sent0832 AS s8, national_parks AS np
	WHERE np.id=1 and ST_Intersects(s8.rast, ST_Transform(np.geom, 4326))
)
SELECT ST_MapAlgebra(
	r3.rast,
	r8.rast,
	'([rast1.val] - [rast2.val]) / ([rast1.val] + [rast2.val])::float','32BF'
) AS rast
FROM r3, r8;

