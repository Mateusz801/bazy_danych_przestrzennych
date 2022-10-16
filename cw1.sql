CREATE EXTENSION postgis;

CREATE TABLE buildings (
	id INTEGER NOT NULL PRIMARY KEY,
	geom GEOMETRY,
	name VARCHAR(10),
	height INTEGER);

INSERT INTO buildings VALUES (0, ST_GeomFromText('POLYGON((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))'), 'BuildingA', 0);
INSERT INTO buildings VALUES (1, ST_GeomFromText('POLYGON((4 5, 6 5, 6 7, 4 7, 4 5))'), 'BuildingB', 0);
INSERT INTO buildings VALUES (2, ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))'), 'BuildingC', 0);
INSERT INTO buildings VALUES (3, ST_GeomFromText('POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))'), 'BuildingD', 0);
INSERT INTO buildings VALUES (4, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))'), 'BuildingF', 0);

SELECT * FROM buildings;
-----------------------
CREATE TABLE roads (
	id INTEGER NOT NULL PRIMARY KEY,
	geom GEOMETRY,
	name VARCHAR(10));

INSERT INTO roads VALUES (0, St_GeomFromText('LINESTRING(0 4.5, 12 4.5)'), 'RoadX');
INSERT INTO roads VALUES (1, St_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)'), 'RoadY');

SELECT * FROM roads;
----------------------
CREATE TABLE pktinfo (
	id INTEGER NOT NULL PRIMARY KEY,
	geom GEOMETRY,
	name VARCHAR(2),
	liczprac INTEGER);

INSERT INTO pktinfo VALUES (0, St_GeomFromText('POINT(1 3.5)'), 'G', 5);
INSERT INTO pktinfo VALUES (1, St_GeomFromText('POINT(5.5 1.5)'), 'H', 3);
INSERT INTO pktinfo VALUES (2, St_GeomFromText('POINT(9.5 6)'), 'I', 8);
INSERT INTO pktinfo VALUES (3, St_GeomFromText('POINT(6.5 6)'), 'J', 2);
INSERT INTO pktinfo VALUES (4, St_GeomFromText('POINT(6 9.5)'), 'K', 3);

SELECT * FROM pktinfo;

--1. Calkowita dlugosc drog
SELECT SUM(ST_Length(geom)) FROM roads;


--2. Wypisanie
SELECT ST_AsText(geom) AS wkt, ST_Area(geom) AS area, ST_Perimeter(geom) AS perimeter 
FROM buildings
WHERE name='BuildingA';


--3. Nazwy i pola budynkow alfabetycznie
SELECT name, ST_Area(geom) AS Area
FROM buildings
ORDER BY name;


--4. Nazwy i obwody budynkow o najwiekszej powierzchni
SELECT name, ST_Perimeter(geom) AS perimeter
FROM buildings
ORDER BY ST_Area(geom) DESC
LIMIT 2;


--5. Najkrotsza odleglosc miedzy budynkiem C a punktem G
SELECT CAST(ST_Distance(b.geom, p.geom) AS DECIMAL(5, 2)) AS Distance
FROM buildings b, pktinfo p
WHERE b.name = 'BuildingC' AND p.name = 'G';

SELECT b.geom, p.geom, ST_ShortestLine(b.geom, p.geom) AS ShortestLine
FROM buildings b, pktinfo p
WHERE b.name = 'BuildingC' AND p.name = 'G';


--6. Pole budynku C znajdujace sie w odlegloscici > 0.5 od budynku B
WITH CteBuffers (buffer, source_name)
AS
(
	SELECT ST_Buffer(geom, 0.5), name
	FROM buildings
	WHERE name = 'BuildingB'
)
SELECT * INTO buffers FROM CteBuffers;

SELECT * FROM buffers;

SELECT b.name, CAST(ST_Area(ST_Difference(b.geom, buff.buffer)) AS DECIMAL(5,2)) 
FROM buildings b, buffers buff
WHERE b.name = 'BuildingC'

--7. Centroid budynku powyżej drogi X
SELECT b.name
FROM buildings b, roads r
WHERE r.name ='RoadX'
AND ST_Y(ST_Centroid(b.geom)) > ST_Y(ST_StartPoint(r.geom))
AND ST_Y(ST_Centroid(b.geom)) > ST_Y(ST_EndPoint(r.geom)); 


--8. Pole niewspolnych czesci budynku C i poligonu
SELECT ST_Area(ST_Difference(geom, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')))
FROM buildings
WHERE name='BuildingC'
