/*
COVID 19 Data Exploration

Skills used: Subquery, Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--��������� ���� ������� ��������� ��������� �������� ��������� Covid

SELECT *
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

--������� ������� �����, � ����� � ���������� ������ ���������

SELECT 
	location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

--Total Cases vs Total Deaths
--��������� ���������� �����, ��� �������� COVID. ������� ���� �� ���������� � ������

SELECT 
	location
	, date
	, total_cases
	, total_deaths
	, ROUND((total_deaths/total_cases)*100, 2)        AS DeathPercentage
FROM COVID_project..CovidDeaths
WHERE
	location LIKE 'Uk%' 
	AND continent IS NOT NULL
ORDER BY 1, 2


--Total Cases vs Population
--��������� ������� ���������, �� ������ ��������� Covid

SELECT 
	location
	, date
	, population
	, total_cases
	, ROUND((total_cases/population)*100, 2)          AS PercentPopultionInfected
FROM COVID_project..CovidDeaths
--WHERE location LIKE 'Uk%'
WHERE continent IS NOT NULL
ORDER BY 1, 2

--����� � �������� ���������� ����������� ������� ������� ���������

SELECT 
	location
	, population
	, MAX(total_cases)                                AS HighestInfectionCount
	, ROUND(MAX((total_cases/population))*100, 2)     AS PercentPopultionInfected
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

--����� �����, �� ����������� ������� ����������� Covid 
--(����, � �� ������� ���� ����������� ��� ����� ������� ����������� Covid)

SELECT 
	continent
	, location
	, MIN(date)
	, MIN(total_cases)
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
HAVING MIN(total_cases) IS NOT NULL
ORDER BY 3

--����� � �������� �������� ������� � ������� ��������� Covid

SELECT 
	location
	, MAX(CONVERT(int, total_deaths))                  AS TotalDeathCount
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

--------------------BREAKING THINGS DOWN BY CONTINENT--------------------

--��������� �������� ������� ������� � ����� ����������
--(���������� � ������������ ������� ������� �� Covid � ������� ��������)

SELECT 
	tdc.continent
	, SUM(tdc.TotalDeathCount)                                AS TotalDeathPerContinentCount
FROM (  SELECT 
			continent
			, location
			, MAX(cast(total_deaths as int))                  AS TotalDeathCount
		FROM COVID_project..CovidDeaths
		WHERE continent IS NOT NULL
		GROUP BY continent, location  ) tdc
GROUP BY tdc.continent
Order By 2 DESC

----������ �� ���������� ������ �������� ������� ������� � �������� �������, ���� ����������� ����� �� �����������
--(���������⳺�� CTE ��� ����������)

WITH CTE_TotalDeathContinent AS 
(
	SELECT 
		tdc.continent                                             AS Continent
		, SUM(tdc.TotalDeathCount)                                AS TotalDeathPerContinentCount
	FROM (  SELECT 
				continent
				, location
				, MAX(cast(total_deaths as int))                  AS TotalDeathCount
			FROM COVID_project..CovidDeaths
			WHERE continent IS NOT NULL
			GROUP BY continent, location  ) tdc
	GROUP BY tdc.continent 
)
SELECT 
	*
	, SUM(TotalDeathPerContinentCount) OVER()                                                     AS TotalCovidDeath
	, cast(TotalDeathPerContinentCount as float)*100/Sum(TotalDeathPerContinentCount) OVER ()     AS PercentageOfTotalNumber
FROM CTE_TotalDeathContinent
ORDER BY 2 DESC



------------------------------GLOBAL NUMBERS------------------------------

--Total Cases per Day in the World VS Total Deaths per Day in the World
--(������������ ����� ��������� �� ��������� �� �����)

SELECT 
	date
	, SUM(total_cases)                                                  AS total_cases_in_the_world
	, SUM(cast(total_deaths as int))                                    AS total_deaths_in_the_world
	, ROUND((SUM(cast(total_deaths as int))/SUM(total_cases))*100, 2)   AS DeathPercentage              --(������������)     --in whole world per day
--	, SUM(cast(new_deaths as int))                                      AS new_deaths_per_day
--	, ROUND((SUM(cast(new_deaths as int))/SUM(total_cases))*100, 2)     AS WorldWideDeathPercentagePerDay
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

--���, � �� ���� ����������� �������� ����� ������� � ������� �ovid �� ����

SELECT 
	date
	, SUM(cast(new_deaths as int))total_new_deaths
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 2 DESC

-- �������� ������� ��������� �� �������� �� ����

SELECT 
	SUM(new_cases)                                                     AS total_new_cases
	, SUM(cast(new_deaths as int))                                     AS total_new_deaths
	, ROUND((SUM(cast(new_deaths as int))/SUM(new_cases))*100, 2)      AS DeathPercentage
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL                   --��� ������������� 22.01.2020 (�� �� �� ������� � ������ ����� ���������� ��� ����� �������)


--(���������⳺�� CTE ��� ����������)

WITH CTE_cases_deaths AS
(
	SELECT 
		(
			SELECT 
				SUM(total_cases)                                   AS sum_total_cases
			From COVID_project..CovidDeaths
			WHERE continent is not null
				AND date = '2020-01-22'
			GROUP BY date
		) + SUM(new_cases)                                         AS total_new_cases
		, 
		(
			SELECT 
				SUM(cast(total_deaths as int))                     AS sum_total_deaths
			From COVID_project..CovidDeaths
			WHERE continent is not null
				AND date = '2020-01-22'
			GROUP BY date
		) + SUM(cast(new_deaths as int))                           AS total_new_deaths 
	FROM COVID_project..CovidDeaths
	WHERE continent IS NOT NULL
)
SELECT 
	*
	, ROUND((total_new_deaths /total_new_cases)*100, 2)            AS DeathPercentage
FROM CTE_cases_deaths
                                                           --� �������������� ������ �� 22.01.2020
													

------------------------------Population vs Vaccinations------------------------------

--������� ��� ���������� ���� � ������� ����������

SELECT *
FROM COVID_project..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3, 4

--�������� ������� ���������� ������������ � ��� �� ����

SELECT                                             
--	death.continent, death.location,                 
	death.date
	, SUM(cast(new_vaccinations as int))           
FROM COVID_project..CovidDeaths death              
JOIN COVID_project..CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
GROUP BY death.date
ORDER BY 1

--������ ���������� ���� �������� ������� ��� � ����� ����

SELECT 
	death.continent
	, death.location
	, death.date
	, new_vaccinations
FROM COVID_project..CovidDeaths death              
JOIN COVID_project..CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2, 3

--³�������� ������������ ��������� �� ��������� ���������� �� Covid
--(���������⳺�� CTE ��� ����������)

WITH CTE_running_totals_of_vaccinations AS
(
	SELECT 
		death.continent
		, death.location
		, death.date
		, death.population
		, vac.new_vaccinations
		, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.date)         AS RollingVaccinations
	FROM COVID_project..CovidDeaths death                                           
	JOIN COVID_project..CovidVaccinations vac                                         
		ON death.location = vac.location
		AND death.date = vac.date
	WHERE death.continent IS NOT NULL                                                --running total of new vaccinations per country
	--ORDER BY 2,3
)
SELECT 
	continent
	, location
	, MAX(date)                                                                        AS last_time_data_was_reseaved
	, MAX(population)                                                                  AS population
	, MAX(RollingVaccinations)                                                         AS total_vacinaccions_were_performed_by_that_time 
	, ROUND((MAX(RollingVaccinations)/MAX(population))*100,2)                          AS PercentageOfVacinnationMade  
FROM CTE_running_totals_of_vaccinations
GROUP BY continent, location
ORDER BY 2 

--(������������� Temp_Table ��� ����������) 

DROP TABLE IF EXISTS #temp

CREATE TABLE #temp
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population int,
	New_vaccinations int,
	RollingVaccinations int
)

INSERT INTO #temp
SELECT 
	death.continent
	, death.location
	, death.date
	, cast(death.population as int)
	, cast(vac.new_vaccinations as int)
	, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.date) AS RollingVaccinations
FROM COVID_project..CovidDeaths death                                           
JOIN COVID_project..CovidVaccinations vac                                        
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not null                                                
--ORDER BY 2,3

SELECT 
	Continent
	, Location
	, MAX(Date)                                                                                    AS last_time_data_was_reseaved
	, MAX(Population)                                                                              AS population
	, MAX(RollingVaccinations)                                                                     AS total_vacinaccions_were_performed_by_that_time 
	, ROUND((cast(MAX(RollingVaccinations) as float)/MAX(Population))*100,2)                       AS PercentageOfVacinnationMade 
FROM #temp
GROUP BY Continent, Location
ORDER BY 2

--�������� ��������� ������� ���������, �� ������� ����� ����������, ����� ����

SELECT                                             
	death.continent
	, death.location
	, MAX(population)                                                                AS population
	, MAX(CONVERT(int,people_fully_vaccinated))                                      AS PeopleFullyVaccinatedCount
	, ROUND(MAX(CONVERT(int,people_fully_vaccinated))/ MAX(population)*100,2)        AS PercentageVaccinatedPeople
FROM COVID_project..CovidDeaths death              
JOIN COVID_project..CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
--AND people_fully_vaccinated IS NOT NULL
GROUP BY death.continent, death.location
ORDER BY 5 DESC

----------------------------------------------------------------------------------------------------

---------------------Creating View to store data for later visualizations---------------------------

CREATE VIEW PercentPopulationVaccinations AS
SELECT 
	death.continent
	, death.location
	, death.date
	, death.population
	, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY death.location ORDER BY death.date) AS RollingVaccinations
FROM COVID_project..CovidDeaths death                                           
JOIN COVID_project..CovidVaccinations vac                                        
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not null                                                
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinations