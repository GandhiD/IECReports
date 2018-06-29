
Declare @FromDate datetime
Declare @ToDate datetime

set @FromDate = '7/1/2016'
set @ToDate = '6/30/2017'

Declare @MyCounter int
declare @OPEID varchar(8)

set nocount on

--set @OPEID = '025593'  --HP
--set @OPEID = '039696'  --Gardena
--set @OPEID = '031133' --Fresno
set @OPEID = '023058' --FCC

if object_Id('tempdb..#tStudentPop') is not null begin
	drop table #tStudentPop
end
Create table #tStudentPop
(
	Studnum varchar(10) not null Primary Key,
	CampusCode int,
	SSN varchar(10),
	FirstName varchar(35),
	MiddleName varchar(35),
	LastName varchar(35),
	DOB	datetime,
	ProgCode varchar(20),
	StartDate datetime,
	StatusCode varchar(4),
	StatusName varchar(100),
	ProjectedGradDate datetime,
	GradDate datetime,
	DropDate datetime,
	CreditLoad int,
	TIVGrant money default(0),
	TIVLoan money default(0),
	mPrivateLoanAmt money default(0),
	mInstitutionalDebt money default(0),
	mTuitionFeeAmt money default(0),
	mBookSupplyAllowance money default(0),
	IsKeep bit default(0),
	IshasPerods bit default(0),
	IsCalcedStartDate bit default(0),
	ARCutoffDate datetime,
	TrueStartDate datetime
)
Create index tIDX_StudentPop_SSN  on #tStudentPop(SSN)


if object_Id('tempdb..#tEnrollPeriods') is not null begin
	drop table #tEnrollPeriods
end
Create table #tEnrollPeriods 
(
	PeriodID int not Null identity(1,1) Primary Key,
	Studnum varchar(10),
	PeriodNum int,
	CampusCode int,
	ProgCode varchar(20),
	EnrollStartDate datetime,
	NextChangeSequence int,
	EnrollEndDate datetime,
	EnrollEndStatusCode int,
	ProjectedGradDate datetime,
	TIVGrant money default(0),
	TIVLoan money default(0),
	mPrivateLoanAmt money default(0),
	mInstitutionalDebt money default(0),
	mTuitionFeeAmt money default(0),
	mBookSupplyAllowance money default(0),
	IsFirstPeriod bit default(0),
	IsLastPeriod bit default(0),
	TuitionPeriodStartDate datetime,
	TuitionPeriodEndDate datetime,
	IsHasTuitionOverlap bit default(0),
	PaymentPeriodStartDate datetime,
	PaymentPeriodEndDate datetime,
	IsHasPaymentOverlap bit default(0),
	IsFirstGrad bit default(0),
	DaysFromLastPeriod int default(0),
	IsUseForStartDate bit default(0)
)
Create index tIDX_tEnrollPeriods_Studnum  on #tEnrollPeriods(Studnum)
Create index tIDX_tEnrollPeriods_TuitionPeriodStartDate  on #tEnrollPeriods(TuitionPeriodStartDate)
Create index tIDX_tEnrollPeriods_TuitionPeriodEndDate  on #tEnrollPeriods(TuitionPeriodEndDate)
Create index tIDX_tEnrollPeriods_PaymentPeriodStartDate  on #tEnrollPeriods(PaymentPeriodStartDate)
Create index tIDX_tEnrollPeriods_PaymentPeriodEndDate  on #tEnrollPeriods(PaymentPeriodEndDate)


if object_Id('tempdb..#tGEout') is not null begin
	drop table #tGEout
end
Create Table #tGEout
(
	RID	int not null identity(1,1) Primary Key,
	RecordType	char(3),
	AwardYear	varchar(8),
	TscriptAwardYear varchar(10),
	SSN	varchar(9),
	FirstName	varchar(35),
	MiddleName	varchar(35),
	LastName	varchar(35),
	DOB	varchar(8),
	OPEID	varchar(8),
	InstitutionName	varchar(65),
	Filler1	char(1),
	ProgramName	varchar(80),
	CIPCode	varchar(6),
	CredentialLevel	char(2),
	MedDentalInternship	char(1),
	Filler2	char(1),
	StartDate	varchar(8),
	AwardYearStartDate	varchar(8),
	AttendStatus	char(1),
	AttendStatusDate	varchar(8),
	dAttendStatusDate datetime,
	PrivateLoanAmt	varchar(6),
	InstitutionalDebt	varchar(6),
	TuitionFeeAmt	varchar(6),
	BookSupplyAllowance	varchar(6),
	ProgramLength	varchar(60),
	ProgramMeasurement	char(1),
	EnrollStatus	char(1),
	Filler3	char(1),
	PeriodID int,
	TIVGrant money default(0),
	TIVLoan money default(0),
	mPrivateLoanAmt money default(0),
	mInstitutionalDebt money default(0),
	mTuitionFeeAmt money default(0),
	mBookSupplyAllowance money default(0),
	IsReport bit default(0)
)


declare @NoLastStatusMarker int
set @NoLastStatusMarker = 1000

Declare @Today datetime
set @Today = Convert(datetime,getdate(),101)


--*******************************************************************************************
--Set Up Campus To Report
--*******************************************************************************************
if object_Id('tempdb..#tCampus') is not null begin
	drop table #tCampus
end
Create table #tCampus
(
	CampusCode int not null Primary Key,
	CampusName varchar(100),
	OPEID varchar(10),
	InstitutionName varchar(65)
) 

Insert Into #tCampus 
(
	CampusCode,
	CampusName,
	OPEID,
	InstitutionName 
)
SElect
	mstC.CampusCode,
	mstC.Campus,
	mstC.OPEID ,
	mstC.CampusECARName 
FROM IEC_TSQL.dbo.mstCampus mstC
where left(mstC.OPEID,6) = @OPEID
and mstC.campusCode not in (2,3,9,43,44) --Closed campuses 
--where mstC.CampusCode < 18



--*******************************************************************************************
--Set Enrollment Codes
--*******************************************************************************************
if object_Id('tempdb..#tEnrollCodes') is not null begin
	drop table #tEnrollCodes
end
Create Table #tEnrollCodes
(
	StatusCode int not Null Primary key,
	Status varchar(100),
	IsLOA bit,
	IsCurrentStudent bit default(0),
	IsEnrollBegin bit default(0),
	IsEnrollEnd bit default(0),
	IsGrad bit default(0),
	IsDrop bit default(0),
	IsCancel bit default(0),
	GEStatus char(1)
)
Create Index tIDX_tEnrollCodes_Status on #tEnrollCodes(Status)

Insert Into #tEnrollCodes  
(
	StatusCode,
	Status
)
select
	StatusCode,
	Status
from IEC_TSQL.dbo.mstEnrollCodes




--Dao (set status codes for switches
Update #tEnrollCodes set IsCurrentStudent = 1 Where left(statuscode,1) in ('0','5')
Update #tEnrollCodes set IsLOA = 1 Where statuscode in ('160','170','175')
Update #tEnrollCodes set IsEnrollBegin = 1 where Left(statuscode,1) = '5'
Update #tEnrollCodes set IsEnrollEnd = 1 where left(statuscode,1) in ('6','7','4') and StatusCode<>'681'
Update #tEnrollCodes set IsDrop = 1 Where left(statuscode,1) = '6' and StatusCode<>'681'
Update #tEnrollCodes set IsGrad = 1 Where left(statuscode,1) = '7'
Update #tEnrollCodes set IsCancel = 1 Where left(statuscode,1) = '4' or StatusCode='681'


Update #tEnrollCodes set GEStatus = 'E' where IsCurrentStudent = 1
Update #tEnrollCodes set GEStatus = 'G' where IsGrad = 1
Update #tEnrollCodes set GEStatus = 'W' where IsDrop = 1

--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************


--select * from #tEnrollCodes
--return



--*******************************************************************************************
--Setup Program and Program Grouping
--*******************************************************************************************

if object_Id('tempdb..#tPrograms') is not null begin
	drop table #tPrograms
end
Create Table #tPrograms
(
	ProgCode varchar(20) not Null Primary Key,
	ProgName varchar(100),
	ProgGroup varchar(20),
	CIPCode varchar(20),
	CredentialLevel char(2),
	IsCurrentlyActive bit default(0),
	IsReport bit default(1),
	ProgLength int,
	ProgMeasure varchar(2)
)


Insert Into #tPrograms 
(
	Progcode,
	ProgName,
	ProgGroup,
	CredentialLevel ,
	CIPCode,
	ProgLength,
	ProgMeasure
)
select
	mstP.[Program Code] ,
	mstP.[GE Program Name] ,
	mstP.Grouping + '-' + mstP.[GE credential level code], 
	mstP.[GE credential level code] ,
	mstP.CIP,
	mstP.WEEKS,
	mstP.ProgMeasure
from IEC_Reports.dbo.tGE_Programs mstP
where mstP.[Is Report] = 1
--and mstP.isAddition = 1

--Update IEC_Reports.dbo.tGE_Programs set cip = '470604' where [Program Code] = 'CAT'

--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************




--*******************************************************************************************
--Setup Transaction Codes
--*******************************************************************************************

if object_Id('tempdb..#tTransCode') is not null begin
	drop table #tTransCode
end
Create table #tTransCode
(
	TransCode int Not Null Primary key,
	TransName varchar(100),
	IsTuitionCharge bit default(0),
	IsBooksSuppliesCharge bit default(0),
	IsPrivatLoan bit default(0),
	IsInstitutionLoan bit default(0),
	IsTIVGrant bit default(0),
	IsTIVLoan bit default(0),
	IsIgnoreForARBalance bit default(0),
	IsCountUpToStatusDate bit default(0)

)


Insert into #tTransCode 
(
	TransCode,
	TransName,
	IsTuitionCharge,
	IsBooksSuppliesCharge,
	IsPrivatLoan,
	IsInstitutionLoan,
	IsTIVGrant,
	IsTIVLoan,
	IsIgnoreForARBalance,
	IsCountUpToStatusDate

)
select
	mstTC.TransCode,
	mstTC.TransName,
	case when mstTC.[Charging Group] = 'TF' then 1 else 0 end as     IsTuitionCharge,
	case when mstTC.[Charging Group] = 'BS' then 1 else 0 end as    IsBookSupplyCharge,
	case when mstTC.[Payment Group] = 'P' then 1 else 0 end as  IsPrivateLoan,
	case when mstTC.[Payment Group] = 'I' then 1 else 0 end as  IsInstituitionLoan,
	case when mstTC.[Payment Group] = 'G' then 1 else 0 end as  IsScholarShipGrants,
	case when mstTC.[Payment Group] = 'T' then 1 else 0 end as  IsTitleIV,
	IsIgnoreForARBalance,
	IsCountUpToStatusDate
from iec_reports.dbo.tGE_TransCodes mstTC





--Payments
--P= Private loan
--I= Institutional loan/ debt
--G= Federal grants
--T= Title IV loans (for reference only- not included in GE reporting)

--Charges
--TF= Tuition and fees
--BS= Books and supplies


--Column J are the payments posted:

--P= private loan
--I= institutional loan
--G= title IV grant 
--T= title IV loan 


--Column K are the charging codes
--TF= tuition and fees
--BS= books and supplies

--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************



--*******************************************************************************************
--Setup Award Year Table
--*******************************************************************************************


Declare @FromYear int
Declare @ToYear int
Declare @ThisYear int

Declare @AwardYear varchar(5)
Declare @AwardYearStartDate datetime
Declare @AwardYearEndDate datetime
Declare @GEAwardYear varchar(8)

if object_Id('tempdb..#tAwardYears') is not null begin
	drop table #tAwardYears
end
Create Table #tAwardYears
(
	AwardYear varchar(8) Not Null Primary key,
	AwardYearStartDate datetime,
	AwardYearEndDate datetime,
	GEAwardYear varchar(8)
)

set @FromYear = year(@FromDate)
set @ToYear = year(@ToDate)

set @THisyear = @FromYear + 1

While @THisYear <= @ToYear begin

	set @AwardYear = right(cast(@ThisYear - 1 as varchar(4)),2) + '/' + right(cast(@ThisYear as varchar(4)),2)
	set @AwardYearStartDate = cast('7/1/' + cast(@ThisYear - 1 as varchar(4)) as datetime)
	set @AwardYearEndDate = cast('6/30/' + cast(@ThisYear as varchar(4)) as datetime)
	set @GEAwardYear =cast(@ThisYear - 1 as varchar(4)) + cast(@ThisYear as varchar(4))
	Insert Into #tAwardYears
	(
		AwardYear,
		AwardYearStartDate,
		AwardYearEndDate,
		GEAwardYear 
	)
	Values
	(
		@AwardYear,
		@AwardYearStartDate,
		@AwardYearEndDate,
		@GEAwardYear
	)

	set @ThisYear = @ThisYear + 1
end


--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************
--Collect Population For Report
--*******************************************************************************************

--Get all students starting befor the period end.
insert into #tStudentPop 
(
	Studnum,
	CampusCode,
	SSN,
	FirstName,
	MiddleName,
	LastName,
	DOB,
	ProgCode,
	StartDate,
	StatusCode,
	StatusName,
	ProjectedGradDate,
	GradDate,
	DropDate,
	TrueStartDate 
)
select
	mstS.Studnum,
	mstS.Campuscode,
	mstS.SSN,
	left(mstS.Firstname,35),
	left(mstS.MiddleName,35),
	left(mstS.LastName,35),
	mstS.BirthDate,
	mstS.ProgCode,
	mstS.OrigStartDate ,
	mstS.StatusCode,
	tE.Status,
	mstS.ProjectedGradDate,
	mstS.StatusDate,
	mstS.StatusDate ,
	mstS.OrigStartDate 
from IEC_TSQL.dbo.mstStudent mstS
inner join #tCampus tC
on mstS.Campuscode= tC.CampusCode 
inner join #tEnrollCodes tE
on mstS.StatusCode = tE.StatusCode 
where (mstS.StartDate1 <= @Todate or mstS.OrigStartDate <= @Todate )
and left(mstS.SSN,3) <> '000'
and right(mstS.SSN,4) <> '0000'
and SUBSTRING(mstS.SSN,4,2) <> '00'





--Mark Records to keep where status indicates active after period start
Update tS set
	IsKeep = 1
from #tStudentPop tS
inner join #tEnrollCodes tEC
on tS.statuscode = tEc.statusCode
where
(	
	(tS.GradDate  >= @FromDate and tEC.IsGrad = 1)
	or
	(tS.DropDate >= @FromDate and tEC.IsDrop = 1)
	or
	(tEC.IsCurrentStudent = 1)
)


--TestCode
select @MyCounter = @@ROWCOUNT
Print 'Base Pop:' + cast(@MyCounter as varchar(10))


--Remove UnNeeded Students
delete from #tStudentPop where Iskeep = 0


--*******************************************************************************************
--Set Credit Load
--*******************************************************************************************

--All IEC student set to full credit load
Update #tStudentPop set creditLoad = 12






--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************


--*******************************************************************************************
--Build Student Enrollment History
--*******************************************************************************************
if object_Id('tempdb..#tStatusChanges') is not null begin
	drop table #tStatusChanges
end
Create Table #tStatusChanges
(
	RId int not null identity(1,1) Primary Key,
	Studnum varchar(10),
	ChangeSequence int,
	StatusCode varchar(5),
	StatusDate datetime,
	ProgCode int,
	StatusChangeDate datetime,
	StatusDateChangeDate datetime
)



--Collect All Pertinent Status Changes (Begining and Ending)
--Use Date Order to generate change sequence
Insert into #tStatusChanges 
(
	Studnum,
	ChangeSequence,
	StatusCode,
	StatusDate,
	StatusChangeDate 
)
select
	sL.Studnum,
	sL.ChangeSequence,
	sL.NewStatusCode ,
	sL.NewStatusDate ,
	sL.ProcessDate  
From IEC_TSQL.dbo.ldgEnrollment sL
inner join #tStudentPop sP
on sL.Studnum = sP.STudnum
inner Join #tEnrollCodes tEC
on sL.NewStatusCode = tEC.StatusCode 
where sL.IsComplete = 1 
and sL.IsVoid = 0
and (tEC.IsEnrollBegin = 1 or tEC.isEnrollEnd = 1)
order by
	sL.Studnum,
	sL.NewStatusDate 


--TestCode
select @MyCounter =  count( Studnum) from (select studnum from #tStatusChanges group by studnum) q1
Print 'Student With Status Changes:' + cast(@MyCounter as varchar(10))



--Create a period for every start (Active) status Change
Insert Into #tEnrollPeriods 
(
	Studnum,
	CampusCode,
	ProgCode,
	EnrollStartDate,
	NextChangeSequence,
	ProjectedGradDate
)
select
	tSP.Studnum,
	tSP.CampusCode,
	tSP.ProgCode,
	convert(datetime,tSC_Begin.statusDate,100),
	Min(isnull(tSC_End.ChangeSequence,@NoLastStatusMarker)) as NextStatusChangeSequence,
	tSP.ProjectedGradDate
from #tStatusChanges tSC_Begin
inner join #tStudentPop tSP
on tSC_Begin.Studnum = tSP.studnum
Inner join #tEnrollCodes tEC
on tSC_Begin.statuscode = tEC.statusCode
Left join #tStatusChanges tSC_End
on tSC_Begin.Studnum = tSC_End.Studnum
and tSC_Begin.ChangeSequence < tSC_End.ChangeSequence 
where tEC.IsEnrollBegin = 1
Group By
	tSP.Studnum,
	tSP.CampusCode,
	tSP.ProgCode,
	tSP.ProjectedGradDate,
	tSC_Begin.statusDate

set  @MyCounter = @@ROWCOUNT
Print 'Periods Generated:' + cast(@MyCounter as varchar(10))

Update tEP set
	EnrollEndStatusCode = tSC.StatusCode,
	EnrollEndDate = convert(datetime,tSC.StatusDate,100)
from #tEnrollPeriods tEP
inner join #tStatusChanges tSC
on tEP.studnum = tSC.Studnum
and tEP.NextChangeSequence = tSC.ChangeSequence 
inner join #tEnrollCodes tEC
on tSC.StatusCode = tEC.StatusCode 

select  @MyCounter = count( distinct Studnum)  from #tEnrollPeriods 
Print 'Student with periods:' + cast(@MyCounter as varchar(10))


Delete from tEP
From #tEnrollPeriods tEP
inner join #tEnrollCodes tEC
on tEP.EnrollEndStatusCode = tEC.StatusCode 
where tEC.IsEnrollBegin = 1
or tEC.IsCancel = 1

set  @MyCounter = @@ROWCOUNT
Print 'Deleted Periods:' + cast(@MyCounter as varchar(10))


--Clean up
--Remove Duplicate Grad Periods (Use first Period)

Update tEP set
	IsFirstGrad = 1,
	NextChangeSequence = @NoLastStatusMarker
from #tEnrollPeriods tEP
inner join 
(
	select 
		tEP.studnum,
		min(tEP.PeriodID) as FirstGradId 
	From #tEnrollPeriods tEP
	inner join
	(
		select
			studnum,
			min(tP.EnrollEndDate) as FirstGradDate
		from #tEnrollPeriods tP
		where tP.EnrollEndStatusCode = '700'
		Group by
			Studnum
	) q1
	on tEP.studnum = q1.studnum
	and tEP.EnrollEndDate = q1.FirstGradDate 
	where tEP.EnrollEndStatusCode = '700'
	Group By
		tEP.STudnum
) q2
on tEP.PeriodID = q2.FirstGradId 
Delete from #tEnrollPeriods where IsFirstGrad = 0  and EnrollEndStatusCode = '700'


--For students with multiple term periods use the last on starting up to report period begin date

Update tEP set
	PeriodNum = q1.PeriodNum
from #tEnrollPeriods tEP
inner join 
(
	select
		tEP.PeriodID,
		ROW_NUMBER() over (Partition By tEP.studnum Order by tEP.EnrollStartDate) as PeriodNum	
	from #tEnrollPeriods tEP
) q1
on tEP.PeriodID = q1.PeriodID 



Update tEP set
	DaysFromLastPeriod = q1.OutofSchoolDays 
from #tEnrollPeriods tEP
inner join 
(
	select
		tEP.PeriodId,
		tEP.PeriodNum,
		datediff(d,tEPSub.EnrollEndDate,tEP.EnrollStartDate) as OutofSchoolDays	
	from #tEnrollPeriods tEP
	inner join #tEnrollPeriods tEPSub
	on tEP.studnum = tEPSub.studnum
	and tEP.PeriodNum - 1 = tEPSub.PeriodNum
) q1
on tEP.PeriodID = q1.PeriodID 



Update tEP set
	IsUseForStartDate = 1
from #tEnrollPeriods tEP
inner join
(
	select
		tEP.studnum,
		Min(PeriodNum) mPeriodNum
	from #tEnrollPeriods tEP
	Where tEP.EnrollEndDate > @FromDate
	group by tEP.studnum
) q1
on tEP.studnum = q1.studnum
and tEP.PeriodNum = q1.mPeriodNum 
where tEP.DaysFromLastPeriod > 365



set  @MyCounter = @@ROWCOUNT
Print 'Students with Extend Out of School Periods:' + cast(@MyCounter as varchar(10))

Delete from tEP
From #tEnrollPeriods tEP
inner join 
(
	select	
		studnum,
		PeriodNum
	from #tEnrollPeriods 
	where IsUseForStartDate = 1
) q1
on tEP.studnum = q1.studnum
and tEP.PeriodNum < q1.PeriodNum 

Update tSP set
	IsCalcedStartDate = 1,
	StartDate = teP.EnrollStartDate 
from #tStudentPop tSP
join #tEnrollPeriods tEP
on tSP.studnum = tep.studnum
where tEP.IsUseForStartDate = 1

set  @MyCounter = @@ROWCOUNT
Print 'Periods Removed for Extended Out of school time:' + cast(@MyCounter as varchar(10))


--Udpate records with change sequence of 1000 to data from mstStudent'
Update tEP set
	EnrollEndStatusCode = tSP.StatusCode,
	EnrollEndDate = convert(datetime,case 
				when tEC.IsDrop = 1 then tSP.DropDate 
				when tEC.IsGrad = 1 then tSP.GradDate 
				When tEC.IsCurrentStudent = 1 then @Today
				when tEC.IsCancel = 1 then tEP.EnrollStartDate 
				else Null end,100)
from #tEnrollPeriods tEP
inner join #tStudentPop tSP
on tEP.Studnum = tSP.Studnum
inner join #tEnrollCodes tEC
on tSP.Statuscode = tEC.StatusCode 
where tEP.NextChangeSequence = @NoLastStatusMarker


Update tEP set
	IsFirstPeriod = qP.IsFirstPeriod,
	TuitionPeriodStartDate = qP.PeriodBeginDate  ,
	TuitionPeriodEndDate = qP.PeriodEndDate,
	IsHasTuitionOverlap = qP.IsHasPeriodOverlap

from #tEnrollPeriods tEP
inner join
(
	select
		tEP.PeriodID,
		tEP.EnrollEndDate as PeriodEndDate,
		max(case when tEP2.PeriodID is null then 1 else 0 end) as IsFirstPeriod,
		Max(case when isnull(tEP2.EnrollEndDate,tEP.EnrollStartDate  )+ 1 > tEP.EnrollStartDate then tEP.EnrollStartDate else isnull(tEP2.EnrollEndDate,tEP.EnrollStartDate ) + 1 end) as PeriodBeginDate,
		Max(case when isnull(tEP2.EnrollEndDate,tEP.EnrollStartDate ) > tEP.EnrollStartDate then 1 else 0 end) as IsHasPeriodOverlap 
	from #tEnrollPeriods tEP
	inner join #tStudentPop tSP
	on tEP.studnum = tSP.Studnum
	Left join #tEnrollPeriods tEP2
	on tEP.studnum = tEP2.studnum
	and tEP2.EnrollStartDate < tEP.EnrollEndDate
	and tEP2.PeriodID <> tEP.PeriodID
	Group By
		tEP.PeriodID,
		tEP.EnrollEndDate
) qP
on tEP.PeriodID = qP.PeriodID


Update tEP set
	IsLastPeriod = qP.IsLastPeriod,
	PaymentPeriodStartDate = qP.PeriodBeginDate ,
	PaymentPeriodEndDate = qP.PeriodEndDate,
	IsHasPaymentOverlap = qp.IsHasPeriodOverlap  
from #tEnrollPeriods tEP
inner join
(
	
	select
		tEP.PeriodID,
		tEP.EnrollStartDate  as PeriodBeginDate,
		max(case when tEP2.PeriodID is null then 1 else 0 end) as IsLastPeriod,
		Min(case when isnull(tEP2.EnrollStartDate,tEP.EnrollEndDate  ) -1 < tEP.EnrollEndDate  then tEP.EnrollStartDate else isnull(tEP2.EnrollStartDate,tEP.EnrollEndDate )-1 end) as PeriodEndDate, 
		Min(case when isnull(tEP2.EnrollStartDate,tEP.EnrollEndDate )-1 < tEP.EnrollEndDate then 1 else 0 end) as IsHasPeriodOverlap 
	from #tEnrollPeriods tEP
	inner join #tStudentPop tSP
	on tEP.studnum = tSP.Studnum
	Left join #tEnrollPeriods tEP2
	on tEP.studnum = tEP2.studnum
	and tEP2.EnrollEndDate  > tEP.EnrollStartDate
	and tEP2.PeriodID <> tEP.PeriodID
	Group By
		tEP.PeriodID,
		tEP.EnrollStartDate
) qp
on tEP.PeriodID = qP.PeriodID 




Update #tEnrollPeriods set 
	TuitionPeriodStartDate = '1/1/1900',
	PaymentPeriodStartDate = '1/1/1900'
where IsFirstPeriod = 1


Update #tEnrollPeriods set 
	TuitionPeriodEndDate  = '12/31/2900',
	PaymentPeriodEndDate  = '12/31/2900'
where IsLastPeriod  = 1


if object_Id('tempdb..#tAR') is not null begin
	drop table #tAR
end
Create table #tAR 
(
	ARID int,
	StudNum varchar(10),
	SSN varchar(10),
	transcode varchar(4),
	TransPostDate datetime,
	TransAmt money,
	EnrollmentID int,
	PeriodID int
)



--Dao: Add Student number and SSN to this query
Insert into #tAR
(
	ARID,
	StudNum,
	SSN,
	transcode,
	TransPostDate,
	TransAmt
)
select
	tAR.PKID,
	tAR.Studnum,
	tSP.SSN,
	tAR.TransCode,
	tAR.TransPostDate,
	tAR.TransAmt 
from #tStudentPop tSP
inner join IEC_TSQL.dbo.ldgAR tAR
on tSP.Studnum = tAR.Studnum
and 1 = case when tSP.IsCalcedStartDate = 1 and tAR.TransPostDate < tSP.StartDate then 0 else 1 end




--Combine Period Total (Tuition/Books/Private Loans)
if object_Id('tempdb..#tStudentCIPTotals') is not null begin
	drop table #tStudentCIPTotals
end
Create table #tStudentCIPTotals
(
	RID int not null identity(1,1) Primary key,
	SSN varchar(10),
	CIPCODE varchar(20),
	TuitionAmt money default(0),
	BooksFeesAmt money default(0),
	PrivateLoan money default(0)
)

insert into #tStudentCIPTotals 
(
	SSN,
	CIPCODE,
	TuitionAmt,
	BooksFeesAmt
	--PrivateLoan 
)
select
	tSP.SSN,
	tP.Cipcode,
	sum(case when tC.IsTuitionCharge = 1 then tR.TransAmt else 0 end) as TutionAmt,
	sum(case when tC.IsBooksSuppliesCharge = 1 then tR.TransAmt else 0 end) as BooksFeesAmt 
	--sum(case when tC.IsPrivatLoan = 1 then tR.TransAmt * -1 else 0 end) as PrivateLoan
from #tStudentPop tSP
inner join #tPrograms  tP
on tsP.ProgCode = tp.Progcode  
inner join #tAR tR
on tsp.studnum = tR.StudNum
inner join #tTransCode tC
on tR.transcode = tc.TransCode 
where tR.TransPostDate<=@ToDate
Group by
	tSP.SSN,
	tP.Cipcode


Insert Into #tGEout
(
	RecordType, --	char(3),
	AwardYear, --	varchar(8),
	TscriptAwardYear,
	SSN, --	varchar(9),
	FirstName, --	varchar(35),
	MiddleName, --	varchar(35),
	LastName, --	varchar(35),
	DOB, --	varchar(8),
	OPEID, --	varchar(8),
	InstitutionName, --	varchar(65),
	Filler1, --	char(1),
	ProgramName, --	varchar(80),
	CIPCode, --	varchar(6),
	CredentialLevel, --	char(2),
	MedDentalInternship, --	char(1),
	Filler2, --	char(1),
	StartDate, --	varchar(8),
	AwardYearStartDate, --	varchar(8),
	AttendStatus, --	char(1),
	AttendStatusDate, --	varchar(8),
	dAttendStatusDate,
	PrivateLoanAmt, --	varchar(6),
	InstitutionalDebt, --	varchar(6),
	TuitionFeeAmt, --	varchar(6),
	BookSupplyAllowance, --	varchar(6),
	ProgramLength, --	varchar(60),
	ProgramMeasurement, --	char(1),
	EnrollStatus, --	char(1),
	Filler3, --	char(1),
	PeriodID -- int
)
select
	'001', --RecordType, --	char(3),
	tAW.GEAwardYear , --	varchar(8),
	tAW.AwardYear,
	tSP.SSN, --	varchar(9),
	left(tSP.FirstName,35), --	varchar(35),
	left(tSP.MiddleName,35), --	varchar(35),
	left(tSP.LastName,35), --	varchar(35),
	IEC_tsql.dbo.udfDateFormat(tSP.DOB,7), --	varchar(8),
	tC.OPEID, --	varchar(8),
	left(tC.InstitutionName,65), --	varchar(65),
	'', --Filler1, --	char(1),
	left(tP.ProgName,80) , --	varchar(80),
	left(tP.CIPCode,6), --	varchar(6),
	tP.CredentialLevel, --	char(2),
	0, --MedDentalInternship, --	char(1),
	'', --Filler2, --	char(1),
	IEC_tsql.dbo.udfDateFormat(tSP.StartDate,7), --	varchar(8),
	IEC_tsql.dbo.udfDateFormat(case when tEP.EnrollStartDate > tAW.AwardYearStartDate then tEP.EnrollStartDate else tAW.AwardYearStartDate end,7), --AwardYearStartDate, --	varchar(8),
	case when tEP.EnrollEndDate > tAW.AwardYearEndDate then 'E' else tEC.GEStatus end, --    AttendStatus, --	char(1),
	IEC_tsql.dbo.udfDateFormat(case when tEP.EnrollEndDate > tAW.AwardYearEndDate then tAW.AwardYearEndDate  else tEP.EnrollEndDate  end,7), -- AttendStatusDate, --	varchar(8),
	case when tEP.EnrollEndDate > tAW.AwardYearEndDate then tAW.AwardYearEndDate  else tEP.EnrollEndDate  end,
	'0' , --PrivateLoanAmt, --	varchar(6),
	'0' , --InstitutionalDebt, --	varchar(6),
	'0' , --TuitionFeeAmt, --	varchar(6),
	'0' , --BookSupplyAllowance, --	varchar(6),
	cast(tP.ProgLength as varchar(3)) +  '000' , --ProgramLength, --	varchar(60),
	tP.ProgMeasure  , --ProgramMeasurement, --	char(1),
	'F' , --EnrollStatus, --	char(1),
	'', --Filler3, --	char(1),
	tEP.PeriodID -- int
from #tEnrollPeriods tEP
inner join #tEnrollCodes tEC
on tEP.EnrollEndStatusCode = tEC.StatusCode
inner join #tStudentPop tSP
on tEP.Studnum = tSP.studnum
inner join #tCampus tC
on tEP.CampusCode = tC.CampusCode 
inner join #tPrograms tP
on tEP.ProgCode = tP.ProgCode 
cross join #tAwardYears tAW
Where tEP.EnrollStartDate <= tAW.AwardYearEndDate 
and tEP.EnrollEndDate >= tAW.AwardYearStartDate  
Order by 
	tSP.SSN,
	tP.CIPCode,	
	tAW.AwardYearStartDate




set @MyCounter = @@ROWCOUNT 
Print 'GE Records Created:' + cast(@MyCounter as varchar(10))




Update tG set 
	mTuitionFeeAmt = tscp.TuitionAmt,
	mBookSupplyAllowance = tscp.BooksFeesAmt
	--mPrivateLoanAmt = tscp.PrivateLoan 
from #tGEout tG
inner join #tStudentCIPTotals tSCP
on tg.ssn = tscp.ssn
and tG.CIPCode = tscp.CIPCODE 
where AttendStatus in ('G','W') 



Update tG set
	TIVGrant = qfed.tg,
	TIVLoan = qfed.tl
from #tGEout tG
inner join 
(
select
	tG.RID,
	sum(case when tTC.IsTIVGrant = 1 then tAR.TransAmt else 0 end) as TG,
	sum(case when tTC.IsTIVLoan = 1 then tAR.TransAmt else 0 end) as tL
from #tGEout tG
inner join #tAwardYears tAW
on tg.TscriptAwardYear  = tAW.AwardYear
inner join #tAR tAR
on tG.ssn = tAR.SSN
inner join #tTransCode tTC
on tAr.transcode = tTC.TransCode 
--where tAR.TransPostDate between tAW.AwardYearStartDate and tAW.AwardYearEndDate 
Group by 
	tG.RId
) qFed
on tG.RId = qFed.RId


Update tG set
	mInstitutionalDebt = case when AttendStatus<>'E' then case when qb.ARBalanceasofStatusDate<0 then 0 else qb.ARBalanceasofStatusDate end else 0 end,
	mPrivateLoanAmt=qB.PrivateDebtasofStatusDate
from #tGEout tG
inner join 

(
	select 
		mstS.SSN,
		mstP.CIPCode as CIPCode,
		mstC.OPEID,
		ts.dAttendStatusDate,
		sum
			(
				case 
				when tr.TransPostDate <= ts.dAttendStatusDate  then tR.TransAmt 
				else 0 end
			) ARBalanceasofStatusDate,
			
		sum
			(
				case when tr.TransPostDate <= ts.dAttendStatusDate and tTC.IsPrivatLoan = 1 then tR.TransAmt * -1 
				else 0 end
			) as PrivateDebtasofStatusDate
	from #tGEout ts 
	inner join IEC_TSQL.dbo.mstStudent mstS
	on tS.SSN = mstS.SSN
	inner join IEC_TSQL.dbo.mstCampus mstC
	on mstS.campuscode = mstC.Campuscode
	and tS.OPEID = mstC.OPEID
	inner join	IEC_TSQL.dbo.ldgAR tR 
	on tr.Studnum=mstS.Studnum
	inner join IEC_TSQL.dbo.mstProgram mstP
	on mstS.ProgCode=mstP.ProgCode and ts.CIPCode=mstP.CIPCode
	inner join #tTransCode tTC
	on tR.transcode = tTC.TransCode 
	Where tTC.IsIgnoreForARBalance = 0
	Group By
		mstS.SSN, mstP.CIPCode,mstC.OPEID,ts.dAttendStatusDate
) qB
on tG.ssn = qB.SSN and tG.CIPCode=qB.CIPCode and tG.OPEID=qb.OPEID and tg.dAttendStatusDate=qB.dAttendStatusDate




Update tG set
	IsReport = 1
from #tGEout tG
inner join 
(
	select
		SSN,
		CIPCode,
		Min(RID) as FirstTIV
	from #tGEout tG
	where tg.TIVGrant <> 0 or tG.TIVLoan <> 0
	Group By
		SSN,
		CIPCode 
) qTIV
on tG.SSN = qTIV.ssn
and tG.CIPCode = qTIV.CIPCode
where tG.RID >= qTIV.FirstTIV 




-------------------------------------------------------

declare @batchID varchar(50)
	
	set @batchID = 'B' + case len(datepart(mm,GETDATE())) when 1 then '0' + cast(datepart(mm,GETDATE()) as varchar(2)) else  cast(datepart(mm,GETDATE()) as varchar(2)) end
					   + case len(datepart(dd,GETDATE())) when 1 then '0' + cast(datepart(dd,GETDATE()) as varchar(2)) else  cast(datepart(dd,GETDATE()) as varchar(2)) end
					   + cast(datepart(yy,GETDATE()) as varchar(4))  
					   + case len(datepart(hh,GETDATE())) when 1 then '0' + cast(datepart(hh,GETDATE()) as varchar(2)) else  cast(datepart(hh,GETDATE()) as varchar(2)) end
					   + case len(datepart(mi,GETDATE())) when 1 then '0' + cast(datepart(mi,GETDATE()) as varchar(2)) else  cast(datepart(mi,GETDATE()) as varchar(2)) end
					   + case len(datepart(ss,GETDATE())) when 1 then '0' + cast(datepart(ss,GETDATE()) as varchar(2)) else  cast(datepart(ss,GETDATE()) as varchar(2)) end

----------------------------------------------- HEADER -----------------------------------

insert into IEC_Reports.dbo.tGE_OUTPUT_Header
(
	RecordType,
	Filler1,
	HeaderText,
	SubmittalDate,
	FileType,
	Filler2,
	OPEID,
	Filler3,
	GEReportBatchID
)

select
	'000',
	'',
	'GE STUDENT SUBMITTAL',
	convert(varchar(8),getdate(),112),
	'S',
	'',
	left(OPEID,6),
	'',
	@batchID
from #tGEout
where IsREport = 1
group by left(OPEID,6)


----------------------------------------------- DETAILS -----------------------------------

insert into IEC_Reports.dbo.tGE_OUTPUT
(
	GEReportBatchID,
	RecordType,
	AwardYear,
	SSN,
	FirstName,
	MiddleName,
	LastName,
	DOB,
	OPEID,
	InstitutionName,
	Filler1,
	ProgramName,
	CIPCode,
	CredentialLevel,
	MedDentalInternship,
	Filler2,
	StartDate,
	AwardYearStartDate,
	AttendStatus,
	AttendStatusDate,
	PrivateLoanAmt,
	InstitutionalDebt,
	TuitionFeeAmt,
	BookSupplyAllowance,
	ProgramLength,
	ProgramMeasurement,
	EnrollStatus,
	Filler3,
	PeriodID,
	TIVGrant,
	TIVLoan,
	mPrivateLoanAmt,
	mInstitutionalDebt,
	mTuitionFeeAmt,
	mBookSupplyAllowance
)	


select 
	@batchID ,
	RecordType,
	AwardYear,
	SSN,
	FirstName,
	MiddleName,
	LastName,
	DOB,
	OPEID,
	InstitutionName,
	Filler1,
	ProgramName,
	CIPCode,
	CredentialLevel,
	'N',
	Filler2,
	StartDate,
	AwardYearStartDate,
	AttendStatus,
	AttendStatusDate,
	PrivateLoanAmt,
	InstitutionalDebt,
	TuitionFeeAmt,
	BookSupplyAllowance,
	ProgramLength,
	ProgramMeasurement,
	EnrollStatus,
	Filler3,
	PeriodID,
	TIVGrant,
	TIVLoan,
	mPrivateLoanAmt,
	mInstitutionalDebt,
	mTuitionFeeAmt,
	mBookSupplyAllowance
from #tGEout
where IsREport = 1
order by SSN,AwardYear 

select @batchID 
return


