class StudentModel {
  final String id;
  final String name;
  final String grade;
  final String className;
  final String? profileImage;
  final AttendanceRecord attendance;
  final AcademicRecord academics;
  final FeesRecord fees;
  final BehaviorRecord behavior;
  final List<String> recentActivities;
  final DepEdCard depEdCard;

  StudentModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.className,
    this.profileImage,
    required this.attendance,
    required this.academics,
    required this.fees,
    required this.behavior,
    required this.recentActivities,
    required this.depEdCard,
  });

  // Convert from Map (for compatibility with existing code)
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'],
      name: map['name'],
      grade: map['grade'],
      className: map['class'],
      profileImage: map['profileImage'],
      attendance: AttendanceRecord.fromMap(map['attendance']),
      academics: AcademicRecord.fromMap(map['academics']),
      fees: FeesRecord.fromMap(map['fees']),
      behavior: BehaviorRecord.fromMap(map['behavior']),
      recentActivities: List<String>.from(map['recentActivities']),
      depEdCard: DepEdCard.fromMap(map['depEdCard'] ?? {}),
    );
  }
}

class AttendanceRecord {
  final double percentage;
  final int daysPresent;
  final int totalDays;
  final DateTime lastAttendance;
  final List<MonthlyAttendance> monthlyRecords;

  AttendanceRecord({
    required this.percentage,
    required this.daysPresent,
    required this.totalDays,
    required this.lastAttendance,
    required this.monthlyRecords,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      percentage: map['percentage']?.toDouble() ?? 0.0,
      daysPresent: map['daysPresent'] ?? 0,
      totalDays: map['totalDays'] ?? 0,
      lastAttendance: map['lastAttendance'] ?? DateTime.now(),
      monthlyRecords: (map['monthlyRecords'] as List?)
          ?.map((m) => MonthlyAttendance.fromMap(m))
          .toList() ?? [],
    );
  }
}

class MonthlyAttendance {
  final String month;
  final int year;
  final int present;
  final int absent;
  final int late;
  final List<DailyAttendance> dailyRecords;

  MonthlyAttendance({
    required this.month,
    required this.year,
    required this.present,
    required this.absent,
    required this.late,
    required this.dailyRecords,
  });

  factory MonthlyAttendance.fromMap(Map<String, dynamic> map) {
    return MonthlyAttendance(
      month: map['month'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      present: map['present'] ?? 0,
      absent: map['absent'] ?? 0,
      late: map['late'] ?? 0,
      dailyRecords: (map['dailyRecords'] as List?)
          ?.map((d) => DailyAttendance.fromMap(d))
          .toList() ?? [],
    );
  }

  double get percentage => 
      (present / (present + absent + late) * 100).isNaN ? 0.0 : 
      (present / (present + absent + late) * 100);
}

class DailyAttendance {
  final DateTime date;
  final AttendanceStatus status;
  final String? remarks;

  DailyAttendance({
    required this.date,
    required this.status,
    this.remarks,
  });

  factory DailyAttendance.fromMap(Map<String, dynamic> map) {
    return DailyAttendance(
      date: map['date'] ?? DateTime.now(),
      status: AttendanceStatus.values.firstWhere(
        (s) => s.toString() == 'AttendanceStatus.${map['status']}',
        orElse: () => AttendanceStatus.present,
      ),
      remarks: map['remarks'],
    );
  }
}

enum AttendanceStatus { present, absent, late, excused }

class AcademicRecord {
  final double gpa;
  final double lastExamScore;
  final double lastQuizScore;
  final int rank;
  final int totalStudents;
  final List<QuarterRecord> quarters;
  final List<SubjectRecord> subjects;

  AcademicRecord({
    required this.gpa,
    required this.lastExamScore,
    required this.lastQuizScore,
    required this.rank,
    required this.totalStudents,
    required this.quarters,
    required this.subjects,
  });

  factory AcademicRecord.fromMap(Map<String, dynamic> map) {
    return AcademicRecord(
      gpa: map['gpa']?.toDouble() ?? 0.0,
      lastExamScore: map['lastExamScore']?.toDouble() ?? 0.0,
      lastQuizScore: map['lastQuizScore']?.toDouble() ?? 0.0,
      rank: map['rank'] ?? 0,
      totalStudents: map['totalStudents'] ?? 0,
      quarters: (map['quarters'] as List?)
          ?.map((q) => QuarterRecord.fromMap(q))
          .toList() ?? [],
      subjects: (map['subjects'] as List?)
          ?.map((s) => SubjectRecord.fromMap(s))
          .toList() ?? [],
    );
  }
}

class QuarterRecord {
  final int quarter;
  final double grade;
  final List<ExamRecord> exams;
  final List<QuizRecord> quizzes;
  final List<ProjectRecord> projects;

  QuarterRecord({
    required this.quarter,
    required this.grade,
    required this.exams,
    required this.quizzes,
    required this.projects,
  });

  factory QuarterRecord.fromMap(Map<String, dynamic> map) {
    return QuarterRecord(
      quarter: map['quarter'] ?? 1,
      grade: map['grade']?.toDouble() ?? 0.0,
      exams: (map['exams'] as List?)
          ?.map((e) => ExamRecord.fromMap(e))
          .toList() ?? [],
      quizzes: (map['quizzes'] as List?)
          ?.map((q) => QuizRecord.fromMap(q))
          .toList() ?? [],
      projects: (map['projects'] as List?)
          ?.map((p) => ProjectRecord.fromMap(p))
          .toList() ?? [],
    );
  }
}

class SubjectRecord {
  final String subject;
  final String teacher;
  final double currentGrade;
  final List<QuarterGrade> quarterGrades;

  SubjectRecord({
    required this.subject,
    required this.teacher,
    required this.currentGrade,
    required this.quarterGrades,
  });

  factory SubjectRecord.fromMap(Map<String, dynamic> map) {
    return SubjectRecord(
      subject: map['subject'] ?? '',
      teacher: map['teacher'] ?? '',
      currentGrade: map['currentGrade']?.toDouble() ?? 0.0,
      quarterGrades: (map['quarterGrades'] as List?)
          ?.map((q) => QuarterGrade.fromMap(q))
          .toList() ?? [],
    );
  }
}

class QuarterGrade {
  final int quarter;
  final double grade;
  final String remarks;

  QuarterGrade({
    required this.quarter,
    required this.grade,
    required this.remarks,
  });

  factory QuarterGrade.fromMap(Map<String, dynamic> map) {
    return QuarterGrade(
      quarter: map['quarter'] ?? 1,
      grade: map['grade']?.toDouble() ?? 0.0,
      remarks: map['remarks'] ?? '',
    );
  }
}

class ExamRecord {
  final String examName;
  final double score;
  final double maxScore;
  final DateTime date;
  final String subject;

  ExamRecord({
    required this.examName,
    required this.score,
    required this.maxScore,
    required this.date,
    required this.subject,
  });

  factory ExamRecord.fromMap(Map<String, dynamic> map) {
    return ExamRecord(
      examName: map['examName'] ?? '',
      score: map['score']?.toDouble() ?? 0.0,
      maxScore: map['maxScore']?.toDouble() ?? 100.0,
      date: map['date'] ?? DateTime.now(),
      subject: map['subject'] ?? '',
    );
  }

  double get percentage => (score / maxScore * 100);
}

class QuizRecord {
  final String quizName;
  final double score;
  final double maxScore;
  final DateTime date;
  final String subject;

  QuizRecord({
    required this.quizName,
    required this.score,
    required this.maxScore,
    required this.date,
    required this.subject,
  });

  factory QuizRecord.fromMap(Map<String, dynamic> map) {
    return QuizRecord(
      quizName: map['quizName'] ?? '',
      score: map['score']?.toDouble() ?? 0.0,
      maxScore: map['maxScore']?.toDouble() ?? 100.0,
      date: map['date'] ?? DateTime.now(),
      subject: map['subject'] ?? '',
    );
  }

  double get percentage => (score / maxScore * 100);
}

class ProjectRecord {
  final String projectName;
  final double score;
  final double maxScore;
  final DateTime submittedDate;
  final String subject;

  ProjectRecord({
    required this.projectName,
    required this.score,
    required this.maxScore,
    required this.submittedDate,
    required this.subject,
  });

  factory ProjectRecord.fromMap(Map<String, dynamic> map) {
    return ProjectRecord(
      projectName: map['projectName'] ?? '',
      score: map['score']?.toDouble() ?? 0.0,
      maxScore: map['maxScore']?.toDouble() ?? 100.0,
      submittedDate: map['submittedDate'] ?? DateTime.now(),
      subject: map['subject'] ?? '',
    );
  }

  double get percentage => (score / maxScore * 100);
}

class FeesRecord {
  final double totalDue;
  final double paid;
  final double pending;
  final DateTime nextDueDate;
  final List<PaymentRecord> paymentHistory;

  FeesRecord({
    required this.totalDue,
    required this.paid,
    required this.pending,
    required this.nextDueDate,
    required this.paymentHistory,
  });

  factory FeesRecord.fromMap(Map<String, dynamic> map) {
    return FeesRecord(
      totalDue: map['totalDue']?.toDouble() ?? 0.0,
      paid: map['paid']?.toDouble() ?? 0.0,
      pending: map['pending']?.toDouble() ?? 0.0,
      nextDueDate: map['nextDueDate'] ?? DateTime.now(),
      paymentHistory: (map['paymentHistory'] as List?)
          ?.map((p) => PaymentRecord.fromMap(p))
          .toList() ?? [],
    );
  }
}

class PaymentRecord {
  final double amount;
  final DateTime date;
  final String description;
  final String receiptNumber;

  PaymentRecord({
    required this.amount,
    required this.date,
    required this.description,
    required this.receiptNumber,
  });

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      amount: map['amount']?.toDouble() ?? 0.0,
      date: map['date'] ?? DateTime.now(),
      description: map['description'] ?? '',
      receiptNumber: map['receiptNumber'] ?? '',
    );
  }
}

class BehaviorRecord {
  final String rating;
  final int disciplinaryActions;
  final String teacherComments;

  BehaviorRecord({
    required this.rating,
    required this.disciplinaryActions,
    required this.teacherComments,
  });

  factory BehaviorRecord.fromMap(Map<String, dynamic> map) {
    return BehaviorRecord(
      rating: map['rating'] ?? '',
      disciplinaryActions: map['disciplinaryActions'] ?? 0,
      teacherComments: map['teacherComments'] ?? '',
    );
  }
}

class DepEdCard {
  final String learnerReferenceNumber;
  final String schoolYear;
  final String track;
  final String strand;
  final Map<String, double> coreSubjects;
  final Map<String, double> appliedSubjects;
  final Map<String, double> specializedSubjects;

  DepEdCard({
    required this.learnerReferenceNumber,
    required this.schoolYear,
    required this.track,
    required this.strand,
    required this.coreSubjects,
    required this.appliedSubjects,
    required this.specializedSubjects,
  });

  factory DepEdCard.fromMap(Map<String, dynamic> map) {
    return DepEdCard(
      learnerReferenceNumber: map['learnerReferenceNumber'] ?? '',
      schoolYear: map['schoolYear'] ?? '',
      track: map['track'] ?? '',
      strand: map['strand'] ?? '',
      coreSubjects: Map<String, double>.from(map['coreSubjects'] ?? {}),
      appliedSubjects: Map<String, double>.from(map['appliedSubjects'] ?? {}),
      specializedSubjects: Map<String, double>.from(map['specializedSubjects'] ?? {}),
    );
  }
}