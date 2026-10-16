/*
1.
create database project

create table Doctor(
SSN char(10) primary key,
FirstName nvarchar(30),
LastName nvarchar(30),
Specialty nvarchar(30),
YearsOfExperience int,
PhoneNum nvarchar(11))

create table Patient(
SSN char(10) primary key,
FirstName nvarchar(30),
LastName nvarchar(30),
Address nvarchar(50),
DOB date,
PrimaryDoctor_SSN char(10) foreign key references Doctor(SSN))

create table Medicine(
TradeName nvarchar(30) primary key,
UnitPrice int,
GenericFlag char(5))

create table Prescription(
Id int primary key,
Date date,
Doctor_SSN char(10) foreign key references Doctor(SSN),
Patient_SSN char(10) foreign key references Patient(SSN))

create table Prescription_Medicine(
PrescriptionId int foreign key references Prescription(Id),
TradeName nvarchar(30) foreign key references Medicine(TradeName),
NumOfUnits int
constraint Prescription_MedicineKey primary key (PrescriptionId, TradeName))

3.
select year(Prescription.Date), sum(Medicine.UnitPrice * Prescription_Medicine.NumOfUnits)
from Medicine, Prescription, Prescription_Medicine
where Medicine.TradeName = Prescription_Medicine.TradeName
and Prescription.Id = Prescription_Medicine.PrescriptionId
group by year(Prescription.Date) 

4.
select top(3) Patient.SSN, Patient.LastName,
sum(Medicine.UnitPrice * Prescription_Medicine.NumOfUnits) as TotalPrice
from Patient, Medicine, Prescription, Prescription_Medicine
where Patient.SSN = Prescription.Patient_SSN
and Medicine.TradeName = Prescription_Medicine.TradeName
and Prescription.Id = Prescription_Medicine.PrescriptionId
and year(Prescription.Date) = 1400
group by Patient.SSN, Patient.LastName
order by TotalPrice desc

5.
with PrescriptionCount as (
select top(1) count(Prescription.Id) as Num
from Patient, Prescription
where Patient.SSN = Prescription.Patient_SSN
group by Patient.SSN, Patient.FirstName, Patient.LastName
order by count(Prescription.Id) desc
)
select Patient.FirstName, Patient.LastName, count(Prescription.Id) as Num
from Patient, Prescription
where Patient.SSN = Prescription.Patient_SSN
group by Patient.SSN, Patient.FirstName, Patient.LastName
having count(Prescription.Id) = (select Num from PrescriptionCount)

6.
select Patient.LastName, Patient.FirstName, count(Prescription.Id) as Num
from Patient, Prescription
where Patient.SSN = Prescription.Patient_SSN
group by Patient.SSN, Patient.FirstName, Patient.LastName
having count(Prescription.Id) > 5
order by Patient.LastName, Patient.FirstName

7.
create function CalculateDrugCount (@DrugName nvarchar(30))
returns int 
as 
begin
	declare @DrugCount int
	set @DrugCount = (
	select sum(NumOfUnits)
	from Prescription_Medicine
	where TradeName = @DrugName
	group by TradeName)
	return @DrugCount
end 

create proc CalculateMaxDrugCount 
as
	select top(2) TradeName, dbo.CalculateDrugCount(TradeName) as DrugCount
	from Medicine
	order by DrugCount desc

8.
with temp (FirstName, LastName, Doctor_SSN, TradeName)
as (select distinct 
    Patient.FirstName, 
    Patient.LastName,
    Prescription.Doctor_SSN,
    Prescription_Medicine.TradeName
from Prescription_Medicine, Prescription, Patient
where Prescription.Id = Prescription_Medicine.PrescriptionId
and Patient.SSN = Prescription.Patient_SSN)
select FirstName, LastName, TradeName
from temp
group by FirstName, LastName, TradeName
having COUNT(TradeName) > 1
order by FirstName, TradeName

9.
select year(Prescription.Date), count(Prescription.Id)
from Prescription, Prescription_Medicine
where Prescription.Id = Prescription_Medicine.PrescriptionId
and Prescription_Medicine.TradeName = N'آسپرین'
and Prescription_Medicine.NumOfUnits = 1
group by year(Prescription.Date)

10.
select T1.Year1, T1.TotalCount, (T2.Count2 * 100 /T1.TotalCount) as 'percent'
from (select year(Date) as Year1, count(Id) as TotalCount
from Prescription
group by year(Date)) as T1,
(select year(Prescription.Date) as Year2, count(Prescription.Id) as count2
from Prescription, Prescription_Medicine
where Prescription_Medicine.PrescriptionId = Prescription.Id
and Prescription_Medicine.TradeName = N'آسپرین'
and Prescription_Medicine.NumOfUnits >= 1
group by year(Prescription.Date)) as T2
where T1.Year1 = T2.Year2 

11.
declare @MaxTypesCount int
set @MaxTypesCount = (
select top(1) count(TradeName)
from Prescription_Medicine
group by PrescriptionId
order by count(TradeName) desc)

select *
from Prescription as T1, 
(select PrescriptionId, count(TradeName) as TypesCount
from Prescription_Medicine
group by PrescriptionId
having count(TradeName) = @MaxTypesCount) as T2
where T2.PrescriptionId = T1.Id
order by T2.TypesCount desc

12.
declare @NewPrescription_Medicine table (PrescriptionId int,
TradeName nvarchar(30),
countMedicine int)

insert into @NewPrescription_Medicine 
select T1.PrescriptionId , T1.TradeName, T2.MedicineNumber
from Prescription_Medicine as T1, 
(select PrescriptionId , count(TradeName) as MedicineNumber
from Prescription_Medicine
group by PrescriptionId) as T2
where T1.PrescriptionId = T2.PrescriptionId

select top(1) P1.PrescriptionId, P2.PrescriptionId, count(P1.TradeName) as similarity
from @NewPrescription_Medicine as P1, @NewPrescription_Medicine as P2
where P1.PrescriptionId != P2.PrescriptionId
and P1.TradeName = P2.TradeName
group by P1.PrescriptionId, P1.countMedicine,
P2.PrescriptionId, P2.countMedicine
having (count(P1.TradeName) != P1.countMedicine 
and count(P1.TradeName) != P2.countMedicine)
order by similarity desc

13.
with asperin(asperin_SSN, asperin_FirstName, 
asperin_LastName, asperin_PrescriptionId,
asperin_Date, asperin_TradeName) 
as (select SSN, FirstName, LastName, PrescriptionId, Date, TradeName
    from Patient, Prescription, Prescription_Medicine
    where Patient.SSN = Prescription.Patient_SSN
    and Prescription.Id = Prescription_Medicine.PrescriptionId
    and TradeName = N'آسپرین')

Update Prescription_Medicine 
set TradeName = N'دیازپام'
where PrescriptionId in (
select distinct Prescription_Medicine.PrescriptionId
from Patient, Prescription, Prescription_Medicine, asperin
where Patient.SSN = Prescription.Patient_SSN
and Prescription.Id = Prescription_Medicine.PrescriptionId
and asperin.asperin_SSN = Patient.SSN
and TradeName = N'کلونازپام'
and asperin.asperin_Date < Date)

14.
create table Appointment (
TurnNumber int,
Date date,
Complain nvarchar(50),
Doctor_SSN char(10) foreign key references Doctor(SSN),
Patient_SSN char(10) foreign key references Patient(SSN),
PrescriptionId int foreign key references Prescription(Id)
constraint AppointmentKey primary key (TurnNumber, Date))

15-1.
create function PatientsList(@Date Date, @DoctorName nvarchar(30))
returns table 
as 
	return
	(select Patient.FirstName, Patient.LastName, Appointment.Complain
	from Patient, Doctor, Appointment
	where Patient.SSN = Appointment.Patient_SSN
	and Doctor.SSN = Appointment.Doctor_SSN
	and Doctor.LastName = @DoctorName
	and Appointment.Date = @Date)

15-2.
select Appointment.TurnNumber, Appointment.Complain, Prescription_Medicine.TradeName 
from Appointment, Prescription_Medicine
where Prescription_Medicine.PrescriptionId = Appointment.PrescriptionId
order by Appointment.Complain
*/