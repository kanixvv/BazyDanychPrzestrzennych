create table obiekty (id int primary key, nazwa varchar(15), geom geometry);

insert into obiekty values
    (1, 'obiekt1', ST_GeomFromEWKT('CompoundCurve
                                   (LineString(0 1, 1 1), 
                                    CircularString(1 1, 2 0, 3 1), 
                                    CircularString(3 1, 4 2, 5 1), 
                                    LineString(5 1, 6 1))')),
    (2, 'obiekt2', ST_GeomFromEWKT('CurvePolygon
                                   (CompoundCurve(LineString(10 6, 14 6), 
                                                  CircularString(14 6, 16 4, 14 2), 
                                                  CircularString(14 2, 12 0, 10 2), 
                                                  LineString(10 2, 10 6)), 
                                    CircularString(11 2, 13 2, 11 2))')), -- okrąg
    (3, 'obiekt3', ST_GeomFromEWKT('CompoundCurve(LineString(10 17, 12 13), 
								  				  LineString(12 13, 7 15), 
                                  				  LineString(7 15, 10 17))')),
	(4, 'obiekt4', ST_GeomFromEWKT('MultiLineString((20 20, 25 25), (25 25, 27 24), (27 24, 25 22), 
								   (25 22, 26 21), (26 21, 22 19), (22 19, 20.5 19.5))')),
	(5, 'obiekt5', ST_GeomFromEWKT('MultiPoint(30 30 59, 38 32 234)')),
    (6, 'obiekt6', ST_GeomFromEWKT('GeometryCollection(LineString(1 1, 3 2), Point(4 2))'));

-- 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej
-- obiekt 3 i 4.

select ST_Area(ST_Buffer(ST_ShortestLine(
    (select geom from obiekty where nazwa='obiekt3'), 
    (select geom from obiekty where nazwa='obiekt4')), 5));

-- 2. Zamień obiekt 4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te warunki.
-- 			>>>>Obiekt musi być linią zamkniętą i nie może być wielolinią; 
--			>>>>jeśli do stworzenia użyto 'MultiLineString', to potrzeba 'ST_MakePolygon'
update obiekty
set geom = ST_MakePolygon(ST_LineMerge(ST_Collect(geom, 'LineString(20.5 19.5, 20 20)'))) 
where nazwa='obiekt4';

-- 3. W tabeli obiekty jako obiekt7 zapisz obiekt złożony z obiekt3 i obiekt4.

insert into obiekty values 
    (7, 'obiekt7', ST_Union(
        (select geom from obiekty where nazwa = 'obiekt3'), 
        (select geom from obiekty where nazwa = 'obiekt4')));
select * from obiekty;

-- 4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów 
-- nie zawierających łuków.

select sum(ST_Area(ST_Buffer(geom, 5))) 
from obiekty 
where not ST_Hasarc(geom);
							