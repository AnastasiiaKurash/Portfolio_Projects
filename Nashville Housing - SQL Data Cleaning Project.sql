/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM Data_Cleaning_Project..Nashville_Housing_Data

--Standardize Date Format

SELECT 
	SaleDate
	, cast(SaleDate as date)                        AS date_without_time
FROM Data_Cleaning_Project..Nashville_Housing_Data

ALTER TABLE Nashville_Housing_Data
ADD SaleDateConverted Date

UPDATE Nashville_Housing_Data
SET SaleDateConverted = cast(SaleDate as date)

SELECT 
	SaleDate
	, SaleDateConverted                     
FROM Data_Cleaning_Project..Nashville_Housing_Data

------------------------------------------------------------------------------------

--Populate Property Address data

SELECT *        
FROM Data_Cleaning_Project..Nashville_Housing_Data
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT 
	nhd1.ParcelID
	, nhd1.PropertyAddress
	, nhd2.ParcelID
	, nhd2.PropertyAddress
	, ISNULL(nhd1.PropertyAddress, nhd2.PropertyAddress)
FROM Data_Cleaning_Project..Nashville_Housing_Data nhd1
JOIN Data_Cleaning_Project..Nashville_Housing_Data nhd2
	ON nhd1.ParcelID = nhd2.ParcelID
	AND nhd1.[UniqueID ] <> nhd2.[UniqueID ]
WHERE nhd1.PropertyAddress IS NULL

UPDATE nhd1
SET nhd1.PropertyAddress = ISNULL(nhd1.PropertyAddress, nhd2.PropertyAddress)
FROM Data_Cleaning_Project..Nashville_Housing_Data nhd1
JOIN Data_Cleaning_Project..Nashville_Housing_Data nhd2
	ON nhd1.ParcelID = nhd2.ParcelID
	AND nhd1.[UniqueID ] <> nhd2.[UniqueID ]
WHERE nhd1.PropertyAddress IS NULL

------------------------------------------------------------------------------------

--Breaking out Address Into Individual Coiumns (Address, City, State)

SELECT*
FROM Nashville_Housing_Data

SELECT PropertyAddress       
FROM Data_Cleaning_Project..Nashville_Housing_Data

SELECT 
	PropertyAddress
	, SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)                       AS Address
	, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))    AS City
FROM Data_Cleaning_Project..Nashville_Housing_Data

ALTER TABLE Nashville_Housing_Data
ADD Property_Address nvarchar(255)

UPDATE Nashville_Housing_Data
SET Property_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE Nashville_Housing_Data
ADD Property_City nvarchar(255)

UPDATE Nashville_Housing_Data
SET Property_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT 
	PropertyAddress
	, Property_Address
	, Property_City
FROM Nashville_Housing_Data

--------------------------------------

SELECT OwnerAddress
FROM Nashville_Housing_Data

SELECT
	OwnerAddress
	, PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)             AS Owner_Address
	, PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)             AS Owner_City
	, PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)             AS Owner_State
FROM Nashville_Housing_Data

ALTER TABLE Nashville_Housing_Data
ADD Owner_Address nvarchar(255)

UPDATE Nashville_Housing_Data
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

ALTER TABLE Nashville_Housing_Data
ADD Owner_City nvarchar(255)

UPDATE Nashville_Housing_Data
SET Owner_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

ALTER TABLE Nashville_Housing_Data
ADD Owner_State nvarchar(255)

UPDATE Nashville_Housing_Data
SET Owner_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

SELECT 
	OwnerAddress
	, Owner_Address
	, Owner_City
	, Owner_State
FROM Data_Cleaning_Project..Nashville_Housing_Data

------------------------------------------------------------------------------------

--Change Y and N to Yes and No in 'Sold as Vacant' field

SELECT SoldAsVacant
FROM Nashville_Housing_Data

SELECT DISTINCT(SoldAsVacant)
FROM Data_Cleaning_Project..Nashville_Housing_Data
WHERE SoldAsVacant <> 'Yes' AND SoldAsVacant <> 'No'

SELECT 
	IIF(SoldAsVacant = 'N', 'No', 'Yes')
FROM Data_Cleaning_Project..Nashville_Housing_Data
WHERE SoldAsVacant <> 'Yes' AND SoldAsVacant <> 'No'

UPDATE Nashville_Housing_Data
SET SoldAsVacant = IIF(SoldAsVacant = 'N', 'No', 'Yes')
WHERE SoldAsVacant <> 'Yes' AND SoldAsVacant <> 'No'

------------------------------------------------------------------------------------

--Remove Duplicates

WITH CTE_find_duplicate AS
(
	SELECT 
		*
		, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID)     AS row_num
	FROM Data_Cleaning_Project..Nashville_Housing_Data
) 
DELETE
FROM CTE_find_duplicate          
WHERE row_num > 1

------------------------------------------------------------------------------------

--Delete Unused Column

SELECT *
FROM Nashville_Housing_Data

ALTER TABLE Data_Cleaning_Project..Nashville_Housing_Data
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
