/*
COVID 19 Data Exploration

Skills used: Subquery, Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Досліджуємо дані відносно фіксованої смертності внаслідок зараження Covid

SELECT *
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

--Обираємо колонки даних, з якими в подальшому будемо працювати

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
--Демонструє ймовірність смерті, при заражені COVID. Звужуємо дані до локалізації в Україні

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
--Демонструє відсоток населення, що зазнав інфікації Covid

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

--Країни з найвищим показником інфікування відносно кількості населення

SELECT 
	location
	, population
	, MAX(total_cases)                                AS HighestInfectionCount
	, ROUND(MAX((total_cases/population))*100, 2)     AS PercentPopultionInfected
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

--Перші країни, що зафіксували випадки інфікування Covid 
--(Дати, в які країнами було репортовано про перші випадки інфікування Covid)

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

--Країни з найвищим рахунком смертей з причини зараження Covid

SELECT 
	location
	, MAX(CONVERT(int, total_deaths))                  AS TotalDeathCount
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

--------------------BREAKING THINGS DOWN BY CONTINENT--------------------

--Демонструє загальну кількість смертей в межах континенту
--(Континенти з зафіксованою кількістю смертей від Covid в порядку спадання)

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

----Додамо до результату запиту загальну кількість смертей і виведемо відсоток, який відповідатиме даним по континентах
--(Використовіємо CTE для розрахунку)

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
--(Співвідношення даних зараження та смертності за днями)

SELECT 
	date
	, SUM(total_cases)                                                  AS total_cases_in_the_world
	, SUM(cast(total_deaths as int))                                    AS total_deaths_in_the_world
	, ROUND((SUM(cast(total_deaths as int))/SUM(total_cases))*100, 2)   AS DeathPercentage              --(співвідношення)     --in whole world per day
--	, SUM(cast(new_deaths as int))                                      AS new_deaths_per_day
--	, ROUND((SUM(cast(new_deaths as int))/SUM(total_cases))*100, 2)     AS WorldWideDeathPercentagePerDay
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

--Дні, в які було зафіксовано найбільше число смертей з причини Сovid по світу

SELECT 
	date
	, SUM(cast(new_deaths as int))total_new_deaths
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 2 DESC

-- Загальна кількість захворілих та померлих по світу

SELECT 
	SUM(new_cases)                                                     AS total_new_cases
	, SUM(cast(new_deaths as int))                                     AS total_new_deaths
	, ROUND((SUM(cast(new_deaths as int))/SUM(new_cases))*100, 2)      AS DeathPercentage
FROM COVID_project..CovidDeaths
WHERE continent IS NOT NULL                   --без зареєстрованих 22.01.2020 (бо їх не віднесли в список нових надходжень або нових смертей)


--(Використовіємо CTE для розрахунку)

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
                                                           --з зареєстрованими даними за 22.01.2020
													

------------------------------Population vs Vaccinations------------------------------

--Доєднуємо для дослідження дані з таблиці вакцинації

SELECT *
FROM COVID_project..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3, 4

--Загальна кількість проведення вакцинування в світі за день

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

--Скільки вакцинацій було здійснено кожного дня в межах країн

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

--Відсоткове співвідношення населення та здійснених вакцинацій від Covid
--(Використовіємо CTE для розрахунку)

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

--(Використовуємо Temp_Table для розрахунку) 

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

--Найбільші показники відсотку населення, що пройшов повну вакцинацію, серед країн

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