$ErrorActionPreference = "Stop"

$RawDir = "c:\ai_smarttable\data\raw"
$OutFile = "c:\ai_smarttable\data\dataset_bundle.js"

$teachersRaw = Import-Csv (Join-Path $RawDir "teacher.csv") -Encoding UTF8
$roomsRaw = Import-Csv (Join-Path $RawDir "room.csv") -Encoding UTF8
$groupsRaw = Import-Csv (Join-Path $RawDir "student_groups.csv") -Encoding UTF8
$subjectsRaw = Import-Csv (Join-Path $RawDir "subject.csv") -Encoding UTF8
$timeslotsRaw = Import-Csv (Join-Path $RawDir "timeslot.csv") -Encoding UTF8
$teachesRaw = Import-Csv (Join-Path $RawDir "teach.csv") -Encoding UTF8
$registersRaw = Import-Csv (Join-Path $RawDir "register.csv") -Encoding UTF8
$tUnavailRaw = Import-Csv (Join-Path $RawDir "teacher_unavailability.csv") -Encoding UTF8
$rUnavailRaw = Import-Csv (Join-Path $RawDir "room_unavailability.csv") -Encoding UTF8

# Map timeslot_id -> day, period
$tsMap = @{}
foreach ($ts in $timeslotsRaw) {
    $tsMap[$ts.timeslot_id] = @{ day = $ts.day; period = [int]$ts.period }
}

function Build-UnavailString {
    param($rows, $idField)
    $byId = @{}
    foreach ($r in $rows) {
        $id = $r.$idField
        $ts = $tsMap[$r.timeslot_id]
        if (-not $ts) { continue }
        if (-not $byId.ContainsKey($id)) { $byId[$id] = @() }
        $byId[$id] += "$($ts.day):$($ts.period)"
    }
    $out = @{}
    foreach ($k in $byId.Keys) {
        $out[$k] = ($byId[$k] -join "|")
    }
    return $out
}

$tUnavailMap = Build-UnavailString -rows $tUnavailRaw -idField "teacher_id"
$rUnavailMap = Build-UnavailString -rows $rUnavailRaw -idField "room_id"

# Departments
$deptMap = @{}
$departments = @()
foreach ($t in $teachersRaw) {
    if (-not $deptMap.ContainsKey($t.department_id)) {
        $deptMap[$t.department_id] = $t.department_name
        $departments += [PSCustomObject]@{
            department_id   = $t.department_id
            department_name = $t.department_name
        }
    }
}

# Teachers
$teachers = @()
foreach ($t in $teachersRaw) {
    $teachers += [PSCustomObject]@{
        teacher_id      = $t.teacher_id
        teacher_name    = $t.teacher_name
        department_id   = $t.department_id
        department_name = $t.department_name
        target_min_load = [int]$t.target_min_load
        unavailability  = if ($tUnavailMap.ContainsKey($t.teacher_id)) { $tUnavailMap[$t.teacher_id] } else { "" }
        password        = "1234"
    }
}

# Rooms
$rooms = @()
$deptLabRooms = @{}
$deptTheoryRooms = @{}
foreach ($r in $roomsRaw) {
    $rooms += [PSCustomObject]@{
        room_id        = $r.room_id
        room_name      = $r.room_name
        room_type      = $r.room_type
        capacity       = [int]$r.capacity
        department_id  = $r.department_id
        unavailability = if ($rUnavailMap.ContainsKey($r.room_id)) { $rUnavailMap[$r.room_id] } else { "" }
    }
    if ($r.room_type -eq "Lab") {
        if (-not $deptLabRooms.ContainsKey($r.department_id)) { $deptLabRooms[$r.department_id] = @() }
        $deptLabRooms[$r.department_id] += $r.room_id
    } else {
        if (-not $deptTheoryRooms.ContainsKey($r.department_id)) { $deptTheoryRooms[$r.department_id] = @() }
        $deptTheoryRooms[$r.department_id] += $r.room_id
    }
}

# Student Groups & Demo Students (1 representative per group, with 69319100035 in G002)
$studentGroups = @()
$students = @()
$idx = 1
foreach ($g in $groupsRaw) {
    $studentGroups += [PSCustomObject]@{
        group_id      = $g.group_id
        group_name    = $g.group_name
        student_count = [int]$g.student_count
        advisor       = $g.advisor
        department_id = $g.department_id
        level         = $g.level
    }
    if ($g.group_id -eq "G002") {
        $students += [PSCustomObject]@{
            student_id    = "69319100035"
            short_id      = "035"
            student_name  = "นางสาวเพียงขวัญ โสกูล"
            group_id      = $g.group_id
            department_id = $g.department_id
            password      = "1234"
        }
    } else {
        $sid = "69319100{0:D3}" -f $idx
        $students += [PSCustomObject]@{
            student_id    = $sid
            short_id      = "{0:D3}" -f $idx
            student_name  = "นักศึกษาตัวแทน $($g.group_id)"
            group_id      = $g.group_id
            department_id = $g.department_id
            password      = "1234"
        }
    }
    $idx++
}

# Subjects map
$subMap = @{}
foreach ($s in $subjectsRaw) { $subMap[$s.subject_id] = $s }
$grpMap = @{}
foreach ($g in $studentGroups) { $grpMap[$g.group_id] = $g }

# Courses (500 register rows -> 2,200 periods)
$courses = @()
$cIdx = 0
foreach ($reg in $registersRaw) {
    $s = $subMap[$reg.subject_id]
    $g = $grpMap[$reg.group_id]
    $did = $s.department_id
    $rList = if ($s.room_type_required -eq "Lab") { $deptLabRooms[$did] } else { $deptTheoryRooms[$did] }
    $prefRoom = $rList[$cIdx % $rList.Count]
    $cIdx++

    $th = [int]$s.theory
    $pr = [int]$s.practice
    $courses += [PSCustomObject]@{
        subject_id         = $s.subject_id
        subject_name       = $s.subject_name
        theory             = $th
        practice           = $pr
        periods            = $th + $pr
        credit             = [int]$s.credit
        teacher_id         = $reg.assigned_teacher_id
        required_room      = $prefRoom
        room_type_required = $s.room_type_required
        group_id           = $reg.group_id
        department_id      = $did
    }
}

$bundle = [PSCustomObject]@{
    admins = @(
        [PSCustomObject]@{
            admin_id   = "ADMIN01"
            admin_name = "ผู้ดูแลระบบ"
            alias      = "admin"
            password   = "admin1234"
            title      = "ฝ่ายวิชาการ สอศ."
        }
    )
    departments   = $departments
    teachers      = $teachers
    rooms         = $rooms
    studentGroups = $studentGroups
    students      = $students
    courses       = $courses
}

$json = $bundle | ConvertTo-Json -Depth 6 -Compress
$jsContent = "window.VEC_RAW_DATASET_BUNDLE = $json;"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutFile, $jsContent, $utf8NoBom)

Write-Host "Generated $OutFile (Teachers: $($teachers.Count), Groups: $($studentGroups.Count), Rooms: $($rooms.Count), Courses: $($courses.Count))"
