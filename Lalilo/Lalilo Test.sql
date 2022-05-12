--1) For a given district, we want to know for each class the number of students and the total number of exercises done:

--Number of Students per District
--Lets look at the "districts"

SELECT SUBSTRING(u.email, '@.*$') as dom, COUNT(SUBSTRING(u.email, '@.*$')) as Frequency
FROM users u
GROUP BY dom
ORDER BY Frequency DESC;

--Too many generic emails, lets try making a view to have a school to email relationship, this could give us more districts as it will give us the
--school email used if we have at least one teacher who did not use aol/hotmail/gmail

CREATE VIEW school_district AS SELECT DISTINCT(grp.id), grp.dom FROM (SELECT sch.id, SUBSTRING(u.email, '@(?!(aol|gmail|hotmail)).*$') as dom
FROM users u
LEFT JOIN school sch
ON u.schoolid = sch.id
WHERE SUBSTRING(u.email, '@(?!(aol|gmail|hotmail)).*$') IS NOT NULL) AS grp
ORDER BY grp.id;

--Upon reading the data we see that some school ids have multiple emails

SELECT id, dom FROM school_district where id = 98;

--Therefore this is something that needs further investigation so lets just do our matching via teacher emails as this matching table I made will give us duplicates
--and unfortunately give us incorrect info when joining.

--Number of Students per district

SELECT SUBSTRING(u.email, '@(?!(aol|gmail|hotmail)).*$')  as dom, COUNT(SUBSTRING(u.email, '@(?!(aol|gmail|hotmail)).*$'))
FROM student st
LEFT JOIN class cl
ON st.classid = cl.id
LEFT JOIN users u
ON cl.teacherid = u.id
GROUP BY dom
HAVING SUBSTRING(u.email, '@(?!(aol|gmail|hotmail)).*$') IS NOT NULL;

--Number of exercises per District

SELECT SUBSTRING(u.email, '@(?!(aol|gmail|hotmail)).*$')  as dom, COUNT(SUBSTRING(u.email, '@(?!(aol|gmail|hotmail)).*$'))
FROM student_trace tr
LEFT JOIN student st
ON st.id = tr.studentid
LEFT JOIN class cl
ON st.classid = cl.id
LEFT JOIN users u
ON cl.teacherid = u.id
GROUP BY dom
HAVING SUBSTRING(u.email, '@(?!(aol|gmail|hotmail)).*$') IS NOT NULL;

--2) For a given week, for each school, the number of active teachers, the number of active students, and the number of teacher signups of the week

--Number of active students per year, week per school

SELECT date_part('year', tr.createdat) as year,
	   date_part('week', tr.createdat) as week,
	   cl.schoolid schid,
	   COUNT(DISTINCT(tr.studentid)) as Frequency
FROM student_trace tr
LEFT JOIN student st
ON tr.studentid = st.id
LEFT JOIN class cl
ON st.classid = cl.id
GROUP BY year, week, schid
ORDER BY year, week, schid;

--Number of active teachers per year, week, per school

SELECT date_part('year', tr.createdat) as year,
	   date_part('week', tr.createdat) as week,
	   cl.schoolid as schid,
	   COUNT(DISTINCT(u.id)) as Frequency
FROM student_trace tr
LEFT JOIN student st
ON tr.studentid = st.id
LEFT JOIN class cl
ON st.classid = cl.id
LEFT JOIN users u
ON cl.teacherid = u.id
GROUP BY year, week, schid
ORDER BY year, week, schid;

--Number of teacher signups per year, week and school

SELECT date_part('year', u.createdat) as year,
	   date_part('week', u.createdat) as week,
	   cl.schoolid as schid,
	   COUNT(DISTINCT(u.id)) as Frequency
FROM student_trace tr
LEFT JOIN student st
ON tr.studentid = st.id
LEFT JOIN class cl
ON st.classid = cl.id
LEFT JOIN users u
ON cl.teacherid = u.id
GROUP BY year, week, schid
ORDER BY year, week, schid;


--Analysis part

--Aggregate all the information above to build a leaderboard of schools that are most likely to buy Lalilo

--I didn't have time to make a leaderboard but here is what my idea would have been:
--For a service to be bought we should look at its activity by number of students as well as number of teacher accounts being created.
--We could create a scoring formula to see which schools are more likely to buy the product.
--Expected Activity Metric = Average exercises done per student per week*(1 + Average number of teachers signing up per week)
--The pros of this formula is it isn't affected too much by the number of students per class, but there are a few cons I will discuss later.


-- To your mind, what defines "a good district"?

--A good district is one which consistently uses the product, thus we are looking for a consistent number of execrises done per student every week. We should be wary of using mean as a metric for this
--it is possible some schools use it exclusively while others don't. We should look at the distributions before making any hasty conclusions on the district.
--Looking at the clusters is also important to recognize that some schools could be larger than others and sway the distributions heavily.
--A metric worth looking into could be Median number of exercises done per student every week for each district.

--What could we do to improve this leaderboard?

--This formula has its flaws. The main flaw is the Average number of teachers signing up per week. That variable can quickly become very low the longer we track a school
--and/or when the maximum number of teachers available is reached and little to no new signups occur. The second flaw is that there are going to be weeks where students are on holidays
--and will not have homework, thus scoring may get impacted by that. Maybe using a formula based on quarters or months in a year could be more beneficial and reduce variance.
