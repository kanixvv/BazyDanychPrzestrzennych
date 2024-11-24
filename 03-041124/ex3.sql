--1. Budynki wybudowane lub wyremontowane na przestrzeni roku (2018/2019)
select count (*) from t2018_kar_buildings;

create view budynki as (
	select b19.*
	from t2018_kar_buildings as b18
	right join t2019_kar_buildings as b19
	on b18.polygon_id = b19.polygon_id
	where ST_Equals(b18.geom, b19.geom) != TRUE OR b18.polygon_id = NULL
);

select * from budynki;

--2. Ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub wybudowanych budynków (z 1 zad) wg. kategorii
create table new_poi as
select poi19.*
from t2018_kar_poi_table as poi18
right join t2019_kar_poi_table as poi19
on poi18.poi_id = poi19.poi_id
where poi18.poi_id IS NULL;

select count(distinct(np.*)), np.type
from new_poi as np, budynki as b
where ST_DWithin(b.geom, np.geom, 500)
group by np.type;

--3. Nowa tabela z danymi z tabeli streets, przetransformowanymi do układu współrzędnych DHDN.Berlin/Cassini
create table streets_reprojected as
select gid, link_id, st_name, ref_in_id, nref_in_id, func_class, speed_cat, fr_speed_l, to_speed_l, dir_travel,
ST_Transform(geom, 3068) as reprojected_geometry
from t2019_kar_streets;

--4. Nowa tabela input_points z dwoma rekordami o geometrii punktowej
create table input_points(
	id int NOT NULL,
	geom geometry);

insert into input_points values
	(1, 'point(8.36093 49.03174)'),
	(2, 'point(8.39876 49.00644)');

--5. Zaktualizowanie danych w tej tabeli, by były one w ukł współrzędnych DHDN.Berlin/Cassini
update input_points set geom = ST_SetSRID(geom, 3068);
select ST_AsText(geom) from input_points;

--6. Wszystkie skrzyżowania, które znajdują się w odległości 200m od linii zbudowanej z punktów  wtabeli input_points
-- z wykorzystaniem tabeli street_node; reprojekcja geometrii z resztą tabel
update input_points set geom = ST_SetSRID(geom, 4326); --ujednolicenie ukladu do obliczen

select * 
from t2019_kar_street_node as node19
where ST_Contains(
        ST_Buffer(
          ST_Shortestline(
            (select geom from input_points where id=1), 
            (select geom from input_points where id=2)
          ), 200
        ), node19.geom)
and node19.intersect = 'Y';

--7. Ilość sklepów sportowych (tab. pois) w odległości 300m od praków (tab. land_use_a)
select count (*) 
from (
    select distinct pt.* 
    from t2019_kar_poi_table as pt, t2019_kar_land_use_a as lu
    where pt.type = 'Sporting Goods Store' 
    and ST_Intersects(ST_Buffer(lu.geom, 300), pt.geom)
);

--8. Punkty przecięcia torów kolejowych (railways) i ciekami (water_lines) w osobnej tabeli
create table t2019_kar_bridges as
select distinct ST_Intersection(rail.geom, water.geom) as bridges
from t2019_kar_railways as rail, t2019_kar_water_lines as water;

select * from t2019_kar_bridges
