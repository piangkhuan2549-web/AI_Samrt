$ErrorActionPreference = "Stop"

$OutDir = "c:\ai_smarttable\data\raw"
if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

function Write-CsvUtf8 {
    param(
        [string]$Path,
        [string[]]$Lines
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($Path, $Lines, $utf8NoBom)
}

# 1. 10 Departments (D01 - D10)
$Departments = @(
    @{ Id = "D01"; Name = "เทคโนโลยีปัญญาประดิษฐ์"; Code = "30901"; LabType = "ปฏิบัติการ AI & Data Science"; Subjects = @(
        @{ SubId="30901-1001"; Name="การเขียนโปรแกรมคอมพิวเตอร์ชั้นสูง"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30901-1002"; Name="ระบบจัดการฐานข้อมูล"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30901-1003"; Name="การวิเคราะห์และออกแบบระบบงาน"; Th=2; Pr=2; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30901-1007"; Name="คณิตศาสตร์สำหรับวิทยาการคอมพิวเตอร์"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30901-1008"; Name="สถิติและการวิเคราะห์ข้อมูลเบื้องต้น"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30901-2001"; Name="การเรียนรู้ของเครื่องและการประยุกต์"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30901-2002"; Name="ปัญญาประดิษฐ์เชิงลึกและระบบผู้เชี่ยวชาญ"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30901-2003"; Name="การประมวลผลข้อมูลขนาดใหญ่"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30901-2008"; Name="การทดสอบและประกันคุณภาพซอฟต์แวร์"; Th=2; Pr=2; Cr=3; Room="Theory"; Lv=2 },
        @{ SubId="30901-2014"; Name="ความก้าวหน้าทางเทคโนโลยีปัญญาประดิษฐ์"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 }
    )},
    @{ Id = "D02"; Name = "เทคโนโลยีสารสนเทศ"; Code = "30901"; LabType = "ปฏิบัติการเครือข่ายและซอฟต์แวร์"; Subjects = @(
        @{ SubId="30901-1101"; Name="เครือข่ายคอมพิวเตอร์และการสื่อสาร"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30901-1102"; Name="โครงสร้างข้อมูลและอัลกอริทึม"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30901-1103"; Name="การพัฒนาเว็บแอปพลิเคชัน"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30901-1104"; Name="ระบบคอมพิวเตอร์และสถาปัตยกรรม"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30901-1105"; Name="เทคโนโลยีสารสนเทศเพื่อการจัดการ"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30901-2101"; Name="ความมั่นคงปลอดภัยบนระบบเครือข่าย"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30901-2102"; Name="เทคโนโลยีคลาวด์และเดฟออปส์ (DevOps)"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30901-2103"; Name="การบริหารจัดการระบบปฏิบัติการคอมพิวเตอร์"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30901-2104"; Name="วิศวกรรมซอฟต์แวร์และการบริหารโครงการ"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 },
        @{ SubId="30901-2105"; Name="กฎหมายและจริยธรรมทางเทคโนโลยีสารสนเทศ"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 }
    )},
    @{ Id = "D03"; Name = "เทคโนโลยีธุรกิจดิจิทัล"; Code = "30204"; LabType = "ปฏิบัติการคอมพิวเตอร์ธุรกิจ"; Subjects = @(
        @{ SubId="30204-1001"; Name="หลักการจัดการธุรกิจดิจิทัล"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30204-1002"; Name="โปรแกรมตารางคำนวณเพื่อการวิเคราะห์ธุรกิจ"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30204-1003"; Name="การออกแบบกราฟิกสำหรับธุรกิจดิจิทัล"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30204-1004"; Name="ระบบสารสนเทศเพื่อการจัดการองค์กร"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30204-1005"; Name="การสื่อสารธุรกิจยุคดิจิทัล"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30204-2001"; Name="พาณิชย์อิเล็กทรอนิกส์และระบบชำระเงิน"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30204-2002"; Name="การวิเคราะห์ข้อมูลธุรกิจด้วย BI"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30204-2003"; Name="การจัดการห่วงโซ่อุปทานดิจิทัล"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30204-2004"; Name="การเป็นผู้ประกอบการธุรกิจดิจิทัล"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 },
        @{ SubId="30204-2005"; Name="กฎหมายพาณิชย์อิเล็กทรอนิกส์"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 }
    )},
    @{ Id = "D04"; Name = "ช่างไฟฟ้ากำลัง"; Code = "30104"; LabType = "ปฏิบัติการไฟฟ้ากำลัง"; Subjects = @(
        @{ SubId="30104-1001"; Name="วงจรไฟฟ้ากระแสสลับขั้นสูง"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30104-1002"; Name="เครื่องวัดและเครื่องมือวัดทางไฟฟ้า"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30104-1003"; Name="การติดตั้งไฟฟ้าในอาคารและโรงงาน"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30104-1004"; Name="มอเตอร์ไฟฟ้าและการควบคุม"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30104-1005"; Name="คณิตศาสตร์ไฟฟ้ากำลัง"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30104-2001"; Name="ระบบส่งและจ่ายกำลังไฟฟ้า"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 },
        @{ SubId="30104-2002"; Name="การโปรแกรม PLC และระบบอัตโนมัติ"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30104-2003"; Name="ระบบไฟฟ้าพลังงานทดแทน"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30104-2004"; Name="การป้องกันระบบไฟฟ้ากำลัง"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30104-2005"; Name="การอนุรักษ์พลังงานในโรงงานอุตสาหกรรม"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 }
    )},
    @{ Id = "D05"; Name = "ช่างอิเล็กทรอนิกส์"; Code = "30105"; LabType = "ปฏิบัติการอิเล็กทรอนิกส์"; Subjects = @(
        @{ SubId="30105-1001"; Name="อุปกรณ์และวงจรอิเล็กทรอนิกส์กำลัง"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30105-1002"; Name="วงจรดิจิทัลและลอจิกขั้นสูง"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30105-1003"; Name="ไมโครคอนโทรลเลอร์และการประยุกต์"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30105-1004"; Name="ทฤษฎีสัญญาณและระบบ"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30105-1005"; Name="การออกแบบแผ่นวงจรพิมพ์ (PCB)"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30105-2001"; Name="ระบบสมองกลฝังตัวและ IoT"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30105-2002"; Name="อิเล็กทรอนิกส์อุตสาหกรรมและการซ่อมบำรุง"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30105-2003"; Name="ระบบสื่อสารไร้สายและโทรคมนาคม"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30105-2004"; Name="การวิเคราะห์วงจรอิเล็กทรอนิกส์"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 },
        @{ SubId="30105-2005"; Name="มาตรฐานความปลอดภัยทางอิเล็กทรอนิกส์"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 }
    )},
    @{ Id = "D06"; Name = "เมคคาทรอนิกส์และหุ่นยนต์"; Code = "30127"; LabType = "ปฏิบัติการหุ่นยนต์และอัตโนมัติ"; Subjects = @(
        @{ SubId="30127-1001"; Name="กลศาสตร์วิศวกรรมสำหรับเมคคาทรอนิกส์"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30127-1002"; Name="นิวเมติกส์และไฮดรอลิกส์อุตสาหกรรม"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30127-1003"; Name="เซ็นเซอร์และตัวกระตุ้นในงานอุตสาหกรรม"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30127-1004"; Name="การเขียนแบบวิศวกรรมด้วยคอมพิวเตอร์ (CAD)"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30127-1005"; Name="ทฤษฎีระบบควบคุมเบื้องต้น"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30127-2001"; Name="การโปรแกรมแขนกลหุ่นยนต์อุตสาหกรรม"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30127-2002"; Name="ระบบวิชั่นและ AI สำหรับหุ่นยนต์"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30127-2003"; Name="การบูรณาการระบบ SCADA และ HMI"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30127-2004"; Name="การออกแบบระบบเมคคาทรอนิกส์"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 },
        @{ SubId="30127-2005"; Name="การบำรุงรักษาเชิงพยากรณ์"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 }
    )},
    @{ Id = "D07"; Name = "ยานยนต์ไฟฟ้า"; Code = "30101"; LabType = "ปฏิบัติการยานยนต์ไฟฟ้า"; Subjects = @(
        @{ SubId="30101-1001"; Name="เทคโนโลยียานยนต์สมัยใหม่"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30101-1002"; Name="ระบบส่งกำลังและแชสซียานยนต์"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30101-1003"; Name="ไฟฟ้าและอิเล็กทรอนิกส์ยานยนต์"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30101-1004"; Name="เครื่องมือวิเคราะห์ปัญหายานยนต์"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30101-1005"; Name="ความปลอดภัยแรงดันสูงในยานยนต์ไฟฟ้า"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30101-2001"; Name="ระบบแบตเตอรี่และการจัดการพลังงาน (BMS)"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30101-2002"; Name="มอเตอร์ขับเคลื่อนและอินเวอร์เตอร์ EV"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30101-2003"; Name="สถานีอัดประจุไฟฟ้าและการบำรุงรักษา"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30101-2004"; Name="ระบบขับขี่อัตโนมัติและ ADAS"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 },
        @{ SubId="30101-2005"; Name="การจัดการศูนย์บริการยานยนต์สมัยใหม่"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 }
    )},
    @{ Id = "D08"; Name = "ช่างกลโรงงาน"; Code = "30102"; LabType = "ปฏิบัติการเครื่องมือกล CNC"; Subjects = @(
        @{ SubId="30102-1001"; Name="วัสดุศาสตร์และกรรมวิธีทางความร้อน"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30102-1002"; Name="งานเครื่องมือกลขั้นสูง"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30102-1003"; Name="การเขียนแบบเทคนิคและ GD&T"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30102-1004"; Name="มาตรวิทยาและการตรวจสอบชิ้นส่วน"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30102-1005"; Name="การวางแผนการผลิตอุตสาหกรรม"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30102-2001"; Name="การโปรแกรมเครื่องจักรกลอัตโนมัติ (CNC)"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30102-2002"; Name="การออกแบบและการผลิตด้วยคอมพิวเตอร์ (CAD/CAM)"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30102-2003"; Name="การออกแบบแม่พิมพ์และจิ๊กฟิกซ์เจอร์"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30102-2004"; Name="การควบคุมคุณภาพเชิงสถิติ (SQC)"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 },
        @{ SubId="30102-2005"; Name="การจัดการความปลอดภัยในโรงงาน"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 }
    )},
    @{ Id = "D09"; Name = "การบัญชี"; Code = "30201"; LabType = "ปฏิบัติการบัญชีคอมพิวเตอร์"; Subjects = @(
        @{ SubId="30201-1001"; Name="การบัญชีขั้นกลาง 1"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30201-1002"; Name="โปรแกรมสำเร็จรูปเพื่องานบัญชี"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30201-1003"; Name="การบัญชีต้นทุนเบื้องต้น"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30201-1004"; Name="การวิเคราะห์งบการเงินด้วยสเปรดชีต"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30201-1005"; Name="หลักกฎหมายภาษีอากร"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30201-2001"; Name="การบัญชีบริหารและการตัดสินใจ"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 },
        @{ SubId="30201-2002"; Name="ระบบสารสนเทศทางการบัญชี (AIS)"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30201-2003"; Name="การสอบบัญชีและการควบคุมภายใน"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30201-2004"; Name="การจัดทำภาษีอิเล็กทรอนิกส์ (e-Tax)"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30201-2005"; Name="จรรยาบรรณวิชาชีพบัญชี"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 }
    )},
    @{ Id = "D10"; Name = "การตลาดดิจิทัล"; Code = "30202"; LabType = "ปฏิบัติการสื่อและการตลาดดิจิทัล"; Subjects = @(
        @{ SubId="30202-1001"; Name="หลักการตลาดสมัยใหม่และพฤติกรรมผู้บริโภค"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30202-1002"; Name="การผลิตสื่อดิจิทัลเพื่อการตลาด"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30202-1003"; Name="การตลาดผ่านสื่อสังคมออนไลน์"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30202-1004"; Name="การออกแบบเว็บไซต์เพื่อการขาย"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=1 },
        @{ SubId="30202-1005"; Name="การสื่อสารการตลาดแบบบูรณาการ"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=1 },
        @{ SubId="30202-2001"; Name="การวิเคราะห์ข้อมูลการตลาดดิจิทัล"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30202-2002"; Name="กลยุทธ์ SEO/SEM และการโฆษณาออนไลน์"; Th=2; Pr=3; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30202-2003"; Name="การจัดการความสัมพันธ์ลูกค้า (CRM)"; Th=2; Pr=2; Cr=3; Room="Lab"; Lv=2 },
        @{ SubId="30202-2004"; Name="การวางแผนแคมเปญการตลาดดิจิทัล"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 },
        @{ SubId="30202-2005"; Name="การวิจัยตลาดในยุคดิจิทัล"; Th=4; Pr=0; Cr=3; Room="Theory"; Lv=2 }
    )}
)

$FirstNames = @("สมชาย","วิภาดา","ณรงค์ศักดิ์","กนกวรรณ","ธีรยุทธ","สุนิสา","ประเสริฐ","ปิยะธิดา","อนุชา","ศิริพร",
                "เกียรติศักดิ์","รัตนาภรณ์","ธนพล","วรรณิภา","สุรชัย","นภาลัย","พงศธร","อรุณี","เอกชัย","พรทิพย์")
$LastNames = @("ใจดี","ศิริพร","ประเสริฐ","เพชรรัตน์","ชัยชนะ","วงศ์สุวรรณ","จันทร์เพ็ญ","ศรีสมบัติ","แก้วมณี","ทองคำ",
               "บุญมี","รุ่งเรือง","สวัสดี","พูลทรัพย์","อินทร์ทอง","เจริญสุข","มั่งมี","แสงสว่าง","สุขสันต์","ธรรมรักษ์")
$Titles = @("อ.","ดร.","ผศ.","อ.","อ.","อ.","อ.")

# 2. Generate timeslot.csv (Mon-Fri, 8 periods/day = 40 periods)
$Days = @("Mon","Tue","Wed","Thu","Fri")
$PeriodTimes = @(
    @{ P=1; S="08:00"; E="09:00" },
    @{ P=2; S="09:00"; E="10:00" },
    @{ P=3; S="10:00"; E="11:00" },
    @{ P=4; S="11:00"; E="12:00" },
    @{ P=5; S="13:00"; E="14:00" },
    @{ P=6; S="14:00"; E="15:00" },
    @{ P=7; S="15:00"; E="16:00" },
    @{ P=8; S="16:00"; E="17:00" }
)
$TimeslotLines = @("timeslot_id,day,period,start,end")
$tsId = 1
foreach ($d in $Days) {
    foreach ($pt in $PeriodTimes) {
        $TimeslotLines += "$tsId,$d,$($pt.P),$($pt.S),$($pt.E)"
        $tsId++
    }
}
Write-CsvUtf8 -Path (Join-Path $OutDir "timeslot.csv") -Lines $TimeslotLines

# 3. Generate teacher.csv (70 teachers = 7 per dept) and teacher_unavailability.csv (4 slots/teacher)
$TeacherLines = @("teacher_id,teacher_name,department_id,department_name,target_min_load")
$TeacherUnavailLines = @("teacher_id,timeslot_id,reason")
$UnavailBlocks = @(
    @(1,2,3,4),     # Mon morning
    @(5,6,7,8),     # Mon afternoon
    @(9,10,11,12),  # Tue morning
    @(13,14,15,16), # Tue afternoon
    @(17,18,19,20), # Wed morning
    @(21,22,23,24), # Wed afternoon
    @(25,26,27,28), # Thu morning
    @(29,30,31,32), # Thu afternoon
    @(33,34,35,36), # Fri morning
    @(37,38,39,40)  # Fri afternoon
)
$ReasonsT = @("ประชุมวิชาการแผนก","เตรียมการสอน/วิจัย","งานแนะแนวและที่ปรึกษา","พัฒนาหลักสูตร สอศ.")

$TeachersByDept = @{}
$tNum = 1
for ($dIdx = 0; $dIdx -lt $Departments.Count; $dIdx++) {
    $dept = $Departments[$dIdx]
    $TeachersByDept[$dept.Id] = @()
    for ($k = 0; $k -lt 7; $k++) {
        $tid = "T{0:D2}" -f $tNum
        $title = $Titles[$k]
        $fn = $FirstNames[($tNum - 1) % $FirstNames.Count]
        $ln = $LastNames[(($tNum - 1) * 3) % $LastNames.Count]
        $tName = "$title$fn $ln"
        $TeacherLines += "$tid,$tName,$($dept.Id),$($dept.Name),30"
        $TeachersByDept[$dept.Id] += $tid

        $blk = $UnavailBlocks[($tNum - 1) % $UnavailBlocks.Count]
        $rsn = $ReasonsT[($tNum - 1) % $ReasonsT.Count]
        foreach ($slot in $blk) {
            $TeacherUnavailLines += "$tid,$slot,$rsn"
        }
        $tNum++
    }
}
Write-CsvUtf8 -Path (Join-Path $OutDir "teacher.csv") -Lines $TeacherLines
Write-CsvUtf8 -Path (Join-Path $OutDir "teacher_unavailability.csv") -Lines $TeacherUnavailLines

# 4. Generate room.csv (80 rooms: 50 Lab + 30 Theory) and room_unavailability.csv
$RoomLines = @("room_id,room_name,room_type,capacity,department_id")
$RoomUnavailLines = @("room_id,timeslot_id,reason")
$RoomReasons = @("ซ่อมบำรุงอุปกรณ์ประจำสัปดาห์","ประชุมแผนกวิชา","กิจกรรมโฮมรูม/พัฒนาผู้เรียน","ทำความสะอาดใหญ่")

$rLabNum = 101
$rThyNum = 201
for ($dIdx = 0; $dIdx -lt $Departments.Count; $dIdx++) {
    $dept = $Departments[$dIdx]
    # 5 Lab rooms per dept
    for ($l = 1; $l -le 5; $l++) {
        $rid = "R$rLabNum"
        $rName = "ห้อง$($dept.LabType) $l"
        $RoomLines += "$rid,$rName,Lab,40,$($dept.Id)"
        $slotA = (($rLabNum * 2) % 39) + 1
        $slotB = $slotA + 1
        $rsn = $RoomReasons[$rLabNum % $RoomReasons.Count]
        $RoomUnavailLines += "$rid,$slotA,$rsn"
        $RoomUnavailLines += "$rid,$slotB,$rsn"
        $rLabNum++
    }
    # 3 Theory rooms per dept (30 total)
    for ($th = 1; $th -le 3; $th++) {
        $rid = "R$rThyNum"
        $rName = "ห้องเรียนทฤษฎี $($dept.Name) $th"
        $RoomLines += "$rid,$rName,Theory,50,$($dept.Id)"
        $slotA = (($rThyNum * 2) % 39) + 1
        $slotB = $slotA + 1
        $rsn = $RoomReasons[$rThyNum % $RoomReasons.Count]
        $RoomUnavailLines += "$rid,$slotA,$rsn"
        $RoomUnavailLines += "$rid,$slotB,$rsn"
        $rThyNum++
    }
}
Write-CsvUtf8 -Path (Join-Path $OutDir "room.csv") -Lines $RoomLines
Write-CsvUtf8 -Path (Join-Path $OutDir "room_unavailability.csv") -Lines $RoomUnavailLines

# 5. Generate student_groups.csv (100 groups = 10 per dept)
$GroupLines = @("group_id,group_name,student_count,advisor,department_id,level")
$rng = New-Object System.Random(2568)
$GroupsByDept = @{}
$gNum = 1
for ($dIdx = 0; $dIdx -lt $Departments.Count; $dIdx++) {
    $dept = $Departments[$dIdx]
    $deptTeachers = $TeachersByDept[$dept.Id]
    $GroupsByDept[$dept.Id] = @()
    for ($lv = 1; $lv -le 2; $lv++) {
        for ($sec = 1; $sec -le 5; $sec++) {
            $gid = "G{0:D3}" -f $gNum
            $gName = "ปวส.$lv/$sec $($dept.Name)"
            $cnt = $rng.Next(26, 41) # 26..40 <= room capacity 40
            $adv = $deptTeachers[($gNum - 1) % $deptTeachers.Count]
            $GroupLines += "$gid,$gName,$cnt,$adv,$($dept.Id),ปวส.$lv"
            $GroupsByDept[$dept.Id] += @{ Id = $gid; Level = $lv }
            $gNum++
        }
    }
}
Write-CsvUtf8 -Path (Join-Path $OutDir "student_groups.csv") -Lines $GroupLines

# 6. Generate subject.csv (100 subjects), teach.csv, register.csv
# Ensure every teacher has >= 30 periods/week (31..33 periods/week)
$SubjectLines = @("subject_id,subject_name,theory,practice,credit,room_type_required,department_id")
$TeachSet = New-Object System.Collections.Generic.HashSet[string]
$TeachLines = @("teacher_id,subject_id")
$RegisterLines = @("group_id,subject_id,assigned_teacher_id")

# Precomputed balanced teacher indices for 50 group-subject pairs per department
# Wait: 25 pairs of Lv1 (15x4 + 10x5 = 110 periods) + 25 pairs of Lv2 (15x4 + 10x5 = 110 periods) = 220 periods/dept.
# Distribute 50 pairs across 7 teachers so each gets 31,31,31,31,31,32,33 periods!
foreach ($dept in $Departments) {
    foreach ($sub in $dept.Subjects) {
        $SubjectLines += "$($sub.SubId),$($sub.Name),$($sub.Th),$($sub.Pr),$($sub.Cr),$($sub.Room),$($dept.Id)"
    }

    $deptTeachers = $TeachersByDept[$dept.Id]
    $lv1Subs = @($dept.Subjects | Where-Object { $_.Lv -eq 1 })
    $lv2Subs = @($dept.Subjects | Where-Object { $_.Lv -eq 2 })

    # Collect all 50 group-subject pairs and assign greedily to the teacher with minimum load
    $allPairs = @()
    foreach ($grp in $GroupsByDept[$dept.Id]) {
        $subs = if ($grp.Level -eq 1) { $lv1Subs } else { $lv2Subs }
        foreach ($s in $subs) {
            $pTotal = $s.Th + $s.Pr
            $allPairs += [PSCustomObject]@{ GroupId = $grp.Id; SubId = $s.SubId; Periods = $pTotal }
        }
    }
    $sortedPairs = $allPairs | Sort-Object -Property Periods -Descending
    $tLoadTracker = @(0, 0, 0, 0, 0, 0, 0)

    foreach ($p in $sortedPairs) {
        $minIdx = 0
        for ($t = 1; $t -lt 7; $t++) {
            if ($tLoadTracker[$t] -lt $tLoadTracker[$minIdx]) { $minIdx = $t }
        }
        $tid = $deptTeachers[$minIdx]
        $tLoadTracker[$minIdx] += $p.Periods
        $RegisterLines += "$($p.GroupId),$($p.SubId),$tid"
        $key = "$tid|$($p.SubId)"
        if ($TeachSet.Add($key)) { $TeachLines += "$tid,$($p.SubId)" }
    }
}

Write-CsvUtf8 -Path (Join-Path $OutDir "subject.csv") -Lines $SubjectLines
Write-CsvUtf8 -Path (Join-Path $OutDir "teach.csv") -Lines $TeachLines
Write-CsvUtf8 -Path (Join-Path $OutDir "register.csv") -Lines $RegisterLines

Write-Host "Successfully generated all 9 CSV files in $OutDir"
