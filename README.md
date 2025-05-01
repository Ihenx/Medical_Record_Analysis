# 🏥 Hospital Patient Records Management & Analysis
![ChatGPT Image May 1, 2025, 12_07_54 PM](https://github.com/user-attachments/assets/3173ba14-a549-41d7-ad03-4e1a74bb416c)
This project involves the cleaning, normalization, modeling, and exploration of hospital patient data using MySQL. The goal is to transform a denormalized and inconsistent dataset into a well-structured relational database and derive meaningful insights from it.

## 📁 Database Used
`USE medical_records;`

## 🧼 1. Data Cleaning
### Objectives:
* Standardize data formats

* Correct inconsistent entries

* Prepare data for modeling and analysis

 ## Key Cleaning Steps:

### Gender Standardization: Fixed entries like `'Mle'` → `'Male'`, and `'Fmale'` → `'Female'`

 ```
UPDATE patients 
SET 
    gender = REPLACE(REPLACE(gender, 'Mle', 'Male'),
        'Fmale',
        'Female');
```
### Date Formatting: Converted mixed date formats to standard SQL DATE types in date_of_birth and date_of_visit
  
```
UPDATE patients 
SET 
    date_of_birth = CASE
        WHEN date_of_birth LIKE '%-%-%' THEN STR_TO_DATE(date_of_birth, '%Y-%m-%d')
        WHEN date_of_birth LIKE '%/%/%' THEN STR_TO_DATE(date_of_birth, '%d/%m/%Y')
        ELSE NULL
    END;
```
```
-- Standardize the date_of_visit column to a consistent DATE format
-- Handles both 'YYYY-MM-DD' and 'MM/DD/YYYY' formats
UPDATE patients 
SET 
    date_of_visit = CASE
        WHEN date_of_visit LIKE '%-%-%' THEN STR_TO_DATE(date_of_visit, '%Y-%m-%d')
        WHEN date_of_visit LIKE '%/%/%' THEN STR_TO_DATE(date_of_visit, '%m/%d/%Y')
        ELSE NULL
    END;
```
### Age Calculation: Created and populated an age column using TIMESTAMPDIFF
```
UPDATE patients 
SET 
    age = TIMESTAMPDIFF(YEAR,
        date_of_birth,
        CURDATE());
```

### Email Cleaning: Fixed double dots (..) and appended missing domain endings (.com)
```
- Fix email addresses with double dots '..' to a single dot '.'
update patients
set email = replace(email, '..','.');

commit;
-- Append '.com' to emails that have '@' but no domain extension
UPDATE patients 
SET 
    email = CASE
        WHEN
            email LIKE '%@%'
                AND email NOT LIKE '%@%.%'
        THEN
            CONCAT(email, '.com')
        ELSE email
    END;
```

### Address Cleaning: Extracted street names from addresses formatted as 'Street, State'
```
-- Clean up addresses by extracting the portion before the first comma
-- Assumes addresses are in the format 'Street, State'
UPDATE patients 
SET 
    address = SUBSTRING_INDEX(address, ',', 1);
```

### Payment Cleanup: Standardized payment_status values and cleaned amount_billed by removing symbols and converting to INT
```
-- Standardize payment status: Ensures only 'Paid' and 'Unpaid' values are retained
UPDATE patients 
SET 
    payment_status = CASE
        WHEN payment_status = 'Paid' THEN 'Paid'
        WHEN payment_status = 'Unpaid' THEN 'Unpaid'
        ELSE 'Unpaid'
    END;
```
```
-- Remove Naira symbol (₦) and commas from the amount_billed column for numeric conversion
UPDATE patients 
SET 
    amount_billed = REPLACE(REPLACE(amount_billed, '₦', ''),
        ',',
        '');
```
```
-- Convert amount_billed column to integer data type
alter table patients
modify column amount_billed int;
```
### Insurance Provider: Replaced NULL with 'Uninsured' in the insurance_provider field
```
-- Fill null values in insurance_provider column with 'Uninsured'
UPDATE patients 
SET 
    insurance_provider = COALESCE(insurance_provider, 'Uninsured');
```

## 🧱 2. Data Modeling & Normalization
#### Goals:

* Convert the flat patients table into a normalized database model

* Improve query performance and enforce data consistency

  #### New Tables Created:

`departments`

`doctors` (linked to departments)

`diagnosis`

`treatments`

`insurance_providers`

`payment_statuses`

### Modeling Steps:

#### Populated the new dimension tables from distinct values in patients
``` -- Create 'departments' table to store unique medical departments
CREATE TABLE departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(255)
);


-- Create 'doctors' table and link each doctor to their department
CREATE TABLE doctors (
    id INT PRIMARY KEY,
    full_name VARCHAR(255),
    dept_id INT,
    FOREIGN KEY (dept_id)
        REFERENCES departments (id)
);

-- Create 'diagnosis' table to store unique diagnoses
CREATE TABLE diagnosis (
    id INT PRIMARY KEY AUTO_INCREMENT,
    diagnosis VARCHAR(255)
);

-- Create 'treatments' table to store different treatment plans
create table treatments(
id int primary key auto_increment,
treatments varchar(255)
);

-- Create 'insurance_providers' table to normalize insurance company data
create table insurance_providers(
id int primary key auto_increment,
insurance_provider varchar(255)
);

-- Create 'payment_statuses' table to normalize patient payment statuses
create table payment_statuses(
id int primary key auto_increment,
payment_status varchar(255)
);
```
```
--  Insert valuses into respectiive tables

-- Insert unique department names into departments table
insert into departments(dept_name)
select distinct department
from patients;

-- Insert unique doctors and assign correct department ID via join
insert into doctors(id,full_name,dept_id)
select distinct doctor_id, doctor_name,d.id
from patients p
join departments d
on d.dept_name = p.department;

-- Insert unique diagnoses into diagnosis table
insert into diagnosis(diagnosis)
select distinct diagnosis
from patients;

-- Insert unique treatments into treatments table
insert into treatments(treatments)
select distinct treatment
from patients;

-- Insert unique insurance providers
insert into insurance_providers(insurance_provider)
select distinct insurance_provider
from patients;

-- Insert unique payment statuses
insert into payment_statuses(payment_status)
select distinct payment_status
from patients;
```

#### Added foreign keys (diagnosis_id, treatment_id, etc.) to the patients table
```
-- Adding normalized columns and defining foreign key constraints
alter table  patients
add column diagnosis_id int,
add column treatment_id int,
add column insurance_provider_id int,
add column payment_status_id int,

-- Define relationships with foreign key constraints
add constraint patient_diagnosis_id
foreign key(diagnosis_id) references diagnosis(id)
on delete cascade
on update cascade,
add constraint patient_treatment_id
foreign key(treatment_id) references treatments(id)
on update cascade
on delete cascade,
add constraint patients_insurance_provider_id
foreign key(insurance_provider_id) references insurance_providers(id)
on update cascade
on delete cascade,
add constraint patients_payment_status_id
foreign key(payment_status_id) references payment_statuses(id)
on update cascade
on delete cascade;
```

#### Backfilled foreign key columns by joining with dimension tables
```
-- Map existing values to corresponding IDs from normalized tables
UPDATE patients p
        JOIN
    diagnosis dg ON dg.diagnosis = p.diagnosis 
SET 
    p.diagnosis_id = dg.id;

UPDATE patients p
        JOIN
    treatments t ON p.treatment = t.treatments 
SET 
    p.treatment_id = t.id;

UPDATE patients p
        JOIN
    insurance_providers ip ON p.insurance_provider = ip.insurance_provider 
SET 
    p.insurance_provider_id = ip.id;

UPDATE patients p
        JOIN
    payment_statuses ps ON p.payment_status = ps.payment_status 
SET 
    p.payment_status_id = ps.id;
```
#### Dropped the original denormalized columns (e.g., doctor_name, diagnosis, treatment)
```
--  drop columns from patients table
alter table patients
drop doctor_name,
drop treatment,
drop department,
drop diagnosis,
drop payment_status,
drop column insurance_provider;
```

#### Created indexes on key columns (diagnosis_id, doctor_id, etc.)
```
-- Create indexes to improve query performance on key columns
create index id_dignosis on patients(diagnosis_id);
create index id_doctor on patients(doctor_id);
create index id_treatment on patients(treatment_id);
create index id_dept on doctors(dept_id);
```
#### Enforced ENUM on gender values and added automatic timestamps for created_at and updated_at
```
-- Restrict gender values to a controlled ENUM list
alter table patients
modify gender enum('Male','Female','Others');

-- Track creation and update times automatically
alter table patients
add column created_at  timestamp default current_timestamp,
add column  updated_at timestamp on update current_timestamp;
```

## 📊 3. Exploratory Data Analysis (EDA)
### Techniques Used:

* Aggregations and groupings

* Common Table Expressions (CTEs)

* Custom SQL functions (divide, product)

* Ranking functions for finding top entries

EDA Highlights:
#### 1.Age Distribution
```
select age , count(*) as "Number of Patients"
from patients
group by age
order by "Number of Patients" desc;
```
![Screenshot 2025-05-01 113808](https://github.com/user-attachments/assets/d2f5fecd-e8b6-4aa5-bf4d-a59bda657c94)


#### 2. Number of Customers By Age Groups
```
-- =============================
-- Group Patients into Age Groups
-- =============================
SELECT 
    CASE
        WHEN age BETWEEN 13 AND 17 THEN 'Adolescents'
        WHEN age BETWEEN 18 AND 34 THEN 'Early Adults'
        WHEN age BETWEEN 35 AND 54 THEN 'Mature Adults'
        ELSE 'Elderly'
    END AS Age_group,
    COUNT(*) AS patient_count
FROM
    patients
GROUP BY age_group;


-- alternatively
-- OR using CTE for reusability
with age_group_cte as(
   select CASE
        WHEN age BETWEEN 13 AND 17 THEN 'Adolescents'
        WHEN age BETWEEN 18 AND 34 THEN 'Early Adults'
        WHEN age BETWEEN 35 AND 54 THEN 'Mature Adults'
        ELSE 'Elderly'
    END AS Age_group
from patients
)
```
<img src="https://github.com/user-attachments/assets/e6f83fd6-6a49-4251-ad5f-b1a87c139500" width="1000" height="200"/>


#### 3. Gender Distribution Ratio

```
-- =============================
-- Custom Division Function
-- =============================

delimiter //
create function divide(
	num1 int, num2 int) returns decimal(10,2)
    deterministic
    begin
		declare divide decimal(10,2);
        return num1 / num2;
        end //
delimiter ;
```
```-- Gender Distribution Ratios
 set @total_count :=(select count(*) from patients);
```
```
SELECT 
    gender, DIVIDE(COUNT(*), @total_count) AS ratio
FROM
    patients
GROUP BY gender;
```

#### 4. Most Common Diagnosis by Age Group
```
with age_group_diag_cte as(select *, CASE
        WHEN age BETWEEN 13 AND 17 THEN 'Adolescents'
        WHEN age BETWEEN 18 AND 34 THEN 'Early Adults'
        WHEN age BETWEEN 35 AND 54 THEN 'Mature Adults'
        ELSE 'Elderly'
    END AS Age_group
from patients),

rank_cte as(select
	age_group, 
	diagnosis,
    count(*) as patient_count,
rank() over (partition by age_group order by count(*) desc) as ranking
from age_group_diag_cte ag
join diagnosis dg
on ag.diagnosis_id = dg.id
group by age_group, diagnosis
order by age_group, patient_count desc)

select age_group,
	diagnosis,
    patient_count
from rank_cte
where ranking =1;
```
<img src="https://github.com/user-attachments/assets/ff3deacb-3b03-4067-a577-5f2284f826f0" width="1000" height="200"/>


#### 5. Doctors With Above-Average Load
```
SELECT 
        p.doctor_id, d.full_name, COUNT(*) patient_count
    FROM
        patients p
    JOIN doctors d ON p.doctor_id = d.id
    GROUP BY p.doctor_id , d.full_name
    having count(*) >
(SELECT 
    AVG(patient_count)
FROM
    (SELECT 
        p.doctor_id, d.full_name, COUNT(*) patient_count
    FROM
        patients p
    JOIN doctors d ON p.doctor_id = d.id
    GROUP BY p.doctor_id , d.full_name) AS doctor_load_sub);
```

<img src="https://github.com/user-attachments/assets/94de1e96-83c2-46b8-a318-ed8b8bcf4494" width="1000" height="200"/>

#### 6. Busiest Day of the Week
```
SELECT 
    DAYNAME(date_of_visit) day_of_week, COUNT(*) visit_count
FROM
    patients
GROUP BY DAYNAME(date_of_visit)
ORDER BY visit_count DESC;
```
#### 7.Billed Amount Ratio by Payment Status
```
set @total_amount_billed := (select sum(amount_billed) from patients);
SELECT 
    ps.payment_status, divide(SUM(amount_billed),@total_amount_billed) AS ratio
FROM
    patients p
        JOIN
    payment_statuses ps ON p.payment_status_id = ps.id
GROUP BY ps.payment_status
order by ratio desc;
```

<img src="https://github.com/user-attachments/assets/0c3eb105-4bc4-449c-b648-36d460669cad" width="1000" height="200"/>

#### 8.Most Busy Month (by visit count)
```
SELECT 
    MONTHNAME(date_of_visit) AS month, COUNT(*) visit_count
FROM
    patients
GROUP BY MONTHNAME(date_of_visit)
ORDER BY visit_count desc;
```
<img src="https://github.com/user-attachments/assets/e03431ca-a12f-4696-82d2-6fdfd397d7be" width="1000" height="200"/>

### 🛠️ Tools & Skills Applied
#### SQL (MySQL)

* Data Cleaning

* Data Modeling

* Indexing

* Window Functions

* CTEs

* User-defined Functions


### 📌 Key Takeaways
* Learned how to transform messy healthcare data into a relational model

* Gained hands-on experience with database normalization

* Improved query performance using indexing

* Extracted actionable business and clinical insights using advanced SQL

