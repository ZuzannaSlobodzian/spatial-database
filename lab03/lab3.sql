--1. Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana pomiędzy 2018 a 2019).
SELECT b19.* INTO change FROM t2019_kar_buildings b19
LEFT OUTER JOIN t2018_kar_buildings b18 ON b18.polygon_id = b19.polygon_id
WHERE b18.height != b19.height 
OR ST_Equals(b18.geom, b19.geom) = FALSE 
OR b18.polygon_id IS NULL;


--2. Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub wybudowanych budynków, 
--które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.
WITH tempPoiTable AS(
SELECT * FROM t2019_kar_poi_table p19
	WHERE NOT EXISTS(SELECT * FROM t2018_kar_poi_table p18 WHERE p18.poi_id = p19.poi_id)

);
SELECT p19.type, COUNT(p19.type) FROM t2019_kar_poi_table p19, tempPoiTable tempP
WHERE ST_Within(p19.geom, ST_Buffer(tempP.geom, 500))
GROUP BY p19.type;

--3. Utwórz nową tabelę o nazwie ‘streets_reprojected’, 
--która zawierać będzie dane z tabeli T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassin
SELECT * INTO streets_reprojected FROM T2019_KAR_STREETS
UPDATE streets_reprojected
SET geom = ST_Transform(ST_SetSRID(geom, 4326), 3068)

--4. Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej. 
--Użyj następujących współrzędnych:
CREATE TABLE input_points(
	id INT,
	geom GEOMETRY
);
INSERT INTO input_points VALUES(0, ST_GeomFromText('POINT(8.36093 49.03174)', 4326));
INSERT INTO input_points VALUES(1, ST_GeomFromText('POINT(8.36093 49.03174)', 4326));

--5. Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych DHDN.Berlin/Cassini. 
--Wyświetl współrzędne za pomocą funkcji ST_AsText().
UPDATE input_points
SET geom = ST_Transform(geom, 3068);
SELECT ST_AsText(geom) FROM input_points
SELECT ST_SRID(geom) FROM input_points

--6. Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii
--zbudowanej z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. 
--Dokonaj reprojekcji geometrii, aby była zgodna z resztą tabel.
SELECT * FROM t2019_kar_street_node
WHERE ST_Contains(ST_Buffer(ST_Transform(ST_ShortestLine((SELECT geom FROM input_points WHERE id=0),
													   (SELECT geom FROM input_points WHERE id=1))
							,4326)
				  ,200)		  
	  ,geom)

--7.Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs)
--znajduje się w odległości 300 m od parków (LAND_USE_A).
SELECT COUNT(DISTINCT(p19.*)) FROM t2019_kar_poi_table p19, t2019_kar_land_use_a lu
WHERE p19.type = 'Sporting Goods Store'
AND lu.type = 'Park (City/County)'
AND ST_Contains(ST_Buffer(lu.geom, 300), p19.geom)

--8. Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). 
--Zapisz znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’.
SELECT DISTINCT(ST_Intersection(r.geom, wl.geom)) INTO t2019_KAR_BRIDGES 
FROM t2019_kar_railways r, t2019_kar_water_lines wl