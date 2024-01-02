Select *
From Portfolio_Project.dbo.covid_death_data
Order by 3,4

Select *
From Portfolio_Project.dbo.covid_vaccination
Order by 3,4

--Selection of data we gonna work with

Select location, date, total_cases, new_cases, total_deaths, population_density
From Portfolio_Project.dbo.covid_death_data	
order by 1,2

--looking at Total Cases vs Total Deaths
-- also changing datatype of totalcases and total_deaths from nvarchar to numeric to get out percentage
-- this calculation shows likelihood of dying if contacted with covid in your country

Select *, (total_deaths/total_cases)* 100 as death_percentage 
From (select location, date, cast(total_cases as numeric) as total_cases, cast(total_deaths as numeric) as total_deaths
from Portfolio_Project.dbo.covid_death_data) as converted_datatype
where location like '%United Kingdom%'
order by 1,2

--looking at total cases vs population
-- showing what percentage of population got covid

Select *, (total_cases/ population)* 100 as covid_percentage
From (select location, date, cast(total_cases as numeric) as total_cases, population
from Portfolio_Project.dbo.covid_death_data) as converted_datatype
where location like '%United Kingdom%'
order by 1,2

-- looking at highest population rate per country

Select location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/ population)) * 100 as infection_rate
From (select location, continent, date, cast(total_cases as numeric) as total_cases, population
from Portfolio_Project.dbo.covid_death_data) as converted_datatype
where continent is not null
Group by location, population
order by infection_rate desc

-- LETS BREAK IT DOWN BY CONTINENT
Select continent, MAX(total_cases) as highest_infection_count, MAX((total_cases/ population)) * 100 as infection_rate
From (select continent, date, cast(total_cases as numeric) as total_cases, population
from Portfolio_Project.dbo.covid_death_data) as converted_datatype
where continent is not null
Group by continent
order by infection_rate desc


--looking at country with highest death count per population

Select location, population, MAX(total_deaths) as highest_infection_count, MAX((total_deaths/ population)) * 100 as death_rate
From (select location, continent, date, cast(total_deaths as numeric) as total_deaths, population
from Portfolio_Project.dbo.covid_death_data) as converted_datatype
where continent is not null
Group by location, population
order by death_rate desc

--LETS BREAK IT DOWN BY CONTINENTS

Select continent as population, MAX(total_deaths) as highest_infection_count, MAX((total_deaths/ population)) * 100 as death_rate
From (select continent, date, cast(total_deaths as numeric) as total_deaths, population
from Portfolio_Project.dbo.covid_death_data) as converted_datatype
where continent is not null
Group by continent
order by death_rate desc

--Total population vs Vaccinations

with popvsvac (continent, location, date, population, new_vaccinations, Rolling_people_vacinated) as 

	(select death.continent, death.location, death.date, death.population, death.new_vaccinations,
	Sum(cast(vacc.new_vaccinations as bigint)) over (partition by death.location order by death.location , death.date) as Rolling_people_vaccinated
	from Portfolio_Project.dbo.covid_death_data as death
	join Portfolio_Project.dbo.covid_vaccination as vacc
	on death.location = vacc.location and
	death.date = vacc.date
	where death.continent is not null)

	-- Using CTE

	Select *, (Rolling_people_vacinated / population)*100
	From popvsvac

-- TEMP TABLE
drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population bigint,
new_vaccinations numeric,
Rolling_people_vaccinated numeric)

insert into #PercentPopulationVaccinated
select death.continent, death.location, death.date, death.population, death.new_vaccinations,
	Sum(cast(vacc.new_vaccinations as bigint)) over (partition by death.location order by death.location , death.date) as Rolling_people_vaccinated
	from Portfolio_Project.dbo.covid_death_data as death
	join Portfolio_Project.dbo.covid_vaccination as vacc
	on death.location = vacc.location and
	death.date = vacc.date
	where death.continent is not null

Select *, (Rolling_people_vaccinated / population)*100
	From #PercentPopulationVaccinated

-- creating view to store data for later vizualizations

create view percentpopulationvaccinated as 
(
select death.continent, death.location, death.date, death.population, death.new_vaccinations,
	Sum(cast(vacc.new_vaccinations as bigint)) over (partition by death.location order by death.location , death.date) as Rolling_people_vaccinated
	from Portfolio_Project.dbo.covid_death_data as death
	join Portfolio_Project.dbo.covid_vaccination as vacc
	on death.location = vacc.location and
	death.date = vacc.date
	where death.continent is not null)