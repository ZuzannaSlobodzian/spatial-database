--4. Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty)
--położonych w odległości mniejszej niż 1000 jednostek od głównych rzek. Budynki spełniające to
--kryterium zapisz do osobnej tabeli tableB.

SELECT p.gid, p.cat, p.f_codedesc, p.f_code, p.type, p.geom INTO tableB FROM popp p, majrivers mr
WHERE f_codedesc = 'Building'
AND ST_Contains(ST_Buffer(mr.geom, 1000), p.geom)


--5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
--geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.

CREATE TABLE airportsNew(
	name VARCHAR(100),
	geom GEOMETRY,
	elev INT);
	
INSERT INTO airportsNew(name, geom, elev)
SELECT name, geom, elev
FROM airports

--a)Znajdź lotnisko, które położone jest najbardziej na zachód
SELECT * FROM airportsNew
ORDER BY ST_Y(geom) ASC LIMIT 1

--a)Znajdź lotnisko, które położone jest najbardziej na wschód
SELECT * FROM airportsNew
ORDER BY ST_Y(geom) DESC LIMIT 1

--b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
--środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. 
INSERT INTO airportsNew Values('AirportB', 
				  ST_Centroid( ST_ShortestLine((SELECT geom FROM airportsNew ORDER BY ST_Y(geom) ASC LIMIT 1), 
				  (SELECT geom FROM airportsNew ORDER BY ST_Y(geom) DESC LIMIT 1))), 
				  44);
				  

--6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
--linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”
SELECT ST_Area(ST_Buffer((SELECT ST_ShortestLine((SELECT geom FROM lakes
				  WHERE names = 'Iliamna Lake'), 
				  (SELECT geom FROM airports
				  WHERE name = 'AMBLER'))), 1000));
				  
				  
--7. Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
--poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).

SELECT tr.vegdesc, SUM(ST_Area(tr.geom)) FROM tundra tn, swamp sp, trees tr
WHERE ST_CoveredBy(tr.geom, tn.geom) OR ST_CoveredBy(tr.geom, sp.geom)
GROUP BY tr.vegdesc
