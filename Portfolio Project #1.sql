--https://ourworldindata.org/covid-deaths
-- Download the data set excel files and use it when running the SQL instructions below

Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

-- Select Data that we are going to using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths

-- cast function turns a string variable into either an int or float value type
-- Where location will filter the location column for names that contain States
-- shows likelihoof of dying if you contract covid in your country
Select Location, date, total_cases,total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
--Where continent is not null
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
Select Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
-- Where location like '%states%'
order by 1,2


-- Looking at Countries with Highest Infection Rate compared to Population
-- desc function allows to sort data or result in a descending order
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
-- Where Location like '%states%'
Group by Location, Population
order by PercentPopulationINfected desc


-- Showing Countries with Highest Death Count per Population
-- int numeric value without decimal

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
-- Where location like '%states%'
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- Show Continents with total death counts
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by totalDeathCount desc

-- Global numbers
Select Location, date, total_cases, total_deaths, (cast(total_deaths as int)/(cast(total_cases as float)))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null
order by 1,2

Select date, SUM((new_cases)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE SUM(CAST(new_deaths as int)) / (SUM(new_cases) * 100.0)
END as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null
Group By date
order by 1,2

--Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From PortfolioProject..CovidDeaths
--Where location like '%states%'
--where continent is not null
--Group By date
--order by 1,2

-- Total population vs vaccinations 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
ISNULL(SUM(cast(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.Date), 0) as RollingPeopleVaccinated,
-- (RollingPeopleVaccinated/population)*100
CASE
	WHEN dea.population = 0 THEN 0
	ELSE (ISNULL(SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date), 0)*100.0) / dea.population
		END AS VaccinationPercentage
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
	--On dea.location = vac.location
	--and dea.date = vac.date
where dea.continent is not null
--order by 2,3
order by dea.location, dea.date

--use CTE
With PopvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
COALESCE(SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location,
dea.Date), 0) AS RollingPeopleVaccinated
  --(RollingPeopleVaccinated/Population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
where dea.continent is not null
--order by 2,3
--order by dea.location, dea.date
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
COALESCE(SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location,
dea.Date), 0) AS RollingPeopleVaccinated
  --(RollingPeopleVaccinated/Population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
-- where dea.continent is not null
--order by 2,3
--order by dea.location, dea.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
COALESCE(SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location,
dea.Date), 0) AS RollingPeopleVaccinated
  --(RollingPeopleVaccinated/Population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
where dea.continent is not null
--order by 2,3
--order by dea.location, dea.date

Select *
From PercentPopulationVaccinated
