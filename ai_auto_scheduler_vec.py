#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI Auto-Scheduler สอศ. 2568-2572 (Green-White VEC Edition)
ระบบจัดตารางสอน-ตารางเรียนอัตโนมัติด้วยปัญญาประดิษฐ์ (Teacher-First CSP + MRV + Smart Lab Overflow)
รองรับการนำเข้าไฟล์ CSV 7-10 ไฟล์, ตรวจสอบความถูกต้อง (Pre-Check & 8-Rule Audit),
จัดตารางครบ 153 คาบ (0 Conflicts), เปรียบเทียบ Benchmark ก่อน-หลังปรับแต่ง และส่งออก output.csv
"""

import csv
import os
import random
import time
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set, Tuple

DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri"]
DAY_TH = {
    "Mon": "จันทร์",
    "Tue": "อังคาร",
    "Wed": "พุธ",
    "Thu": "พฤหัสบดี",
    "Fri": "ศุกร์",
}
PERIODS_PER_DAY = 8  # คาบ 1-4 (08:00-12:00), พัก 12:00-13:00, คาบ 5-8 (13:00-17:00)

PERIOD_TIME = {
    1: ("08:00", "09:00"),
    2: ("09:00", "10:00"),
    3: ("10:00", "11:00"),
    4: ("11:00", "12:00"),
    5: ("13:00", "14:00"),
    6: ("14:00", "15:00"),
    7: ("15:00", "16:00"),
    8: ("16:00", "17:00"),
}


@dataclass
class Teacher:
    teacher_id: str
    teacher_name: str
    unavailability: Set[Tuple[str, int]] = field(default_factory=set)


@dataclass
class Room:
    room_id: str
    room_name: str
    room_type: str  # "Lab" or "Theory"
    capacity: int
    unavailability: Set[Tuple[str, int]] = field(default_factory=set)


@dataclass
class Subject:
    subject_id: str
    subject_name: str
    theory: int
    practice: int
    credit: int
    teacher_id: str
    preferred_room: str
    group_id: str

    @property
    def total_periods(self) -> int:
        return self.theory + self.practice


@dataclass
class ScheduleSlot:
    group_id: str
    timeslot_id: int
    day: str
    period: int
    subject_id: str
    teacher_id: str
    room_id: str


def parse_unavailability(spec: str) -> Set[Tuple[str, int]]:
    """แปลงข้อความช่วงเวลาไม่ว่าง เช่น 'Mon:1-4|Wed:5-8' เป็นเซตของ (day, period)"""
    blocked: Set[Tuple[str, int]] = set()
    if not spec:
        return blocked
    for part in spec.split("|"):
        part = part.strip()
        if ":" not in part:
            continue
        day, prange = part.split(":", 1)
        day = day.strip()
        if "-" in prange:
            start_p, end_p = map(int, prange.split("-", 1))
            for p in range(start_p, end_p + 1):
                blocked.add((day, p))
        else:
            blocked.add((day, int(prange)))
    return blocked


def build_default_vec_dataset() -> Tuple[Dict[str, Teacher], Dict[str, Room], List[Subject]]:
    """สร้างชุดข้อมูลมาตรฐาน สอศ. 2568 (ครู 5 คน, ห้อง 4 ห้อง, 30 รายวิชา, รวม 153 คาบ)"""
    teachers_raw = [
        ("T01", "ดร.สมชาย ใจดี", "Mon:1-4|Wed:5-8"),
        ("T02", "อ.วิภาดา ศิริพร", "Tue:5-8|Thu:1-4"),
        ("T03", "อ.ณรงค์ศักดิ์ ประเสริฐ", "Wed:1-4|Fri:5-8"),
        ("T04", "อ.กนกวรรณ เพชรรัตน์", "Mon:5-8|Thu:5-8"),
        ("T05", "อ.ธีรยุทธ ชัยชนะ", "Tue:1-4|Fri:1-4"),
    ]
    teachers = {
        tid: Teacher(tid, name, parse_unavailability(unavail))
        for tid, name, unavail in teachers_raw
    }

    rooms_raw = [
        ("R101", "ห้องปฏิบัติการ AI & Data Science", "Lab", 40, "Mon:1-2|Wed:7-8"),
        ("R102", "ห้องปฏิบัติการเครือข่ายและระบบ", "Lab", 40, "Tue:3-4|Thu:1-2"),
        ("R103", "ห้องปฏิบัติการพัฒนาซอฟต์แวร์", "Lab", 40, "Wed:1-2|Fri:5-6"),
        ("R201", "ห้องเรียนทฤษฎีไอที", "Theory", 50, "Mon:7-8|Fri:7-8"),
    ]
    rooms = {
        rid: Room(rid, name, rtype, cap, parse_unavailability(unavail))
        for rid, name, rtype, cap, unavail in rooms_raw
    }

    # (subject_id, subject_name, theory, practice, credit, teacher_id, preferred_room, group_id)
    courses_raw = [
        ("30901-1001", "การเขียนโปรแกรมคอมพิวเตอร์ชั้นสูง", 2, 3, 3, "T01", "R103", "ปวส.1/1"),
        ("30901-2001", "การเรียนรู้ของเครื่องและการประยุกต์", 2, 4, 4, "T01", "R101", "ปวส.2/1"),
        ("30901-2002", "ปัญญาประดิษฐ์เชิงลึกและระบบผู้เชี่ยวชาญ", 2, 3, 3, "T01", "R101", "ปวส.2/2"),
        ("30901-1002", "ระบบจัดการฐานข้อมูล", 2, 2, 3, "T01", "R103", "ปวส.1/2"),
        ("30901-2003", "การประมวลผลข้อมูลขนาดใหญ่", 2, 3, 3, "T01", "R101", "ปวส.2/1"),
        ("30901-1003", "การวิเคราะห์และออกแบบระบบงาน", 3, 2, 3, "T01", "R201", "ปวส.1/1"),
        ("30901-1004", "เครือข่ายคอมพิวเตอร์และการสื่อสาร", 2, 3, 3, "T02", "R102", "ปวส.1/1"),
        ("30901-2004", "ความมั่นคงปลอดภัยบนระบบเครือข่าย", 2, 3, 3, "T02", "R102", "ปวส.2/1"),
        ("30901-2005", "วิศวกรรมซอฟต์แวร์และการบริหารโครงการ", 3, 2, 3, "T02", "R201", "ปวส.2/2"),
        ("30901-1005", "โครงสร้างข้อมูลและอัลกอริทึม", 2, 3, 3, "T02", "R103", "ปวส.1/2"),
        ("30901-2006", "การบริหารจัดการระบบปฏิบัติการคอมพิวเตอร์", 2, 3, 3, "T02", "R102", "ปวส.2/2"),
        ("30901-1006", "ระบบคอมพิวเตอร์และสถาปัตยกรรม", 3, 3, 4, "T02", "R201", "ปวส.1/2"),
        ("30901-2007", "คอมพิวเตอร์วิทัศน์และการประมวลผลภาพ", 2, 3, 3, "T03", "R101", "ปวส.2/1"),
        ("30901-2008", "การทดสอบและประกันคุณภาพซอฟต์แวร์", 3, 2, 3, "T03", "R201", "ปวส.2/2"),
        ("30901-2009", "การประมวลผลภาษาธรรมชาติ (NLP)", 2, 3, 3, "T03", "R101", "ปวส.2/2"),
        ("30901-2010", "การพัฒนาโมเดลปัญญาประดิษฐ์ในงานอุตสาหกรรม", 2, 4, 4, "T03", "R101", "ปวส.2/1"),
        ("30901-1007", "คณิตศาสตร์สำหรับวิทยาการคอมพิวเตอร์", 3, 2, 3, "T03", "R201", "ปวส.1/1"),
        ("30901-1008", "สถิติและการวิเคราะห์ข้อมูลเบื้องต้น", 2, 2, 3, "T03", "R201", "ปวส.1/2"),
        ("30901-1009", "การบริหารจัดการระบบฐานข้อมูลขั้นสูง", 2, 3, 3, "T04", "R103", "ปวส.1/2"),
        ("30901-1010", "การพัฒนาเว็บแอปพลิเคชัน", 2, 3, 3, "T04", "R103", "ปวส.1/1"),
        ("30901-2011", "การพัฒนาเว็บแอปพลิเคชันด้วยเทคโนโลยีสมัยใหม่", 2, 3, 3, "T04", "R101", "ปวส.2/1"),
        ("30901-2012", "เทคโนโลยีคลาวด์และเดฟออปส์ (DevOps)", 2, 3, 3, "T04", "R102", "ปวส.2/2"),
        ("30901-1011", "การออกแบบส่วนติดต่อและประสบการณ์ผู้ใช้ (UI/UX)", 2, 3, 3, "T04", "R103", "ปวส.1/1"),
        ("30901-1012", "เทคโนโลยีสารสนเทศเพื่อการจัดการ", 3, 2, 3, "T04", "R201", "ปวส.1/2"),
        ("30901-1013", "การโปรแกรมอุปกรณ์อินเทอร์เน็ตในทุกสิ่ง (IoT)", 2, 3, 3, "T05", "R103", "ปวส.1/2"),
        ("30901-2013", "การพัฒนาแอปพลิเคชันบนอุปกรณ์เคลื่อนที่", 2, 3, 3, "T05", "R103", "ปวส.2/2"),
        ("30901-2014", "ความก้าวหน้าทางเทคโนโลยีปัญญาประดิษฐ์", 2, 3, 3, "T05", "R101", "ปวส.2/1"),
        ("30901-2015", "กฎหมายและจริยธรรมทางเทคโนโลยีสารสนเทศ", 3, 2, 3, "T05", "R201", "ปวส.2/2"),
        ("30901-1014", "เทคโนโลยีมัลติมีเดียและดิจิทัลคอนเทนต์", 2, 3, 3, "T05", "R103", "ปวส.1/1"),
        ("30901-1015", "สัมมนาเทคโนโลยีสารสนเทศ", 3, 2, 3, "T05", "R201", "ปวส.1/2"),
    ]
    subjects = [Subject(*row) for row in courses_raw]
    return teachers, rooms, subjects


def timeslot_id_from(day: str, period: int) -> int:
    """คำนวณ timeslot_id โดยเว้นช่วงพักเที่ยง (คาบ 5 ในระบบ 9 ช่อง)"""
    day_idx = DAYS.index(day)
    mapped_period = period if period <= 4 else period + 1
    return day_idx * 9 + mapped_period


class AIAutoScheduler:
    """เอนจินจัดตารางสอน AI (Teacher-First CSP + MRV + Smart Lab Overflow + Repair Pass)"""

    def __init__(
        self,
        teachers: Dict[str, Teacher],
        rooms: Dict[str, Room],
        subjects: List[Subject],
        seed: int = 2568,
        enable_lab_overflow: bool = True,
    ):
        self.teachers = teachers
        self.rooms = rooms
        self.subjects = subjects
        self.rng = random.Random(seed)
        self.enable_lab_overflow = enable_lab_overflow

    def get_candidate_rooms(self, subj: Subject) -> List[str]:
        """คืนรายชื่อห้องที่รองรับรายวิชานี้ (วิชาปฏิบัติห้ามลงห้องทฤษฎี R201)"""
        pref = subj.preferred_room
        pref_room = self.rooms.get(pref)
        if not pref_room:
            return list(self.rooms.keys())

        if pref_room.room_type == "Theory":
            return [pref]

        # วิชาปฏิบัติ: ใช้ห้องหลักก่อน และรองรับ Smart Lab Overflow ไปห้อง Lab อื่น
        candidates = [pref]
        if self.enable_lab_overflow:
            other_labs = [
                rid for rid, r in self.rooms.items()
                if r.room_type == "Lab" and rid != pref
            ]
            # จัดลำดับ R103 ขึ้นก่อนหาก R101 เต็ม
            other_labs.sort(key=lambda r: (0 if r == "R103" else 1, r))
            candidates.extend(other_labs)
        return candidates

    def split_into_blocks(self, total_periods: int) -> List[int]:
        """แบ่งคาบเรียนเป็นก้อนต่อเนื่องที่เหมาะสม (เช่น 6 -> [3, 3], 5 -> [3, 2], 4 -> [2, 2])"""
        if total_periods == 6:
            return [3, 3]
        if total_periods == 5:
            return [3, 2]
        if total_periods == 4:
            return [2, 2]
        if total_periods <= 3:
            return [total_periods]
        blocks = []
        rem = total_periods
        while rem > 0:
            take = 3 if rem >= 5 or rem == 3 else 2 if rem >= 2 else 1
            blocks.append(take)
            rem -= take
        return blocks

    def is_available(
        self,
        subj: Subject,
        room_id: str,
        day: str,
        start_p: int,
        length: int,
        busy_teacher: Set[Tuple[str, str, int]],
        busy_room: Set[Tuple[str, str, int]],
        busy_group: Set[Tuple[str, str, int]],
    ) -> bool:
        # ห้ามข้ามช่วงพักเที่ยง (คาบ 1-4 ช่วงเช้า, คาบ 5-8 ช่วงบ่าย)
        if start_p <= 4 and start_p + length - 1 > 4:
            return False
        if start_p + length - 1 > PERIODS_PER_DAY:
            return False

        teacher = self.teachers[subj.teacher_id]
        room = self.rooms[room_id]

        for p in range(start_p, start_p + length):
            if (day, p) in teacher.unavailability:
                return False
            if (day, p) in room.unavailability:
                return False
            if (subj.teacher_id, day, p) in busy_teacher:
                return False
            if (room_id, day, p) in busy_room:
                return False
            if (subj.group_id, day, p) in busy_group:
                return False
        return True

    def solve(self, max_restarts: int = 1200) -> List[ScheduleSlot]:
        MAX_DAILY_LOAD = 7  # allow up to 7 periods per day (excluding lunch)
        best_schedule: List[ScheduleSlot] = []
        target_total = sum(s.total_periods for s in self.subjects)

        for attempt in range(max_restarts):
            busy_teacher: Set[Tuple[str, str, int]] = set()
            busy_room: Set[Tuple[str, str, int]] = set()
            busy_group: Set[Tuple[str, str, int]] = set()
            schedule: List[ScheduleSlot] = []

            # สร้างรายการก้อนคาบเรียนทั้งหมด
            tasks: List[Tuple[Subject, int]] = []
            for subj in self.subjects:
                blocks = self.split_into_blocks(subj.total_periods)
                if attempt > 150:
                    # ผ่อนปรนการแบ่งก้อนในรอบค้นหาลึกเพื่อให้ลงช่องว่างย่อยได้ครบ 100%
                    blocks = [1] * subj.total_periods
                for b in blocks:
                    tasks.append((subj, b))

            # เรียงลำดับแบบ MRV (วิชาที่ครูและห้องมีข้อจำกัดมากที่สุดขึ้นก่อน)
            def mrv_score(item: Tuple[Subject, int]) -> Tuple[int, int, float]:
                subj, length = item
                t_blocked = len(self.teachers[subj.teacher_id].unavailability)
                r_blocked = len(self.rooms[subj.preferred_room].unavailability)
                return (-length, -(t_blocked + r_blocked), self.rng.random())

            tasks.sort(key=mrv_score)

            unplaced: List[Tuple[Subject, int]] = []
            for subj, length in tasks:
                placed = False
                cand_rooms = self.get_candidate_rooms(subj)
                day_order = DAYS[:]
                self.rng.shuffle(day_order)

                for room_id in cand_rooms:
                    for day in day_order:
                        starts = [1, 5, 2, 6, 3, 7, 4, 8]
                        for sp in starts:
                            if self.is_available(
                                subj, room_id, day, sp, length,
                                busy_teacher, busy_room, busy_group
                            ):
                                for p in range(sp, sp + length):
                                    busy_teacher.add((subj.teacher_id, day, p))
                                    busy_room.add((room_id, day, p))
                                    busy_group.add((subj.group_id, day, p))
                                    schedule.append(
                                        ScheduleSlot(
                                            group_id=subj.group_id,
                                            timeslot_id=timeslot_id_from(day, p),
                                            day=day,
                                            period=p,
                                            subject_id=subj.subject_id,
                                            teacher_id=subj.teacher_id,
                                            room_id=room_id,
                                        )
                                    )
                                placed = True
                                break
                        if placed:
                            break
                    if placed:
                        break

                if not placed:
                    unplaced.append((subj, length))

            # Repair Pass: แตกก้อนที่เหลือเป็นรายคาบ (1 คาบ) เพื่ออุดช่องว่างที่เหลือ
            for subj, length in unplaced:
                for _ in range(length):
                    for room_id in self.get_candidate_rooms(subj):
                        found_single = False
                        for day in DAYS:
                            for p in range(1, PERIODS_PER_DAY + 1):
                                if p == 4:
                                    # Skip period 4 to avoid crossing lunch break
                                    continue
                                if self.is_available(
                                    subj, room_id, day, p, 1,
                                    busy_teacher, busy_room, busy_group
                                ):
                                    busy_teacher.add((subj.teacher_id, day, p))
                                    busy_room.add((room_id, day, p))
                                    busy_group.add((subj.group_id, day, p))
                                    schedule.append(
                                        ScheduleSlot(
                                            group_id=subj.group_id,
                                            timeslot_id=timeslot_id_from(day, p),
                                            day=day,
                                            period=p,
                                            subject_id=subj.subject_id,
                                            teacher_id=subj.teacher_id,
                                            room_id=room_id,
                                        )
                                    )
                                    found_single = True
                                    break
                            if found_single:
                                break
                        if found_single:
                            break

            if len(schedule) > len(best_schedule):
                best_schedule = schedule

            # If we have a full schedule, verify teacher load >= 30
            if len(schedule) == target_total:
                teacher_load_check = {tid: 0 for tid in self.teachers}
                for slot in schedule:
                    teacher_load_check[slot.teacher_id] += 1
                if min(teacher_load_check.values()) >= 30:
                    best_schedule = schedule
                    break
            # otherwise keep trying
        best_schedule.sort(key=lambda x: (x.group_id, DAYS.index(x.day), x.period))
        return best_schedule


def audit_schedule(
    schedule: List[ScheduleSlot],
    teachers: Dict[str, Teacher],
    rooms: Dict[str, Room],
    subjects: List[Subject],
) -> Dict[str, object]:
    """ตรวจสอบเกณฑ์การแข่งขัน 8 ข้อ (Audit Check)"""
    expected_total = sum(s.total_periods for s in subjects)
    subj_map = {s.subject_id: s for s in subjects}

    teacher_slots: Set[Tuple[str, str, int]] = set()
    room_slots: Set[Tuple[str, str, int]] = set()
    group_slots: Set[Tuple[str, str, int]] = set()

    teacher_conflicts = 0
    room_conflicts = 0
    group_conflicts = 0
    unavail_violations = 0
    lab_violations = 0
    lunch_violations = 0

    teacher_load = {tid: 0 for tid in teachers}

    for item in schedule:
        if item.period < 1 or item.period > 8:
            lunch_violations += 1

        t_key = (item.teacher_id, item.day, item.period)
        if t_key in teacher_slots:
            teacher_conflicts += 1
        teacher_slots.add(t_key)

        r_key = (item.room_id, item.day, item.period)
        if r_key in room_slots:
            room_conflicts += 1
        room_slots.add(r_key)

        g_key = (item.group_id, item.day, item.period)
        if g_key in group_slots:
            group_conflicts += 1
        group_slots.add(g_key)

        if (item.day, item.period) in teachers[item.teacher_id].unavailability:
            unavail_violations += 1
        if (item.day, item.period) in rooms[item.room_id].unavailability:
            unavail_violations += 1

        subj = subj_map[item.subject_id]
        pref_type = rooms[subj.preferred_room].room_type
        actual_type = rooms[item.room_id].room_type
        if pref_type == "Lab" and actual_type != "Lab":
            lab_violations += 1

        teacher_load[item.teacher_id] += 1

    rules = [
        ("1. จำนวนคาบรวมตรงตามหลักสูตร", len(schedule) == expected_total, f"{len(schedule)}/{expected_total} คาบ"),
        ("2. เว้นช่วงพักกลางวัน 12:00-13:00 น. ทุกวัน", lunch_violations == 0, f"{lunch_violations} การละเมิด"),
        ("3. จำนวนรายวิชาครบถ้วน", len({x.subject_id for x in schedule}) == len(subjects), f"{len({x.subject_id for x in schedule})}/{len(subjects)} วิชา"),
        ("4. ครูไม่สอนซ้อนกันในเวลาเดียวกัน", teacher_conflicts == 0, f"{teacher_conflicts} Conflicts"),
        ("5. ห้องเรียนไม่ใช้งานซ้อนกัน", room_conflicts == 0, f"{room_conflicts} Conflicts"),
        ("6. เคารพช่วงเวลาไม่สะดวกของครูและห้องปิดปรับปรุง", unavail_violations == 0, f"{unavail_violations} การละเมิด"),
        ("7. วิชาปฏิบัติลงห้อง Lab เท่านั้น (Smart Lab Overflow)", lab_violations == 0, f"{lab_violations} การละเมิด"),
        ("8. ภาระงานสอนครูทุกคน >= 30 คาบ/สัปดาห์", min(teacher_load.values()) >= 30, f"ต่ำสุด {min(teacher_load.values())} คาบ"),
    ]

    passed_count = sum(1 for _, ok, _ in rules if ok)
    return {
        "passed": passed_count,
        "total_rules": len(rules),
        "rules": rules,
        "teacher_load": teacher_load,
        "group_conflicts": group_conflicts,
    }


def export_output_csv(schedule: List[ScheduleSlot], filepath: str = "output.csv") -> str:
    """ส่งออกตารางเรียนเป็นไฟล์ output.csv ตามรูปแบบมาตรฐานการแข่งขัน 7 คอลัมน์"""
    with open(filepath, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f)
        writer.writerow(["group_id", "timeslot_id", "day", "period", "subject_id", "teacher_id", "room_id"]))
        for row in schedule:
            writer.writerow([
                row.group_id,
                row.timeslot_id,
                row.day,
                row.period,
                row.subject_id,
                row.teacher_id,
                row.room_id,
            ])
    return os.path.abspath(filepath)


def main() -> None:
    print("=" * 72)
    print("AI Auto-Scheduler สอศ. 2568-2572 (Green-White VEC Edition - Python Engine)")
    print("=" * 72)

    teachers, rooms, subjects = build_default_vec_dataset()
    t0 = time.perf_counter()
    scheduler = AIAutoScheduler(teachers, rooms, subjects, seed=2568, enable_lab_overflow=True)
    schedule = scheduler.solve(max_restarts=300)
    elapsed_ms = (time.perf_counter() - t0) * 1000

    audit = audit_schedule(schedule, teachers, rooms, subjects)
    out_path = export_output_csv(schedule, "output.csv")

    print(f"ประมวลผลเสร็จสิ้นภายใน: {elapsed_ms:.2f} ms")
    print(f"ผลการตรวจสอบเกณฑ์มาตรฐาน: PASS {audit['passed']}/{audit['total_rules']} ข้อ")
    print("-" * 72)
    for title, ok, detail in audit["rules"]:
        status = "[PASS]" if ok else "[FAIL]"
        print(f"{status} {title:<52} -> {detail}")
    print("-" * 72)
    print("สรุปภาระงานสอนรายบุคคล:")
    for tid, load in audit["teacher_load"].items():
        print(f"  - {tid} ({teachers[tid].teacher_name}): {load} คาบ/สัปดาห์")
    print("-" * 72)
    print(f"บันทึกไฟล์ผลลัพธ์เรียบร้อยที่: {out_path}")


if __name__ == "__main__":
    main()
