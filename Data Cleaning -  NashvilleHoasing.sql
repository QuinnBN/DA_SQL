-- In this project, I performed some data cleaning on the NashvilleHousing dataset using T-SQL.


SELECT *
FROM NashvilleHousing..Housing;


--Standadize SaleDate format
SELECT SaleDate
FROM NashvilleHousing..Housing;

ALTER TABLE NashvilleHousing..Housing
ALTER COLUMN SaleDate date;


--Poplulate PropertyAddress
SELECT *
FROM NashvilleHousing..Housing
WHERE PropertyAddress IS NULL; 

SELECT
	t1.ParcelID,
	t1.PropertyAddress,
	t2.ParcelID,
	t2.PropertyAddress,
	ISNULL(t1.PropertyAddress, t2.PropertyAddress)
FROM NashvilleHousing..Housing t1
JOIN NashvilleHousing..Housing t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.[UniqueID ]<>t2.[UniqueID ]
WHERE t1.PropertyAddress IS NULL;

UPDATE t1
SET PropertyAddress = ISNULL(t1.PropertyAddress, t2.PropertyAddress)
FROM NashvilleHousing..Housing t1
JOIN NashvilleHousing..Housing t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.[UniqueID ]<>t2.[UniqueID ]
WHERE t1.PropertyAddress IS NULL;


--Break Address into individual columns (Address, City, State)
SELECT 
	PropertyAddress
FROM NashvilleHousing..Housing;

SELECT
	PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2),
	PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1)
FROM NashvilleHousing..Housing;

ALTER TABLE NashvilleHousing..Housing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing..Housing
SET PropertySplitAddress = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2);

ALTER TABLE NashvilleHousing..Housing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing..Housing
SET PropertySplitCity = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1);

SELECT 
	OwnerAddress
FROM NashvilleHousing..Housing;

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing..Housing;

ALTER TABLE NashvilleHousing..Housing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing..Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE NashvilleHousing..Housing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing..Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE NashvilleHousing..Housing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing..Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

--SELECT *
--FROM NashvilleHousing..Housing;


--Replace 'Y' and 'N' in SoleAsVacant column
SELECT
	DISTINCT(SoldAsVacant),
	COUNT(SoldAsVacant)
FROM NashvilleHousing..Housing
GROUP BY SoldAsVacant;

SELECT
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM NashvilleHousing..Housing;

UPDATE NashvilleHousing..Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END;


--Remove duplicates
WITH Row_Num AS(
	SELECT
		*,
		ROW_NUMBER() OVER(
		PARTITION BY
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			ORDER BY UniqueID) AS row_num
	FROM NashvilleHousing..Housing)

DELETE
--SELECT *
FROM Row_Num
WHERE row_num>1;


--Drop unused columns
SELECT *
FROM NashvilleHousing..Housing;

ALTER TABLE NashvilleHousing..Housing
DROP COLUMN 
	PropertyAddress,
	OwnerAddress,
	TaxDistrict;
