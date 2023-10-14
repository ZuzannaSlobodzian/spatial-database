CREATE DATABASE plan;
CREATE EXTENSION postgis;

CREATE TABLE budynki(
	id CHAR(2),
	geometria GEOMETRY,
	nazwa CHAR(9)
);

CREATE TABLE drogi(
	id CHAR(2),
	geometria GEOMETRY,
	nazwa CHAR(5)
);

CREATE TABLE punkty_informacyjne(
	id CHAR(2),
	geometria GEOMETRY,
	nazwa CHAR(1)
);

INSERT INTO budynki VALUES('01', ST_GeomFromText('POLYGON((10.5 4,10.5 1.5,8 1.5,8 4,10.5 4))', -1), 'BuildingA');
INSERT INTO budynki VALUES('02', ST_GeomFromText('POLYGON((6 7,6 5,4 5,4 7,6 7))', -1), 'BuildingB');
INSERT INTO budynki VALUES('03', ST_GeomFromText('POLYGON((5 8,5 6,3 6,3 8,5 8))', -1), 'BuildingC');
INSERT INTO budynki VALUES('04', ST_GeomFromText('POLYGON((10 9,10 8,9 8,9 9,10 9))', -1), 'BuildingD');
INSERT INTO budynki VALUES('05', ST_GeomFromText('POLYGON((2 2,2 1,1 1,1 2,2 2))', -1), 'BuildingF');

INSERT INTO drogi VALUES('01', ST_GeomFromText('LINESTRING(0 4.5,12 4.5)', -1), 'RoadX');
INSERT INTO drogi VALUES('02', ST_GeomFromText('LINESTRING(7.5 0,7.5 10.5)', -1), 'RoadY');

INSERT INTO punkty_informacyjne VALUES('01', ST_GeomFromText('POINT(1 3.5)', -1), 'G');
INSERT INTO punkty_informacyjne VALUES('02', ST_GeomFromText('POINT(5.5 1.5)', -1), 'H');
INSERT INTO punkty_informacyjne VALUES('03', ST_GeomFromText('POINT(9.5 6)', -1), 'I');
INSERT INTO punkty_informacyjne VALUES('04', ST_GeomFromText('POINT(6.5 6)', -1), 'J');
INSERT INTO punkty_informacyjne VALUES('05', ST_GeomFromText('POINT(6 9.5)', -1), 'K');

SELECT SUM(ST_Length(geometria)) FROM drogi;

SELECT ST_AsText(geometria), ST_Area(geometria), ST_Perimeter(geometria) FROM budynki
WHERE nazwa = 'BuildingA';

SELECT nazwa, ST_Area(geometria) FROM budynki
ORDER BY nazwa ASC;

SELECT nazwa, ST_Perimeter(geometria) FROM budynki
ORDER BY ST_Area(geometria) DESC LIMIT 2;

SELECT ST_Distance((SELECT geometria FROM budynki
				  WHERE nazwa = 'BuildingC'), 
				  (SELECT geometria FROM punkty_informacyjne
				  WHERE nazwa = 'G'));
				  
SELECT ST_Area(ST_Difference((SELECT geometria FROM budynki 
							 WHERE nazwa = 'BuildingC'),
							 (SELECT ST_buffer(geometria, 0.5) FROM budynki
							 WHERE nazwa = 'BuildingB')));
							 
SELECT nazwa FROM budynki
WHERE ST_Y(ST_Centroid(geometria)) > (SELECT ST_Y(ST_StartPoint(geometria)) FROM drogi WHERE nazwa = 'RoadX');

SELECT ST_Area(ST_SymDifference((SELECT geometria FROM budynki 
								WHERE nazwa = 'BuildingC'),
			   					ST_GeomFromText('POLYGON((4 7,6 7,6 8,4 8,4 7))', -1)));






