CREATE DATABASE IF NOT EXISTS medical_records;
USE medical_records;

-- Step 2: Create the Patients Table
CREATE TABLE IF NOT EXISTS patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255),
    gender VARCHAR(20),
    date_of_birth VARCHAR(50),
    phone_number VARCHAR(20),
    email VARCHAR(255),
    address VARCHAR(255),
    state_of_origin VARCHAR(100),
    doctor_id INT,
    doctor_name VARCHAR(255),
    department VARCHAR(100),
    diagnosis VARCHAR(255),
    treatment VARCHAR(255),
    date_of_visit VARCHAR(50),
    amount_billed VARCHAR(50),
    payment_status VARCHAR(50),
    next_of_kin VARCHAR(255),
    relationship_to_patient VARCHAR(50),
    emergency_contact VARCHAR(20),
    insurance_provider VARCHAR(255)
);

-- Step 3: Create a Helper Table for Random Data
CREATE TABLE IF NOT EXISTS helpers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255),
    doctor_name VARCHAR(255),
    state_of_origin VARCHAR(100),
    department VARCHAR(100),
    diagnosis VARCHAR(100),
    treatment VARCHAR(100),
    relationship VARCHAR(50)
);
-- Continuing Step 4: Insert Random Sample Data into Helper
INSERT INTO helpers (full_name, doctor_name, state_of_origin, department, diagnosis, treatment, relationship)
VALUES
('Chukwu Emeka', 'Dr. Musa Ahmed', 'Enugu', 'Cardiology', 'Malaria', 'Paracetamol', 'Father'),
('Ngozi Onu', 'Dr. Chioma Obi', 'Lagos', 'Pediatrics', 'Typhoid', 'Antibiotics', 'Mother'),
('Ibrahim Musa', 'Dr. John Smith', 'Kano', 'Neurology', 'Diabetes', 'Insulin Injection', 'Brother'),
('Blessing Okafor', 'Dr. Aisha Bello', 'Abuja', 'Orthopedics', 'Bone Fracture', 'Plaster Cast', 'Sister'),
('Sunday Eze', 'Dr. Emeka Okoro', 'Anambra', 'Dermatology', 'Eczema', 'Steroid Cream', 'Father'),
('Amina Yusuf', 'Dr. Oladimeji Bayo', 'Kaduna', 'Oncology', 'Cancer', 'Chemotherapy', 'Mother');

-- Step 5: Create Procedure to Insert 5000 Random Records
DELIMITER //

CREATE PROCEDURE generate_patients()
BEGIN
    DECLARE counter INT DEFAULT 0;
    DECLARE rand_helper_id INT;
    DECLARE rand_gender VARCHAR(10);
    DECLARE dob DATE;
    DECLARE visit DATE;
    DECLARE bill_amount INT;
    DECLARE rand_payment_status VARCHAR(10);

    WHILE counter < 5000 DO
        SET rand_helper_id = FLOOR(1 + (RAND() * 6)); -- Pick random helper (we have 6)
        SET rand_gender = ELT(FLOOR(1 + (RAND() * 4)), 'Male', 'Female', 'Fmale', 'Mle');
        SET dob = DATE_ADD('1970-01-01', INTERVAL FLOOR(RAND() * 14600) DAY);
        SET visit = DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 1825) DAY);
        SET bill_amount = FLOOR(1000 + (RAND() * 49000));
        SET rand_payment_status = ELT(FLOOR(1 + (RAND() * 3)), 'Paid', 'Unpaid', '');

        INSERT INTO patients (
            full_name,
            gender,
            date_of_birth,
            phone_number,
            email,
            address,
            state_of_origin,
            doctor_id,
            doctor_name,
            department,
            diagnosis,
            treatment,
            date_of_visit,
            amount_billed,
            payment_status,
            next_of_kin,
            relationship_to_patient,
            emergency_contact,
            insurance_provider
        )
        SELECT 
            full_name,
            rand_gender,
            IF(RAND() > 0.7, DATE_FORMAT(dob, '%d/%m/%Y'), DATE_FORMAT(dob, '%Y-%m-%d')),
            CONCAT('080', FLOOR(RAND()*10000000)),
            CONCAT(LOWER(REPLACE(full_name, ' ', '')), 
                   ELT(FLOOR(1 + (RAND() * 3)), '@gmail..com', '@yahoo', '@outlook.com')),
            CONCAT('No ', FLOOR(1 + (RAND()*100)), ' Street, ', state_of_origin),
            state_of_origin,
            rand_helper_id,
            doctor_name,
            department,
            diagnosis,
            treatment,
            IF(RAND() > 0.7, DATE_FORMAT(visit, '%m/%d/%Y'), DATE_FORMAT(visit, '%Y-%m-%d')),
            CONCAT('₦', FORMAT(bill_amount, 0)),
            rand_payment_status,
            CONCAT(full_name, ' Jr.'),
            relationship,
            CONCAT('080', FLOOR(RAND()*10000000)),
            IF(RAND() > 0.6, NULL, ELT(FLOOR(1 + (RAND() * 3)), 'Hygeia', 'AXA', 'Reliance'))
        FROM helpers
        WHERE id = rand_helper_id;

        SET counter = counter + 1;
    END WHILE;
END //

DELIMITER ;

-- Step 6: Run the Procedure
CALL generate_patients();

-- Step 7: Drop Procedure to Keep DB Clean
DROP PROCEDURE generate_patients;