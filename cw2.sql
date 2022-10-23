--4. Liczba budynkow w odleglosci < 1000 od glownych rzek (tabela popp, atrybut f_codedesc)
SELECT * FROM popp;
SELECT * FROM rivers;

DROP TABLE tableb;

SELECT p.gid, p.cat, p.f_codedesc, p.f_code, p.type, p.geom
INTO tableB
FROM popp p, rivers r
WHERE p.f_codedesc = 'Building'
AND ST_Distance(r.geom, p.geom) < 1000;

SELECT * FROM tableB;

--5.
SELECT * FROM airports;

--prolog
SELECT name, geom, elev
INTO airportsNew
FROM airports;

SELECT * FROM airportsNew;

--a) Lotnisko najbardziej na zachód i na wschód
SELECT name, ST_AsText(geom)
FROM airports
WHERE ST_X(ST_AsText(geom)) = (SELECT MIN(ST_X(ST_AsText(geom))) FROM airports)
--ATKA

SELECT name, ST_AsText(geom)
FROM airports
WHERE ST_X(ST_AsText(geom)) = (SELECT MAX(ST_X(ST_AsText(geom))) FROM airports)
--ANNETTE ISLAND

--b) Lotnisko pomiêdzy western a eastern
INSERT INTO airportsnew
VALUES('airbortB', 
	   (ST_LineInterpolatePoint(ST_MakeLine(
		   (SELECT geom FROM airportsnew WHERE name = 'ATKA'),
		   (SELECT geom FROM airportsnew WHERE name = 'ANNETTE ISLAND')),
	   0.5)),
	  45);

SELECT name, ST_AsText(geom) FROM airportsnew


--6. Pole oddalone o mniej ni¿ 1000 od najkrótszej linii ³¹cz¹cej jeziora Iliamna Lake i lotniska AMBLER
SELECT * FROM lakes;
SELECT * FROM alaska;

SELECT SUM(area_mi)
FROM alaska al
WHERE ST_DWithin(al.geom,
				 (SELECT ST_ShortestLine( 
					 (SELECT geom FROM lakes WHERE names = 'Iliamna Lake'),
					 (SELECT geom FROM airports WHERE name = 'AMBLER'))), 1000);


--7. Suma pól powierzchni poligonów typów drzew na obszarze tundry i bagien.
SELECT * FROM swamp;
SELECT * FROM tundra;
SELECT * FROM trees;

SELECT DISTINCT tr.vegdesc, SUM(ST_Area(tr.geom)) FROM trees tr, swamp s, tundra tu
WHERE ST_Contains(tr.geom, s.geom)
OR ST_Contains(tr.geom, tu.geom)
GROUP BY tr.vegdesc;

SELECT DISTINCT tr.vegdesc, SUM(tr.area_km2) FROM trees tr, swamp s, tundra tu
WHERE ST_Contains(tr.geom, s.geom)
OR ST_Contains(tr.geom, tu.geom)
GROUP BY tr.vegdesc;
