--1. Wybudowane lub wyremontowane budynki
SELECT * FROM t2018_kar_buildings
SELECT * FROM t2019_kar_buildings

SELECT build.geom
INTO new_buildings
FROM t2019_kar_buildings build
WHERE build.geom
NOT IN (SELECT b19.geom
		FROM t2018_kar_buildings b18
		JOIN t2019_kar_buildings b19 
		ON b18.geom = b19.geom);

SELECT * FROM new_buildings

--2. Policz wg kategorii ile POI w promienu 500m od rzeczy z 1.
SELECT * FROM t2019_kar_poi_table;

SELECT poi.geom
INTO new_poi
FROM t2019_kar_poi_table poi
WHERE poi.geom
NOT IN (SELECT poi19.geom
		FROM t2018_kar_poi_table poi18
		JOIN t2019_kar_poi_table poi19 
		ON poi18.geom = poi19.geom);
		
SELECT * FROM new_poi;


SELECT COUNT(DISTINCT poi.geom)
FROM new_poi poi, new_buildings build
WHERE ST_DWITHIN(poi.geom,
				build.geom,
				500)

--3. Transformacja
SELECT * FROM t2019_kar_streets;

SELECT gid, ST_Transform(geom, 3068) AS transormed
INTO streets_reprojected
FROM t2019_kar_streets;

SELECT * FROM streets_reprojected;

--4. Nowe punkty
CREATE TABLE input_points (
	id INTEGER NOT NULL PRIMARY KEY,
	geom GEOMETRY);
	
INSERT INTO input_points VALUES (1, ST_GeomFromText('POINT(8.36093 49.03174)', 4326));
INSERT INTO input_points VALUES (2, ST_GeomFromText('POINT(8.39876 49.00644)', 4326));

SELECT * FROM input_points;

--5. UPDATE
UPDATE input_points
SET geom = ST_Transform(geom, 3068);

SELECT ST_AsText(geom)
FROM input_points;

--6. Skrzyżowania 200m od nowej linii
SELECT * 
FROM t2019_kar_street_node;

UPDATE input_points
SET geom = ST_Transform(geom, 4326);

SELECT ST_AsText(geom)
FROM input_points;

SELECT *
FROM t2019_kar_street_node
WHERE "intersect" = 'Y'
AND ST_DWithin( ST_MakeLine(
		(SELECT geom FROM input_points WHERE id=1),
		(SELECT geom FROM input_points WHERE id=2)),
				 ST_Transform(geom,3068),
				 200);
	
--7.

SELECT COUNT(DISTINCT poi.geom)
FROM t2019_kar_poi_table poi, t2019_kar_land_use_a land
WHERE poi."type" = 'Sporting Goods Store'
AND land."type" = 'Park (City/County)'
AND ST_DWithin( poi.geom,
				land.geom,
				300) 

--8.
SELECT * FROM t2019_kar_railways;
SELECT * FROM t2019_kar_water_lines;

SELECT DISTINCT ST_Intersection(rail.geom, water.geom) AS bridges
INTO T2019_KAR_BRIDGES
FROM t2019_kar_railways rail, t2019_kar_water_lines water;

SELECT * FROM t2019_kar_bridges