-- Gym Membership Database Assignment
-- This SQL file includes table creation, sample data, and 10 propositions for the GymDB assignment

-- 1. Create Tables
CREATE TABLE Members (
    MemberID INT PRIMARY KEY,
    Name NVARCHAR(100),
    JoinDate DATE,
    MembershipType NVARCHAR(50),
    PaymentStatus NVARCHAR(20)
);

CREATE TABLE Visits (
    VisitID INT PRIMARY KEY,
    MemberID INT,
    VisitDate DATE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

CREATE TABLE Classes (
    ClassID INT PRIMARY KEY,
    ClassName NVARCHAR(100),
    MaxCapacity INT
);

CREATE TABLE Enrollments (
    MemberID INT,
    ClassID INT,
    EnrollDate DATE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
    FOREIGN KEY (ClassID) REFERENCES Classes(ClassID)
);

CREATE TABLE Trainers (
    TrainerID INT PRIMARY KEY,
    Name NVARCHAR(100)
);

CREATE TABLE TrainerAssignments (
    TrainerID INT,
    MemberID INT,
    FOREIGN KEY (TrainerID) REFERENCES Trainers(TrainerID),
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

-- 2. Insert Sample Data
-- Members
INSERT INTO Members VALUES (1, 'John Doe', '2025-09-01', 'Gold', 'Paid');
INSERT INTO Members VALUES (2, 'Jane Smith', '2025-09-10', 'Silver', 'Overdue');
INSERT INTO Members VALUES (3, 'Alice Brown', '2025-09-05', 'Gold', 'Paid');
INSERT INTO Members VALUES (4, 'Bob White', '2025-08-20', 'Bronze', 'Paid');

-- Visits
INSERT INTO Visits VALUES (1, 1, '2025-09-05');
INSERT INTO Visits VALUES (2, 1, '2025-09-12');
INSERT INTO Visits VALUES (3, 2, '2025-09-15');
INSERT INTO Visits VALUES (4, 3, '2025-09-18');
INSERT INTO Visits VALUES (5, 1, '2025-09-20');

-- Classes
INSERT INTO Classes VALUES (1, 'Yoga', 2);
INSERT INTO Classes VALUES (2, 'Spinning', 3);
INSERT INTO Classes VALUES (3, 'Pilates', 2);

-- Enrollments
INSERT INTO Enrollments VALUES (1, 1, '2025-09-05');
INSERT INTO Enrollments VALUES (2, 1, '2025-09-10');
INSERT INTO Enrollments VALUES (3, 2, '2025-09-12');

-- Trainers
INSERT INTO Trainers VALUES (1, 'Mike');
INSERT INTO Trainers VALUES (2, 'Sara');

-- TrainerAssignments
INSERT INTO TrainerAssignments VALUES (1, 1);
INSERT INTO TrainerAssignments VALUES (2, 2);

-- 3. 10 Propositions
-- Proposition 1: Top 10 Members by Visits
SELECT TOP 10 m.Name, COUNT(v.VisitID) AS VisitCount
FROM Members m
JOIN Visits v ON m.MemberID = v.MemberID
WHERE v.VisitDate >= DATEADD(MONTH, -1, GETDATE())
GROUP BY m.Name
ORDER BY VisitCount DESC;

-- Proposition 2: Members with Overdue Payments
SELECT Name, MembershipType, PaymentStatus
FROM Members
WHERE PaymentStatus = 'Overdue';

-- Proposition 3: Classes Full or Overbooked
SELECT c.ClassName, COUNT(e.MemberID) AS Enrolled, c.MaxCapacity
FROM Classes c
JOIN Enrollments e ON c.ClassID = e.ClassID
GROUP BY c.ClassName, c.MaxCapacity
HAVING COUNT(e.MemberID) >= c.MaxCapacity;

-- Proposition 4: Trainers with Most Clients
SELECT t.Name, COUNT(ta.MemberID) AS ClientCount
FROM Trainers t
JOIN TrainerAssignments ta ON t.TrainerID = ta.TrainerID
GROUP BY t.Name
ORDER BY ClientCount DESC;

-- Proposition 5: Members Signed Up in Last 30 Days
SELECT Name, JoinDate
FROM Members
WHERE JoinDate >= DATEADD(DAY, -30, GETDATE());

-- Proposition 6: Average Weekly Visits per Member
SELECT m.Name, CAST(COUNT(v.VisitID)/4.0 AS DECIMAL(5,2)) AS AvgWeeklyVisits
FROM Members m
JOIN Visits v ON m.MemberID = v.MemberID
WHERE v.VisitDate >= DATEADD(MONTH, -1, GETDATE())
GROUP BY m.Name;

-- Proposition 7: Membership Types with Most Sign-Ups
SELECT MembershipType, COUNT(MemberID) AS NumMembers
FROM Members
GROUP BY MembershipType
ORDER BY NumMembers DESC;

-- Proposition 8: Members Who Haven’t Attended Classes in Last Month
SELECT m.Name
FROM Members m
LEFT JOIN Enrollments e ON m.MemberID = e.MemberID
WHERE e.MemberID IS NULL
   OR e.EnrollDate < DATEADD(MONTH, -1, GETDATE());

-- Proposition 9: Trainers Without Members
SELECT t.Name
FROM Trainers t
LEFT JOIN TrainerAssignments ta ON t.TrainerID = ta.TrainerID
WHERE ta.MemberID IS NULL;

-- Proposition 10: Most Popular Class in Last 3 Months
SELECT TOP 1 c.ClassName, COUNT(e.MemberID) AS AttendanceCount
FROM Classes c
JOIN Enrollments e ON c.ClassID = e.ClassID
WHERE e.EnrollDate >= DATEADD(MONTH, -3, GETDATE())
GROUP BY c.ClassName
ORDER BY AttendanceCount DESC;