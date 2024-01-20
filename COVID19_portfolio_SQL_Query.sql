/*
COVID 19 Data Exploration

Skills used: Subquery, Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Data exploration on mortality due to Covid infection

SELECT *
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

--Select Data that we are going to be starting with

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
--Shows the likelihood of dying if you contract Covid (we narrow the data to localization in Ukraine)

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
--Shows what percentage of the population infected with Covid

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

--Countries with the Highest Infection Rate compared to Population

SELECT 
	location
	, population
	, MAX(total_cases)                                AS HighestInfectionCount
	, ROUND(MAX((total_cases/population))*100, 2)     AS PercentPopultionInfected
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

--Ïåðø³ êðà¿íè, ùî çàô³êñóâàëè âèïàäêè ³íô³êóâàííÿ Covid 
--(Äàòè, â ÿê³ êðà¿íàìè áóëî ðåïîðòîâàíî ïðî ïåðø³ âèïàäêè ³íô³êóâàííÿ Covid)

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

--Êðà¿íè ç íàéâèùèì ðàõóíêîì ñìåðòåé ç ïðè÷èíè çàðàæåííÿ Covid

SELECT 
	location
	, MAX(CONVERT(int, total_deaths))                  AS TotalDeathCount
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

--------------------BREAKING THINGS DOWN BY CONTINENT--------------------

--Äåìîíñòðóº çàãàëüíó ê³ëüê³ñòü ñìåðòåé â ìåæàõ êîíòèíåíòó
--(Êîíòèíåíòè ç çàô³êñîâàíîþ ê³ëüê³ñòþ ñìåðòåé â³ä Covid â ïîðÿäêó ñïàäàííÿ)

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

----Äîäàìî äî ðåçóëüòàòó çàïèòó çàãàëüíó ê³ëüê³ñòü ñìåðòåé ³ âèâåäåìî â³äñîòîê, ÿêèé â³äïîâ³äàòèìå äàíèì ïî êîíòèíåíòàõ
--(Âèêîðèñòîâ³ºìî CTE äëÿ ðîçðàõóíêó)

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
--(Ñï³ââ³äíîøåííÿ äàíèõ çàðàæåííÿ òà ñìåðòíîñò³ çà äíÿìè)

SELECT 
	date
	, SUM(total_cases)                                                  AS total_cases_in_the_world
	, SUM(cast(total_deaths as int))                                    AS total_deaths_in_the_world
	, ROUND((SUM(cast(total_deaths as int))/SUM(total_cases))*100, 2)   AS DeathPercentage              --(ñï³ââ³äíîøåííÿ)     --in whole world per day
--	, SUM(cast(new_deaths as int))                                      AS new_deaths_per_day
--	, ROUND((SUM(cast(new_deaths as int))/SUM(total_cases))*100, 2)     AS WorldWideDeathPercentagePerDay
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

--Äí³, â ÿê³ áóëî çàô³êñîâàíî íàéá³ëüøå ÷èñëî ñìåðòåé ç ïðè÷èíè Ñovid ïî ñâ³òó

SELECT 
	date
	, SUM(cast(new_deaths as int))total_new_deaths
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 2 DESC

-- Çàãàëüíà ê³ëüê³ñòü çàõâîð³ëèõ òà ïîìåðëèõ ïî ñâ³òó

SELECT 
	SUM(new_cases)                                                     AS total_new_cases
	, SUM(cast(new_deaths as int))                                     AS total_new_deaths
	, ROUND((SUM(cast(new_deaths as int))/SUM(new_cases))*100, 2)      AS DeathPercentage
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL                   --áåç çàðåºñòðîâàíèõ 22.01.2020 (áî ¿õ íå â³äíåñëè â ñïèñîê íîâèõ íàäõîäæåíü àáî íîâèõ ñìåðòåé)


--(Âèêîðèñòîâ³ºìî CTE äëÿ ðîçðàõóíêó)

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
                                                           --ç çàðåºñòðîâàíèìè äàíèìè çà 22.01.2020
													

------------------------------Population vs Vaccinations------------------------------

--Äîºäíóºìî äëÿ äîñë³äæåííÿ äàí³ ç òàáëèö³ âàêöèíàö³¿

SELECT *
FROM COVID_project..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3, 4

--Çàãàëüíà ê³ëüê³ñòü ïðîâåäåííÿ âàêöèíóâàííÿ â ñâ³ò³ çà äåíü

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

--Ñê³ëüêè âàêöèíàö³é áóëî çä³éñíåíî êîæíîãî äíÿ â ìåæàõ êðà¿í

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

--Â³äñîòêîâå ñï³ââ³äíîøåííÿ íàñåëåííÿ òà çä³éñíåíèõ âàêöèíàö³é â³ä Covid
--(Âèêîðèñòîâ³ºìî CTE äëÿ ðîçðàõóíêó)

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

--(Âèêîðèñòîâóºìî Temp_Table äëÿ ðîçðàõóíêó) 

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

--Íàéá³ëüø³ ïîêàçíèêè â³äñîòêó íàñåëåííÿ, ùî ïðîéøîâ ïîâíó âàêöèíàö³þ, ñåðåä êðà¿í

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
