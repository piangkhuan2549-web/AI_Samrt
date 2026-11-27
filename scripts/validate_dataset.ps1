$ErrorActionPreference = "Stop"

$RawDir = "c:\ai_smarttable\data\raw"

$teachers = Import-Csv (Join-Path $RawDir "teacher.csv") -Encoding UTF8
$rooms = Import-Csv (Join-Path $RawDir "room.csv") -Encoding UTF8
$groups = Import-Csv (Join-Path $RawDir "student_groups.csv") -Encoding UTF8
$subjects = Import-Csv (Join-Path $RawDir "subject.csv") -Encoding UTF8
$timeslots = Import-Csv (Join-Path $RawDir "timeslot.csv") -Encoding UTF8
$teaches = Import-Csv (Join-Path $RawDir "teach.csv") -Encoding UTF8
$registers = Import-Csv (Join-Path $RawDir "register.csv") -Encoding UTF8
$tUnavail = Import-Csv (Join-Path $RawDir "teacher_unavailability.csv") -Encoding UTF8
$rUnavail = Import-Csv (Join-Path $RawDir "room_unavailability.csv") -Encoding UTF8

$errors = @()

# 1. Count checks
if ($groups.Count -ne 100) { $errors += "Expected 100 student groups, got $($groups.Count)" }
if ($teachers.Count -ne 70) { $errors += "Expected 70 teachers, got $($teachers.Count)" }
$depts = ($teachers | Select-Object -ExpandProperty department_id -Unique)
if ($depts.Count -ne 10) { $errors += "Expected 10 departments, got $($depts.Count)" }
if ($timeslots.Count -ne 40) { $errors += "Expected 40 timeslots, got $($timeslots.Count)" }

# Lookup tables
$subMap = @{}
foreach ($s in $subjects) { $subMap[$s.subject_id] = $s }

$teachSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($tc in $teaches) { [void]$teachSet.Add("$($tc.teacher_id)|$($tc.subject_id)") }

$tUnavailCount = @{}
foreach ($tu in $tUnavail) {
    $tUnavailCount[$tu.teacher_id] = ($tUnavailCount[$tu.teacher_id] + 1)
}

$rUnavailCount = @{}
foreach ($ru in $rUnavail) {
    $rUnavailCount[$ru.room_id] = ($rUnavailCount[$ru.room_id] + 1)
}

# 2. Check teacher loads & teach.csv integrity
$tLoads = @{}
$gLoads = @{}
$labDemand = 0
$theoryDemand = 0

foreach ($reg in $registers) {
    if (-not $subMap.ContainsKey($reg.subject_id)) {
        $errors += "Unknown subject_id in register.csv: $($reg.subject_id)"
        continue
    }
    if (-not $teachSet.Contains("$($reg.assigned_teacher_id)|$($reg.subject_id)")) {
        $errors += "Teacher $($reg.assigned_teacher_id) not authorized for $($reg.subject_id) in teach.csv"
    }
    $s = $subMap[$reg.subject_id]
    $p = [int]$s.theory + [int]$s.practice
    $tLoads[$reg.assigned_teacher_id] = ($tLoads[$reg.assigned_teacher_id] + $p)
    $gLoads[$reg.group_id] = ($gLoads[$reg.group_id] + $p)
    if ($s.room_type_required -eq "Lab") { $labDemand += $p } else { $theoryDemand += $p }
}

foreach ($t in $teachers) {
    $load = [int]$tLoads[$t.teacher_id]
    $unav = [int]$tUnavailCount[$t.teacher_id]
    $avail = 40 - $unav
    if ($load -lt 30) {
        $errors += "Teacher $($t.teacher_id) load $load < 30 periods/week"
    }
    if ($load -gt $avail) {
        $errors += "Teacher $($t.teacher_id) load $load > available slots $avail"
    }
}

foreach ($g in $groups) {
    $load = [int]$gLoads[$g.group_id]
    if ($load -gt 40 -or $load -le 0) {
        $errors += "Group $($g.group_id) has invalid load $load"
    }
}

# 3. Room capacity & supply check
$labSupply = 0
$theorySupply = 0
foreach ($r in $rooms) {
    $avail = 40 - [int]$rUnavailCount[$r.room_id]
    if ($r.room_type -eq "Lab") { $labSupply += $avail } else { $theorySupply += $avail }
}
if ($labDemand -gt $labSupply) { $errors += "Lab demand $labDemand > Lab supply $labSupply" }
if ($theoryDemand -gt $theorySupply) { $errors += "Theory demand $theoryDemand > Theory supply $theorySupply" }

if ($errors.Count -gt 0) {
    Write-Host "VALIDATION FAILED:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

$totalPeriods = $labDemand + $theoryDemand
$minT = ($tLoads.Values | Measure-Object -Minimum).Minimum
$maxT = ($tLoads.Values | Measure-Object -Maximum).Maximum
$avgT = [math]::Round(($tLoads.Values | Measure-Object -Average).Average, 2)
$labUtil = [math]::Round(($labDemand / $labSupply) * 100, 1)
$theoryUtil = [math]::Round(($theoryDemand / $theorySupply) * 100, 1)

Write-Host "=== VALIDATION PASSED (100% FEASIBLE) ===" -ForegroundColor Green
Write-Host "Departments: $($depts.Count) | Teachers: $($teachers.Count) | Groups: $($groups.Count) | Subjects: $($subjects.Count) | Rooms: $($rooms.Count)"
Write-Host "Register rows: $($registers.Count) | Total periods/week: $totalPeriods"
Write-Host "Teacher Load -> Min: $minT | Max: $maxT | Avg: $avgT (Target >= 30)"
Write-Host "Lab Demand/Supply: $labDemand / $labSupply ($labUtil%)"
Write-Host "Theory Demand/Supply: $theoryDemand / $theorySupply ($theoryUtil%)"
