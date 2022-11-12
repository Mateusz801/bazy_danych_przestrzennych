CREATE TABLE obiekty ("nazwa" VARCHAR(10), "geom" GEOMETRY)
DROP TABLE obiekty
INSERT INTO obiekty VALUES ('obiekt1',
							ST_GeomFromEWKT(
								'COMPOUNDCURVE( (0 1, 1 1),
								CIRCULARSTRING(1 1, 2 0, 3 1),
								CIRCULARSTRING(3 1, 4 2, 5 1),
								(5 1, 6 1))'));

INSERT INTO obiekty VALUES ('obiekt2',
	ST_GeomFromEWKT('CURVEPOLYGON(
					COMPOUNDCURVE(
					CIRCULARSTRING(14 6, 16 4, 14 2),
					CIRCULARSTRING(14 2, 12 0, 10 2),
					(10 2, 10 6, 14 6)),
					CIRCULARSTRING(11 2, 13 2, 11 2))'));
							
INSERT INTO obiekty VALUES ('obiekt3', ST_GeomFromEwkt('TRIANGLE((7 15, 10 17, 12 13, 7 15))'));
INSERT INTO obiekty VALUES ('obiekt4', ST_GeomFromEWKT('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)'));
INSERT INTO obiekty VALUES ('obiekt5', ST_GeomFromEWKT('MULTIPOINT( (30 30 59), (38 32 234))'));
INSERT INTO obiekty VALUES ('obiekt6', ST_GeomFromEWKT('GEOMETRYCOLLECTION( LINESTRING(1 1, 3 2), POINT(4 2))'));

		
--1. Pole bufora o wielkości 5, utworzonego wokół najkrótszej linii między obiektem 3 i 4
SELECT ST_Area(ST_Buffer(ST_ShortestLine(
	(SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'),
	(SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')),
						 5));
						 
--2. Zamiana 4 na poligon
SELECT ST_MakePolygon( (SELECT geom FROM obiekty WHERE nazwa = 'obiekt4'))
-- lwpoly_from_lwlines: shell must be closed

UPDATE obiekty 
SET geom = ST_MakePolygon(ST_AddPoint(geom, ST_StartPoint(geom)))
WHERE nazwa = 'obiekt4';

SELECT geom FROM obiekty WHERE nazwa = 'obiekt4';

--3. obiekt7 jako połączenie obiektu 3 i 4
INSERT INTO obiekty
VALUES('obiekt7',
	   ST_Union((SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'),
				(SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')));
				
SELECT geom FROM obiekty WHERE nazwa = 'obiekt7';


--4. Pole buforów o wielkości 5 utworzonych wokół obiektów bez łuków
WITH non_arc (nazwa, geom)
AS 
(
	SELECT nazwa, geom
	FROM obiekty
	WHERE ST_HasArc(geom) = false
)
SELECT nazwa, ST_Area(ST_Buffer(geom, 5)) AS pole_bufora
FROM non_arc;
