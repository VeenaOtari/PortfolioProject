-- **Project Overview:** 
-- This project demonstrates proficiency in Data Manipulation Language (DML) and Data Query Language (DQL) using a COVID-19 dataset.

-- **Explore Raw Data:**
-- 1. Examine the dataset for CovidDeaths to gain an initial understanding of the available information.
select *
from PortfolioProject..CovidDeaths

-- 2. Investigate the contents of the CovidVaccinations dataset to identify key data points.
select *
from PortfolioProject..CovidVaccinations

-- **Data Cleaning and Transformation:**
-- 3. Cleanse the CovidDeaths data by removing entries related to 'Upper middle income.'
delete
from PortfolioProject..CovidDeaths
where location = 'Upper middle income'

-- 4. Transform total_cases and total_deaths columns in CovidDeaths to integers.
update PortfolioProject..CovidDeaths
set total_cases = cast(total_cases as int)
where total_cases is not null and isnumeric(total_cases) = 1;

update PortfolioProject..CovidDeaths
set total_deaths = cast(total_deaths as int)
where total_deaths is not null and isnumeric(total_deaths) = 1;

-- **Organize and View Data:**
-- 5. Arrange and view relevant columns (Location, Date, Total Cases, New Cases, Total Deaths, Population) in the CovidDeaths dataset, ordered by location and date.
Select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1, 2

-- **Explore COVID-19 Impact:**
-- 6. Calculate the death percentage for COVID-19 cases in a specific country, such as India, considering the ratio of total deaths to total cases.
select location, date, total_cases, total_deaths, 
(convert(float, total_deaths) / nullif(convert(float, total_cases), 0)) * 100 as death_percentage
from PortfolioProject..CovidDeaths
where location = 'India'
order by 1, 2

-- 7. Analyze the percentage of the population affected by COVID-19 in different countries over time.
select location, date, population, total_cases,
(nullif(convert(float, total_cases), 0) / population) * 100 as infected_pop_percentage
from PortfolioProject..CovidDeaths
order by 1, 2

-- 8. Identify countries with the highest infection rates relative to their population, showcasing both the highest infection count and the corresponding percentage.
select location, population, Max(total_cases) as highest_infection_count,
max((nullif(convert(float, total_cases), 0)) / population) * 100 as infected_pop_percentage
from PortfolioProject..CovidDeaths
group by location, population
order by infected_pop_percentage desc

-- 9. Investigate countries with the highest death count per population.
select location, max(total_deaths) as total_death_count
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by total_death_count desc

-- **Regional Analysis:**
-- 10. Explore continents with the highest death counts, differentiating between continents and individual locations.
select location, max(total_deaths) as total_death_count
from PortfolioProject..CovidDeaths
where continent is null
group by location
order by total_death_count desc

-- 11. Regional Hotspots:
-- Identify countries that experienced the highest peaks in daily new cases and deaths.
select continent, location, date, max(new_cases) as peak_new_cases, max(total_deaths) as peak_deaths
from PortfolioProject..CovidDeaths
where continent is not null
group by continent, location, date

-- **Global Statistics:**
-- 12. Investigate global COVID-19 statistics, summarizing total cases, total deaths, and the death percentage over time.
select date, sum(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_deaths,
case
	when sum(new_cases) = 0 then null
    else sum(cast(new_deaths as int)) / nullif(sum(new_cases), 0) * 100
end as death_percentage
from PortfolioProject..CovidDeaths
where continent IS NOT NULL
group by date
order by date;

-- **Combined Data Exploration:**
select *
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

-- 13. Combine data from CovidDeaths and CovidVaccinations datasets to explore the relationship between total population and new vaccinations.
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (partition by  dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
order by 1, 2, 3

-- Continental Variation:
-- 14. Compare the progression of COVID-19 across different continents. How do infection rates, death rates, and vaccination efforts vary?
select dea.continent, dea.date, avg(cast(new_cases as bigint)) as average_infection_rate, 
avg(cast(total_deaths as bigint)) as average_death_rate, sum(cast(total_vaccinations as bigint)) as total_vaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
group by dea.continent, dea.date
order by continent, date;

-- Impact of Population Density:
-- 15. Explore the relationship between population density and COVID-19 outcomes. Do more densely populated areas experience higher infection rates or mortality?
select continent, location, sum(cast(new_cases as bigint)) as total_new_cases, avg(population) as average_population
from PortfolioProject..CovidDeaths
where continent is not null
group by continent, location
order by continent, location

-- **Vaccination Progress Over Time:**
-- 16. Explore the temporal evolution of new vaccinations globally or in specific regions to visualize the progress of vaccination campaigns.
select vac.date, sum(cast(new_vaccinations as bigint)) as total_vaccinations, 
(SUM(cast(vac.people_vaccinated as bigint)) / MAX(dea.population)) * 100 AS vaccination_coverage_percentage
from PortfolioProject..CovidVaccinations vac
join PortfolioProject..CovidDeaths dea ON vac.location = dea.location
where vac.continent is not null
group by vac.date, vac.continent
order by vac.date, vac.continent;

--Geographical Distribution of Booster Shots:
--17. Analyze the distribution of booster shots across different regions. How are countries adapting their vaccination strategies over time?
select continent, location, date, sum(cast(total_boosters as int)) as total_booster_shots
from PortfolioProject..CovidVaccinations
where continent IS NOT NULL
group by continent, location, date
order by continent, location, date;

-- Vaccination Coverage vs. GDP per Capita:
-- 18. Explore the relationship between vaccination coverage and the GDP per capita of countries. 
-- Are wealthier nations more successful in achieving widespread vaccination?
select vac.location as country, sum(cast(vac.total_vaccinations as bigint)) as total_vaccinations, sum(cast(vac.people_vaccinated as bigint)) as total_people_vaccinated,
    sum(cast(vac.people_fully_vaccinated as bigint)) as total_people_fully_vaccinated, avg(cast(vac.gdp_per_capita as bigint)) as average_gdp_per_capita
from PortfolioProject..CovidVaccinations vac
join PortfolioProject..CovidDeaths dea on vac.location = dea.location
where vac.continent is not null
group by vac.location
order by vac.location;



