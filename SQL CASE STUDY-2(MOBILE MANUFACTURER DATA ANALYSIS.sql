--SQL CASE STUDY

USE db_SQLCaseStudies

Select * from FACT_TRANSACTIONS
SElect * from dbo.DIM_CUSTOMER
Select * from dbo.DIM_MODEL
Select * from dbo.DIM_DATE
Select * from dbo.DIM_LOCATION 
Select * from DIM_MANUFACTURER


--1. List all the states in which we have customers who have bought cellphones from 2005 till today.	

SELECT DISTINCT T1.[STATE],YEAR(DATE) [YEAR]
FROM FACT_TRANSACTIONS T4
LEFT JOIN DIM_LOCATION T1 ON T4.IDLocation = T1.IDLocation
WHERE year(date)>='2005'
ORDER BY [year];
	



	
--2. What state in the US is buying the most 'Samsung' cell phones? 

SELECT TOP 1 T1.COUNTRY,T1.[STATE] FROM DIM_LOCATION T1 LEFT JOIN FACT_TRANSACTIONS T2 ON T1.IDLOCATION =T2.IDLocation
LEFT JOIN DIM_MODEL T3 ON T2.IDModel = T3.IDModel LEFT JOIN DIM_MANUFACTURER T4 ON T3.IDManufacturer=T4.IDManufacturer
WHERE COUNTRY='US' AND Manufacturer_Name='SAMSUNG'
GROUP BY T1.COUNTRY,T1.[STATE]
ORDER BY SUM(Quantity)DESC;



 

--3. Show the number of transactions for each model per zip code per state. 

SELECT T1.MODEL_NAME,T2.[STATE],T2.ZIPCODE,COUNT(IDCUSTOMER) TRANSACTIONS FROM DIM_LOCATION T2
JOIN FACT_TRANSACTIONS T3 ON T2.IDLocation = T3.IDLocation JOIN DIM_MODEL T1 ON T3.IDModel=T1.IDModel
GROUP BY T1.MODEL_NAME,T2.[STATE],T2.ZIPCODE
ORDER BY COUNT(IDCUSTOMER)desc;
	


--4. Show the cheapest cellphone (Output should contain the price also)

SELECT TOP 1 MODEL_NAME ,MANUFACTURER_NAME ,MIN(Unit_price) [MINIMUM PRICE]
FROM DIM_MODEL JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer=DIM_MANUFACTURER.IDManufacturer
GROUP BY MODEL_NAME ,MANUFACTURER_NAME 
ORDER BY MIN(Unit_price);



--5. Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.

SELECT  MANUFACTURER_NAME , MODEL_NAME,AVG(TotalPrice) [AVERAGE PRICE]
FROM DIM_MODEL
LEFT JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer = DIM_MANUFACTURER.IDManufacturer LEFT JOIN FACT_TRANSACTIONS ON DIM_MODEL.IDModel = FACT_TRANSACTIONS.IDModel
WHERE MANUFACTURER_NAME IN  (SELECT TOP 5 Manufacturer_Name FROM FACT_TRANSACTIONS JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel=DIM_MODEL.IDModel
JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer=DIM_MANUFACTURER.IDManufacturer GROUP BY Manufacturer_Name ORDER BY SUM(QUANTITY)desc)
GROUP BY Manufacturer_Name,Model_Name
ORDER BY AVG(TotalPrice)desc;

--6. List the names of the customers and the average amount spent in 2009, where the average is higher than 500

SELECT  T1.IDCUSTOMER,T1.CUSTOMER_NAME,AVG(TOTALPRICE) [AVERAGE PRICE]
FROM DIM_CUSTOMER T1 JOIN FACT_TRANSACTIONS T2 ON T1.IDCustomer =T2.IDCustomer WHERE YEAR(DATE)='2009'
GROUP BY T1.IDCUSTOMER,T1.CUSTOMER_NAME
HAVING AVG(TOTALPRICE)>500 
ORDER BY Customer_Name;


	
--7. List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010	

SELECT * from DIM_MODEL where idmodel in(	
select idmodel from(select top 5 sum(Quantity) quantity,idmodel from FACT_TRANSACTIONS where year(date)=2008
group by IDModel order by sum(Quantity)desc)t
intersect
select idmodel from(select top 5 sum(Quantity) quantity,idmodel from FACT_TRANSACTIONS where year(date)=2009
group by IDModel order by sum(Quantity)desc)t
intersect
select idmodel from(select top 5 sum(Quantity) quantity,idmodel from FACT_TRANSACTIONS where year(date)=2010
group by IDModel order by sum(Quantity)desc)t);	



--8. Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.

with rnk as ( select t1.idmanufacturer,t1.manufacturer_name,year(date)[year],rank() over(order by sum(totalprice) desc) r from FACT_TRANSACTIONS t2
join DIM_MODEL t3 on t2.IDModel=t3.IDModel join DIM_MANUFACTURER t1 on t3.IDManufacturer=t1.IDManufacturer
where year(date)='2009' group by year(date), t1.idmanufacturer,t1.manufacturer_name
union all 
select t1.idmanufacturer,t1.manufacturer_name,year(date)[year],rank() over(order by sum(totalprice) desc) r from FACT_TRANSACTIONS t2
join DIM_MODEL t3 on t2.IDModel=t3.IDModel join DIM_MANUFACTURER t1 on t3.IDManufacturer=t1.IDManufacturer
where year(date)='2010' group by year(date), t1.idmanufacturer,t1.manufacturer_name)
select idmanufacturer,manufacturer_name,[YEAR] from rnk where r=2;


--9. Show the manufacturers that sold cellphones in 2010 but did not in 2009. 	

SELECT T1.IDMANUFACTURER,T1.MANUFACTURER_NAME FROM DIM_MANUFACTURER T1 JOIN DIM_MODEL T2 ON T1.IDManufacturer=T2.IDManufacturer
JOIN FACT_TRANSACTIONS T3 ON T2.IDModel=T3.IDModel WHERE YEAR(DATE)='2010'
EXCEPT
SELECT T1.IDMANUFACTURER,T1.MANUFACTURER_NAME FROM DIM_MANUFACTURER T1 JOIN DIM_MODEL T2 ON T1.IDManufacturer=T2.IDManufacturer
JOIN FACT_TRANSACTIONS T3 ON T2.IDModel=T3.IDModel WHERE YEAR(DATE)='2009';

-

--10. Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.

with temp as
(select *,lag(tot) over(partition by customer_name order by customer_name ) yoyspend from
(select c.Customer_Name,year(date) [year],sum(totalprice) tot,avg(TotalPrice) avgspent,avg(Quantity) avgqty 
from DIM_CUSTOMER c 
  join FACT_TRANSACTIONS f on c.IDCustomer=f.IDCustomer
  group by c.Customer_Name,year(date)) r )
  select Customer_Name,year,tot,avgspent,avgqty,(tot-yoyspend)/yoyspend*100 [% change yoy] from temp; 	

