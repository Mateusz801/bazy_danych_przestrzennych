--raster2pgsql.exe -s 27700 -N -32767 -t 100x100 -I -C -M -d 
--"D:\BDP\ras250_gb\data\*.tif" rasters.uk_250k 
--| psql -d ex6 -h localhost -U postgres -p 5432

SELECT * FROM rasters.uk_250k;

CREATE TABLE public.union AS
SELECT ST_Union(rast) 
FROM rasters.uk_250k;


SELECT ST_AsTiff(rast)
FROM rasters.union;

--wektor -> geometria -> poligony na linie ->zapisz warstwê tymczasow¹ jako PostgreSQL SQL Dump

SELECT * FROM vectors.granice_parkow;

CREATE TABLE vectors.lake_district AS
SELECT * FROM vectors.granice_parkow
WHERE id = 1;

SELECT * FROM vectors.lake_district;

CREATE TABLE rasters.uk_lake_district AS
SELECT ST_Clip(a.rast, b.wkb_geometry, true) AS raster
FROM rasters.uk_250k AS a, vectors.lake_district AS b
WHERE ST_Intersects(a.rast, b.wkb_geometry)


DROP TABLE tmp_out;
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
					 ST_AsGDALRaster(ST_Union(raster), 'GTiff', 
									 ARRAY['COMPRESS=DEFLATE',
										   'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM "rasters".uk_lake_district;

SELECT lo_export(loid, 'E:\uk_lake_district.tiff')
FROM tmp_out;

--wgranie do QGIS, raster -> rozne -> połącz
-- CREATE TABLE NDWI_layer AS
-- WITH NDWI (rast) AS
-- (
-- 	SELECT ( (b8a.rast - b11.rast) / (b8a.rast + b11.rast))
-- 	FROM b8a, b11
-- )
-- SELECT ST_clip(NDWI.rast, b.wkb_geometry) 
-- FROM NDWI, granice_parkow b
-- WHERE b.id = 1;

SELECT * FROM rasters.ndwi;

CREATE TABLE rasters.ndwi_clip AS
SELECT ST_Clip(a.rast, b.wkb_geometry, true) AS raster
FROM rasters.ndwi AS a, vectors.lake_district AS b
WHERE ST_Intersects(a.rast, b.wkb_geometry);

DROP TABLE tmp_out;
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
					 ST_AsGDALRaster(ST_Union(raster), 'GTiff', 
									 ARRAY['COMPRESS=DEFLATE',
										   'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM "rasters".ndwi_clip;

SELECT lo_export(loid, 'E:\ndwi.tiff')
FROM tmp_out;