--Tworzenie rastrów z istniejących rastrów i interakcja z wektorami
--1. Przecięcie rastra z wektorem
CREATE TABLE "Mati".intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ILIKE 'porto';

--1.1. dodanie serial primary key
ALTER TABLE "Mati".intersects
ADD COLUMN rid SERIAL PRIMARY KEY;

--2.1. utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON "Mati".intersects
USING gist (ST_ConvexHull(rast));

--3.1. schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('Mati'::name,
'intersects'::name,'rast'::name);

SELECT * FROM "Mati".intersects;


--2. Obcinanie rastra na podstawie wektora
CREATE TABLE "Mati".clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality LIKE 'PORTO';

SELECT * FROM "Mati".clip;


--3. Połączenie wielu kafelków w jeden raster.
CREATE TABLE "Mati".union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

SELECT * FROM "Mati".union;


--Tworzenie rastrów z wektorów (rastrowanie)
--1. Rastrowanie tabeli z parafiami o takiej samej charakterystyce przestrzennej tj.: wielkość piksela, zakresy itp.
DROP TABLE "Mati".porto_parishes;
CREATE TABLE "Mati".porto_parishes AS
WITH r AS 
(
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--Przykładowe zapytanie używa piksela typu '8BUI' tworząc 8-bitową nieoznaczoną liczbę całkowitą (8-
--bit unsigned integer).

--2. Drugi przykład łączy rekordy z poprzedniego przykładu przy użyciu funkcji ST_UNION w pojedynczy
--raster.
DROP TABLE "Mati".porto_parishes;
CREATE TABLE "Mati".porto_parishes AS
WITH r AS 
(
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ILIKE 'porto';

SELECT * FROM "Mati".porto_parishes

--3. Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile.
DROP TABLE "Mati".porto_parishes; --> drop table porto_parishes first
CREATE TABLE "Mati".porto_parishes AS
WITH r AS 
(
	SELECT rast FROM rasters.dem
	LIMIT 1 
)
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


--Konwertowanie rastrów na wektory (wektoryzowanie)
--1. Funkcja St_Intersection jest podobna do ST_Clip. ST_Clip zwraca raster, a ST_Intersection zwraca
--zestaw par wartości geometria-piksel, ponieważ ta funkcja przekształca raster w wektor przed
--rzeczywistym „klipem”.
CREATE TABLE "Mati".intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--2. ST_DumpAsPolygons konwertuje rastry w wektory (poligony).
CREATE TABLE "Mati".dumppolygons AS
SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--Analiza rastrów
--1. Funkcja ST_Band służy do wyodrębniania pasm z rastra
CREATE TABLE "Mati".landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat;

--2. ST_Clip może być użyty do wycięcia rastra z innego rastra
CREATE TABLE "Mati".paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--3. Poniższy przykład użycia funkcji ST_Slope wygeneruje nachylenie przy użyciu
--poprzednio wygenerowanej tabeli (wzniesienie).
CREATE TABLE "Mati".paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM "Mati".paranhos_dem AS a;

--4. Aby zreklasyfikować raster należy użyć funkcji ST_Reclass.
CREATE TABLE "Mati".paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM "Mati".paranhos_slope AS a;

--5. Aby obliczyć statystyki rastra można użyć funkcji ST_SummaryStats. Tutaj dla kafelka
SELECT st_summarystats(a.rast) AS stats
FROM "Mati".paranhos_dem AS a;

--6. Przy użyciu UNION można wygenerować jedną statystykę wybranego rastra.
SELECT st_summarystats(ST_Union(a.rast))
FROM "Mati".paranhos_dem AS a;

--7. ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS 
(
	SELECT st_summarystats(ST_Union(a.rast)) AS stats
	FROM "Mati".paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--8. ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
	SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
	b.geom,true))) AS stats
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
	GROUP BY b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--9. Funkcja ST_Value pozwala wyodrębnić wartość piksela z punktu lub zestawu punktów.
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

--10. Topographic Position Index (TPI)
-- Funkcja ST_Value pozwala na utworzenie mapy TPI z DEM wysokości.
CREATE TABLE "Mati".tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON "Mati".tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('Mati'::name,
'tpi30'::name,'rast'::name);

CREATE TABLE "Mati".tpi30_porto AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

CREATE INDEX idx_tpi30_porto_rast_gist ON "Mati".tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('Mati'::name,
'tpi30_porto'::name,'rast'::name);


--Algebra map
--1. Wyrażenie Algebry Map
CREATE TABLE "Mati".porto_ndvi AS
WITH r AS 
(
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT r.rid,ST_MapAlgebra(
	r.rast, 1,
	r.rast, 4,
	'([rast2.val] - [rast1.val]) / ([rast2.val] +
	[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON "Mati".porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('Mati'::name,
'porto_ndvi'::name,'rast'::name);

--2. Funkcja zwrotna
--Tworzenie funkcji
CREATE OR REPLACE FUNCTION "Mati".ndvi(
	VALUE double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug
--purposes
	RETURN (VALUE [2][1][1] - VALUE [1][1][1])/(VALUE [2][1][1]+VALUE
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

--Kweredna algebry mapy z wywołaniem funkcji
CREATE TABLE "Mati".porto_ndvi2 AS
WITH r AS 
(
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT r.rid,ST_MapAlgebra(
	r.rast, ARRAY[1,4],
	'"Mati".ndvi(double precision[],
	integer[],text[])'::regprocedure, --> This is the function!
	'32BF'::text
	) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON "Mati".porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('Mati'::name,
'porto_ndvi2'::name,'rast'::name);


--3. Funkcje TPI 





--Eksport danych
--1. Funkcja ST_AsTiff tworzy dane wyjściowe jako binarną reprezentację pliku tiff
SELECT ST_AsTiff(ST_Union(rast))
FROM "Mati".porto_ndvi;

--2. ST_AsGDALRaster nie zapisuje danych wyjściowych bezpośrednio
--na dysku, natomiast dane wyjściowe są reprezentacją binarną dowolnego formatu GDAL.
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM "Mati".porto_ndvi;

--3. Zapisywanie danych na dysku za pomocą dużego obiektu (large object,lo)
DROP TABLE tmp_out;
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
					 ST_AsGDALRaster(ST_Union(rast), 'GTiff', 
									 ARRAY['COMPRESS=DEFLATE',
										   'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM "Mati".porto_ndvi;

SELECT lo_export(loid, 'C:\Users\Mateusz\Desktop\Nauka\Materialy_studia\Semestr_5\Bazy_danych_przestrzenncyh\cw6\myraster.tiff') --> Save the file in a place
--where the user postgres have access. In windows a flash drive usualy works
--fine.
FROM tmp_out;

SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

