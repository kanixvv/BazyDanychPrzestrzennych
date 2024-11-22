--zad 1
select matchid, player
from gole
WHERE teamid = 'POL';

--zad 2
select *
from mecze
where id = 1004;

--zad 3
select g.player, g.teamid, m.stadium, m.mdate
from mecze as m
join gole as g on m.id = g.matchid
where g.teamid = 'POL';

--zad 4
select m.team1, m.team2, g.player
from mecze as m
join gole as g ON id = matchid
where g.player like 'Mario%';

--zad 5
select g.player, g.teamid,  d.coach, g.gtime
from gole as g
join druzyny as d on g.teamid = d.id
where g.gtime <= 10;

--zad 6
select d.teamname, m.mdate 
from druzyny as d 
join gole as g on d.id = g.teamid 
join mecze as m on g.matchid = m.id 
where d.coach = 'Franciszek Smuda';

--zad 7
select distinct g.player
from gole as g
join mecze as m on g.matchid = m.id
where m.stadium = 'National Stadium, Warsaw';

--zad 8
select  g.player, g.gtime
from mecze as m
join gole as g ON g.matchid = m.id
where (m.team1 = 'GER' OR m.team2 = 'GER') AND g.teamid != 'GER';

--zad 9
select d.teamname, count(g.*) as goals
from druzyny as d
join gole as g on d.id = g.teamid
group by d.teamname
order by goals desc;

--zad 10
select m.stadium, count(g.*) as goals
from mecze as m
join gole g on m.id = g.matchid
group by m.stadium
order by goals desc;