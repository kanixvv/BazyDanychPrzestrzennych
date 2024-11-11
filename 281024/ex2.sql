create extension postgis;

create table buildings(id int primary key not null, geometry geometry, name varchar(20)); 
create table roads(id int primary key not null, geometry geometry, name varchar(20)); 
create table poi(id int primary key not null, geometry geometry, name varchar(20)); 

/* select *, st_astex(geometry) from roads 

insert into roads (id, name, geometry) values
(1, 'RoadX', 'LINESTRING(0 4.5, 12 4.5)'),
(2, 'RoadY', 'LINESTRING(7.5 10.5, 7.5 0)'); */

--5. Współrzędne obiektów oraz nazwy odczytane z mapki, układ współrzędnych niezdefiniowany.
insert into buildings values  
	(1, ST_GeomFromText('polygon((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))'), 'BuildingA'), 
	(2, ST_GeomFromText('polygon((4 7, 6 7, 6 5, 4 5, 4 7))'), 'BuildingB'),
	(3, ST_GeomFromText('polygon((3 8, 5 8, 5 6, 3 6, 3 8))'), 'BuildingC'),
	(4, ST_GeomFromText('polygon((9 9, 10 9, 10 8, 9 8, 9 9))'), 'BuildingD'),
	(5, ST_GeomFromText('polygon((1 2, 2 2, 2 1, 1 1, 1 2))'), 'BuildingE');
	
insert into roads values 
	(1, ST_GeomFromText('linestring(0 4.5, 12 4.5)'), 'RoadX'), 
	(2, ST_GeomFromText('linestring(7.5 10.5, 7.5 0)'), 'RoadY');
	
insert into poi values 
	(1, ST_GeomFromText('point(1 3.5)'), 'G'), 
	(2, ST_GeomFromText('point(5.5 1.5)'), 'H'),
	(3, ST_GeomFromText('point(9.5 6)'), 'I'),
	(4, ST_GeomFromText('point(6.5 6)'), 'J'),
	(5, ST_GeomFromText('point(6 9.5)'), 'K');
	
--6.
--a. Całkowita długość dróg w analizowanym mieście
select sum(st_length(geometry)) from roads;

--b. Wypisz geometrie (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA
select ST_AsText(geometry) as WKT, ST_Area(geometry) as polePowierzchni, ST_Perimeter(geometry) as obwod from buildings
where name='BuildingA';

--c. Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie
select name, ST_Area(geometry) from buildings 
order by name asc; 

--d. Wypisz nazwy i obwody 2 budynków o największej powierzchni
select name, ST_Perimeter(geometry) from buildings
order by ST_Area(geometry) desc limit 2;

--e. Wyznacz najkrószą odległość między budynkiem BuildingC a punktem K
select ST_Distance(b.geometry, p.geometry) 
from buildings b
join poi p on true
where b.name = 'BuildingC' and p.name = 'K';

--f. Wypisz pole powierzchni tej częsci budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB.
select ST_Area(
	ST_Difference(
		geometry, 
		ST_Buffer((select geometry from buildings where name = 'BuildingB'), 0.5))) 
from buildings 
where name = 'BuildingC';

--g. Wybierz te budynki, któych centroid znajduje się powyżej drogi o nazwie RoadX.
select * from buildings b 
join roads r on true
where (ST_Y(ST_Centroid(b.geometry))) > (ST_Y(ST_Centroid(r.geometry))) and r.name='RoadX'

--h. Oblicz pole powierzchni tych cześci budynku BuildingC i poligonu o  współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów
select ST_Area(ST_SymDifference(geometry, st_geomfromtext('polygon((4 7, 6 7, 6 8, 4 8, 4 7))'))) from buildings 
where name = 'BuildingC';

