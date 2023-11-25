--utwrzenie bazy i schematów
CREATE DATABASE raster
CREATE SCHEMA slobodzian
CREATE SCHEMA rasters
CREATE SCHEMA vectors

--dodanie rozszerzeń
CREATE EXTENSION postgis
CREATE EXTENSION postgis_raster

--sprawdzenie zawartości
SELECT * FROM public.raster_columns

--TWORZENIE RASTRÓW Z ISTNIEJĄCYCH RASTRÓW I INERAKCJA Z WEKTORAMI
--Przykład 1 - ST_Intersects
--Przecięcie rastra z wektorem.
CREATE TABLE slobodzian.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

--1. dodanie serial primary key:
alter table slobodzian.intersects
add column rid SERIAL PRIMARY KEY;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON slobodzian.intersects
USING gist (ST_ConvexHull(rast));

--3. dodanie raster constraints:
SELECT AddRasterConstraints('slobodzian'::name,
'intersects'::name,'rast'::name);

--Przykład 2 - ST_Clip
--Obcinanie rastra na podstawie wektora.

CREATE TABLE slobodzian.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

--1. dodanie serial primary key:
alter table slobodzian.clip
add column rid SERIAL PRIMARY KEY;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_clip_rast_gist ON slobodzian.clip
USING gist (ST_ConvexHull(st_clip));

--3. dodanie raster constraints:
SELECT AddRasterConstraints('slobodzian'::name,
'clip'::name,'st_clip'::name);

--Przykład 3 - ST_Union
--Połączenie wielu kafelków w jeden raster.
CREATE TABLE slobodzian.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

--1. dodanie serial primary key:
alter table slobodzian.union
add column rid SERIAL PRIMARY KEY;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_union_rast_gist ON slobodzian.union
USING gist (ST_ConvexHull(st_union));

--3. dodanie raster constraints:
SELECT AddRasterConstraints('slobodzian'::name,
'union'::name,'st_union'::name);

--TWORZENIE RASTRÓW Z WEKTORÓW (RASTROWANIE)
--Przykład 1 - ST_AsRaster
--Przykład pokazuje użycie funkcji ST_AsRaster w celu rastrowania tabeli z parafiami o takiej
--samej charakterystyce przestrzennej tj.: wielkość piksela, zakresy itp.
CREATE TABLE slobodzian.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--1. dodanie serial primary key:
alter table slobodzian.porto_parishes
add column rid SERIAL PRIMARY KEY;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_porto_parishes_rast_gist ON slobodzian.porto_parishes
USING gist (ST_ConvexHull(rast));

--3. dodanie raster constraints:
SELECT AddRasterConstraints('slobodzian'::name,
'porto_parishes'::name,'rast'::name);

--Przykład 2 - ST_Union
--Wynikowy raster z poprzedniego zadania to jedna parafia na rekord, na wiersz tabeli. Użyj QGIS lub ArcGIS do wizualizacji wyników.
--Drugi przykład łączy rekordy z poprzedniego przykładu przy użyciu funkcji ST_UNION w pojedynczy raster.
DROP TABLE slobodzian.porto_parishes; --> drop table porto_parishes first
CREATE TABLE slobodzian.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--1. dodanie serial primary key:
alter table slobodzian.porto_parishes
add column rid SERIAL PRIMARY KEY;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_porto_parishes_rast_gist ON slobodzian.porto_parishes
USING gist (ST_ConvexHull(rast));

--3. dodanie raster constraints:
SELECT AddRasterConstraints('slobodzian'::name,
'porto_parishes'::name,'rast'::name);

--Przykład 3 - ST_Tile
--Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile.
DROP TABLE slobodzian.porto_parishes; --> drop table porto_parishes first
CREATE TABLE slobodzian.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--1. dodanie serial primary key:
alter table slobodzian.porto_parishes
add column rid SERIAL PRIMARY KEY;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_porto_parishes_rast_gist ON slobodzian.porto_parishes
USING gist (ST_ConvexHull(rast));

--3. dodanie raster constraints:
SELECT AddRasterConstraints('slobodzian'::name,
'porto_parishes'::name,'rast'::name);

--KONWERTOWANIE RASTRÓW NA WEKTORY (WEKTORYZOWANIE)
--Przykład 1 - ST_Intersection
create table slobodzian.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--Przykład 2 - ST_DumpAsPolygons
CREATE TABLE slobodzian.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--ANALIZA RASTRÓW

--Przykład 1 - ST_Band
--Funkcja ST_Band służy do wyodrębniania pasm z rastra
CREATE TABLE slobodzian.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

--Przykład 2 - ST_Clip
CREATE TABLE slobodzian.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--Przykład 3 - ST_Slope
CREATE TABLE slobodzian.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM slobodzian.paranhos_dem AS a;

--Przykład 4 - ST_Reclass
--Aby zreklasyfikować raster należy użyć funkcji ST_Reclass.
CREATE TABLE slobodzian.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM slobodzian.paranhos_slope AS a;

--Przykład 5 - ST_SummaryStats
--Aby obliczyć statystyki rastra można użyć funkcji ST_SummaryStats. Poniższy przykład
--wygeneruje statystyki dla kafelka.
SELECT st_summarystats(a.rast) AS stats
FROM slobodzian.paranhos_dem AS a;

--Przykład 6 - ST_SummaryStats oraz Union
--Przy użyciu UNION można wygenerować jedną statystykę wybranego rastra.
SELECT st_summarystats(ST_Union(a.rast))
FROM slobodzian.paranhos_dem AS a;

--Przykład 7 - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM slobodzian.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--Przykład 8 - ST_SummaryStats w połączeniu z GROUP BY
--Aby wyświetlić statystykę dla każdego poligonu "parish" można użyć polecenia GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;


--Przykład 9 - ST_Value
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

--Topographic Position Index (TPI)
--Przykład 10 - ST_TPI
create table slobodzian.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

--1. dodanie serial primary key:
alter table slobodzian.tpi30
add column rid SERIAL PRIMARY KEY;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_tpi30_rast_gist ON slobodzian.tpi30
USING gist (ST_ConvexHull(rast));

--3. dodanie raster constraints:
SELECT AddRasterConstraints('slobodzian'::name,
'tpi30'::name,'rast'::name);

--Przykład 1 - Wyrażenie Algebry Map
CREATE TABLE slobodzian.porto_ndvi AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
	r.rast, 1,
	r.rast, 4,
	'([rast2.val] - [rast1.val]) / ([rast2.val] +
	[rast1.val])::float','32BF'
	) AS rast
FROM r;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi_rast_gist ON slobodzian.porto_ndvi
USING gist (ST_ConvexHull(rast));

--3. dodanie raster constraints:
SELECT AddRasterConstraints('slobodzian'::name,
'porto_ndvi'::name,'rast'::name);

--Przykład 2 – Funkcja zwrotna
--W pierwszym kroku należy utworzyć funkcję, które będzie wywołana później:
create or replace function slobodzian.ndvi(
value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

--W kwerendzie algebry map należy można wywołać zdefiniowaną wcześniej funkcję:
CREATE TABLE slobodzian.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
	r.rast, ARRAY[1,4],
	'slobodzian.ndvi(double precision[],
	integer[],text[])'::regprocedure, --> This is the function!
	'32BF'::text
) AS rast
FROM r;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi2_rast_gist ON slobodzian.porto_ndvi2
USING gist (ST_ConvexHull(rast));

--3. dodanie raster constraints:
SELECT AddRasterConstraints('slobodzian'::name,
'porto_ndvi2'::name,'rast'::name);

create table slobodzian.tpi30_porto as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

--Dodanie indeksu przestrzennego:
CREATE INDEX idx_tpi30_porto_rast_gist ON slobodzian.tpi30_porto
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('slobodzian'::name,
'tpi30_porto'::name,'rast'::name);

--Przykład 1 - ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM slobodzian.porto_ndvi;

--Przykład 2 - ST_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM slobodzian.porto_ndvi;

--Przykład 3 - Zapisywanie danych na dysku za pomocą dużego obiektu (large object,lo)
CREATE TABLE slobodzian.tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM slobodzian.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'D:\myraster.tiff') --> Save the file in a place
--where the user postgres have access. In windows a flash drive usualy works
--fine.
FROM slobodzian.tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM slobodzian.tmp_out; --> Delete the large object.

