-- 2. 
CREATE TABLE kania.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

-- dodanie serial primary key
alter table kania.intersects
add column rid SERIAL PRIMARY KEY;

-- utworzenie indeksu przestrzennego
CREATE INDEX idx_intersects_rast_gist ON kania.intersects
USING gist (ST_ConvexHull(rast));

-- dodanie raster constraints:
-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('kania'::name,
'intersects'::name,'rast'::name);

select * from kania.intersects
order by rid asc limit 50

-- Przykład 2 - ST_Clip. Obcinanie rastra na podstawie wektora.
CREATE TABLE kania.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

select * from kania.clip
limit 50

--Przykład 3 - ST_Union. Połączenie wielu kafelków w jeden raster.
CREATE TABLE kania.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

select * from kania.union
limit 50

-- Przykład 1 - ST_AsRaster - użycie funkcji ST_AsRaster w celu rastrowania tabeli z 
-- parafiami o takiej samej charakterystyce przestrzennej tj.: wielkość piksela, zakresy itp.
CREATE TABLE kania.porto_parishes AS
WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

select * from kania.porto_parishes
limit 50

-- połączenie rekordów z poprzedniego przykładu przy użyciu funkcji ST_UNION w pojedynczy raster.
DROP TABLE kania.porto_parishes; --> drop table porto_parishes first

CREATE TABLE kania.porto_parishes AS
WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


-- Przykład 3 - ST_Tile. Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile.
DROP TABLE kania.porto_parishes; --> drop table porto_parishes first

CREATE TABLE kania.porto_parishes AS
WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


-- Konwertowanie rastrów na wektory (wektoryzowanie)

-- Przykład 1 - ST_Intersection
CREATE TABLE kania.intersection as
SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

select * from kania.intersection
limit 50

-- ST_DumpAsPolygons konwertuje rastry w wektory (poligony).
CREATE TABLE kania.dumppolygons AS
SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

select * from kania.dumppolygons
limit 50

-- Analiza rastrów

-- Funkcja ST_Band służy do wyodrębniania pasm z rastra
CREATE TABLE kania.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

select * from kania.landsat_nir
limit 50

-- wycięcie jednej parafii z tabeli vectors.porto_parishes. 
CREATE TABLE kania.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

select * from kania.paranhos_dem
limit 50

-- generowanie nachylenia przy użyciu poprzednio wygenerowanej tabeli (wzniesienie).
CREATE TABLE kania.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM kania.paranhos_dem AS a;

select * from kania.paranhos_slope
limit 50

-- Preklasyfikacja rastra
CREATE TABLE kania.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3', '32BF',0)
FROM kania.paranhos_slope AS a;

select * from kania.paranhos_slope_reclass
limit 50

-- Pobliczenie statystyk rastra dla kafelka
SELECT st_summarystats(a.rast) AS stats
FROM kania.paranhos_dem AS a;

-- obliczenie jednej statystyki wybranego rastra.
SELECT st_summarystats(ST_Union(a.rast))
FROM kania.paranhos_dem AS a;

-- lepsza kontrola złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM kania.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

-- wyswietlenie statystyki dla każdego poligonu "parish" z użyciem GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;


-- wyodrębnienie wartości piksela z punktu lub zestawu punktów.
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

-- Topographic Position Index (TPI)

-- obliczanie TPI
CREATE TABLE kania.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a; 

-- Poniższa kwerenda utworzy indeks przestrzenny:
CREATE INDEX idx_tpi30_rast_gist ON kania.tpi30S
-- Dodanie constraintów:
SELECT AddRasterConstraints('kania'::name,
'tpi30'::name,'rast'::name);

-- ZADANIE Tworzenie tabeli tpi30 dla obszaru gminy Porto - ograniczenie czasu wykonywania
CREATE TABLE kania.tpi30_porto AS
SELECT ST_TPI(a.rast, 1) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS p
WHERE ST_Intersects(a.rast, p.geom) AND p.municipality ILIKE 'porto'; 

-- Poniższa kwerenda utworzy indeks przestrzenny:
CREATE INDEX idx_tpi30_rast_gist1 ON kania.tpi30_porto
USING gist (ST_ConvexHull(rast));
-- Dodanie constraintów:
SELECT AddRasterConstraints('kania'::name,
'tpi30_porto'::name,'rast'::name);

-- Algebra map

-- Przykład 1 - Wyrażenie Algebry Map
CREATE TABLE kania.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast))
SELECT r.rid,ST_MapAlgebra(r.rast, 1, r.rast, 4, '([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF') AS rast
FROM r;



-- Utworzenie indeksu przestrzennego na wcześniej stworzonej tabeli:
CREATE INDEX idx_porto_ndvi_rast_gist ON kania.porto_ndvi
USING gist (ST_ConvexHull(rast));

-- Dodanie constraintów:
SELECT AddRasterConstraints('kania'::name,
'porto_ndvi'::name,'rast'::name);

select * from kania.porto_ndvi2
limit 50


-- Przykład 2 – Funkcja zwrotna
CREATE OR REPLACE FUNCTION kania.ndvi(
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

-- W kwerendzie algebry map należy/można wywołać zdefiniowaną wcześniej funkcję:
CREATE TABLE kania.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT r.rid,ST_MapAlgebra(r.rast, ARRAY[1,4], 'kania.ndvi(double precision[],
integer[],text[])'::regprocedure, --> function!
'32BF'::text) AS rast
FROM r;

-- Dodanie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi2_rast_gist ON kania.porto_ndvi2
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('kania'::name,
'porto_ndvi2'::name,'rast'::name);
