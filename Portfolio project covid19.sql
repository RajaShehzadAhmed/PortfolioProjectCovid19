
---------------------- Looking at total cases, and population vs deaths---------------------------------------------------------
Select 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population,
	(total_deaths/total_cases)*100 AS death_percentage_by_cases, 
	(total_deaths/population)*100 AS death_percentage_by_population
From PortfolioProject.dbo.covid_deaths
WHERE location like '%india%'
Order by 1,2

----------------------- Looking at countries with highest infection rate vs population----------------------------------------------

Select 
	location, 
	max(total_cases) as highest_infection_count, 
	population,
	max((total_cases/population))*100 AS death_percentage_by_population
From PortfolioProject.dbo.covid_deaths
Group by location, population
Order by death_percentage_by_population desc

---------------------------- Showing countries with highest death count----------------------------------------------------------

Select 
	location,
	continent,
	max(cast(total_deaths as int)) as total_death_count
From PortfolioProject.dbo.covid_deaths
Where continent is NOT NULL
Group by location, continent
Order by total_death_count desc


------------------------------- Showing continents with highest death count-----------------------------------------------------------

Select 
	continent,
	max(cast(total_deaths as int)) as total_death_count
From PortfolioProject.dbo.covid_deaths
Where continent is NOT NULL
Group by continent
Order by total_death_count desc

------------------------------------- Global Numbers---------------------------------------------------------------------

Select
	--date,
	sum(New_cases) as Total_cases,
	sum(cast(New_deaths as int)) as Total_deaths,
	sum(cast(New_deaths as int))/sum(New_cases)*100 as death_percentage_by_cases
From PortfolioProject.dbo.covid_deaths
Where continent is NOT NULL
--Group by date
Order by 1,2

--- ----------------------------------Looking at total population vs vaccinations---------------------------------------------------------------------

Select dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) over (partition by dea.location Order by dea.location, dea.date) as rolling_sum_vac
From PortfolioProject.dbo.covid_deaths dea
Join PortfolioProject.dbo.covid_vaccinations vac
	on dea.location = vac.location
	AND
	dea.date = vac.date
Where dea.continent is NOT NULL -- AND dea.location like '%canada%' AND vac.new_vaccinations is NOT NULL
Order by 2,3

-- --------------------------------------Use of CTE in above query-------------------------------------------------

/*CTE stands for Common Table Expression in SQL. It is a temporary result set that can be referenced within a SELECT, INSERT, UPDATE, or DELETE statement*/

with PopvsVac (continent, location, date, population, new_vaccinations,rolling_sum_vac)

AS
(
Select 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) over (partition by dea.location Order by dea.location, dea.date) as rolling_sum_vac
From 
	PortfolioProject.dbo.covid_deaths dea
Join 
	PortfolioProject.dbo.covid_vaccinations vac
ON 
	dea.location = vac.location
	AND
	dea.date = vac.date
Where 
	dea.continent is NOT NULL -- AND dea.location like '%canada%' AND vac.new_vaccinations is NOT NULL
-- Order by 2,3
)

Select *,  (rolling_sum_vac/population)*100 as vac_pop_percntg
From PopvsVac

---------------------------------------Temporary table------------------------------------------

Drop Table if exists #percentpopulationvaccinated
	Create table #percentpopulationvaccinated

		(
		continent nvarchar(255),
		location nvarchar(255),
		date datetime,
		population numeric,
		new_vaccinations numeric,
		rolling_sum_vac numeric
		)

	insert into #percentpopulationvaccinated

		Select 
			dea.continent, 
			dea.location,
			dea.date,
			cast(dea.population as numeric),
			cast(vac.new_vaccinations as numeric),
			0 -- Its a jugaad, because the calculated column was not getting inserted, i inserted 0 initially and later used the update command below
		From 
			PortfolioProject.dbo.covid_deaths dea
		Join 
			PortfolioProject.dbo.covid_vaccinations vac
		ON 
			dea.location = vac.location
			AND
			dea.date = vac.date
		Where 
			dea.continent is NOT NULL
	
	Update #percentpopulationvaccinated
		SET #percentpopulationvaccinated.rolling_sum_vac = 
		(
			Select
				sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) AS rolling_sum_vac
			From
				PortfolioProject.dbo.covid_vaccinations vac
				JOIN 
				PortfolioProject.dbo.covid_deaths dea
				ON
				dea.location = vac.location
				AND
				dea.date = vac.date
			WHERE dea.continent is NOT NULL
			AND #percentpopulationvaccinated.location = dea.location
			AND #percentpopulationvaccinated.date = dea.date
		)
	
	 Select *
	From #percentpopulationvaccinated

	--------------------------------------Creating view to store data for later visualization------------------

	Create view percentpopulationvaccinated as
	Select 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) over (partition by dea.location Order by dea.location, dea.date) as rolling_sum_vac
	From 
	PortfolioProject.dbo.covid_deaths dea
	Join 
	PortfolioProject.dbo.covid_vaccinations vac
	ON 
	dea.location = vac.location
	AND
	dea.date = vac.date
	Where 
	dea.continent is NOT NULL -- AND dea.location like '%canada%' AND vac.new_vaccinations is NOT NULL
	-- Order by 2,3

	Select * 
	From percentpopulationvaccinated