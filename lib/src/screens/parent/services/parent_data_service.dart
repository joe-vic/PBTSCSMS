import 'package:flutter/material.dart';
import '../../../models/student_model.dart';

/// 🎯 PURPOSE: Handle ALL data operations for parent dashboard
/// 📝 WHAT IT DOES: Provides students, payments, events, announcements
/// 🔧 HOW TO USE: final service = ParentDataService(); await service.getStudents();
class ParentDataService {
  
  /// 📢 Gets school announcements
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
    
    return [
      {
        'title': 'DepEd Order: Face-to-Face Classes Resume',
        'content': 'All schools will resume full face-to-face classes starting next week. Health protocols will remain in place.',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'priority': 'high',
      },
      {
        'title': 'Parent-Teacher Conference Schedule',
        'content': 'Quarterly parent-teacher meetings will be held on June 5-7. Please coordinate with your child\'s advisers.',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'priority': 'medium',
      },
      {
        'title': 'National Achievement Test (NAT)',
        'content': 'Grade 6 and Grade 10 students will take the NAT on June 20-21. Review schedules have been posted.',
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'priority': 'high',
      },
    ];
  }

  /// 👨‍👩‍👧‍👦 Gets student list for this parent
  Future<List<StudentModel>> getStudents() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate loading
    
    return [
      _createStudentModel(
        id: 'LRN-123456789012',
        name: 'John Smith',
        grade: 'Grade 10',
        className: '10-Einstein',
      ),
      _createStudentModel(
        id: 'LRN-123456789013',
        name: 'Emma Johnson',
        grade: 'Grade 8',
        className: '8-Newton',
      ),
    ];
  }

  /// 💰 Gets payment information
  Future<List<Map<String, dynamic>>> getPayments() async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate loading
    
    return [
      {
        'id': 'PAY2024001',
        'studentId': 'LRN-123456789012',
        'studentName': 'John Smith',
        'amount': 2500.0,
        'type': 'Miscellaneous Fee',
        'dueDate': DateTime.now().add(const Duration(days: 15)),
        'status': 'pending',
        'description': 'Q2 Miscellaneous Fee (Laboratory, Library, Computer)',
        'breakdown': {
          'Laboratory Fee': 800.0,
          'Library Fee': 500.0,
          'Computer Fee': 700.0,
          'Sports Fee': 300.0,
          'Maintenance Fee': 200.0,
        }
      },
      {
        'id': 'PAY2024002',
        'studentId': 'LRN-123456789012',
        'studentName': 'John Smith',
        'amount': 2000.0,
        'type': 'Miscellaneous Fee',
        'dueDate': DateTime.now().subtract(const Duration(days: 30)),
        'status': 'paid',
        'description': 'Q1 Miscellaneous Fee',
        'paidDate': DateTime.now().subtract(const Duration(days: 25)),
        'receiptNumber': 'OR-2024-001234',
      },
      {
        'id': 'PAY2024003',
        'studentId': 'LRN-123456789013',
        'studentName': 'Emma Johnson',
        'amount': 1800.0,
        'type': 'Project Fee',
        'dueDate': DateTime.now().add(const Duration(days: 7)),
        'status': 'pending',
        'description': 'Science Fair Project Materials',
      },
    ];
  }

  /// 📅 Gets school events and calendar
  Future<List<Map<String, dynamic>>> getEvents() async {
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate loading
    
    return [
      {
        'id': 'EVT001',
        'title': 'First Quarter Examination',
        'date': DateTime.now().add(const Duration(days: 10)),
        'endDate': DateTime.now().add(const Duration(days: 12)),
        'time': '7:30 AM - 4:30 PM',
        'location': 'All Classrooms',
        'type': 'academic',
        'description': 'First quarter examinations for all grade levels',
      },
      {
        'id': 'EVT002',
        'title': 'Science and Mathematics Festival',
        'date': DateTime.now().add(const Duration(days: 20)),
        'endDate': DateTime.now().add(const Duration(days: 21)),
        'time': '8:00 AM - 5:00 PM',
        'location': 'School Gymnasium',
        'type': 'event',
        'description': 'Annual Science and Mathematics Festival showcasing student projects',
      },
      {
        'id': 'EVT003',
        'title': 'Semestral Break',
        'date': DateTime.now().add(const Duration(days: 25)),
        'endDate': DateTime.now().add(const Duration(days: 32)),
        'time': 'All Day',
        'location': 'School Closed',
        'type': 'holiday',
        'description': 'Semestral break - no classes',
      },
      {
        'id': 'EVT004',
        'title': 'Parent-Teacher Conference',
        'date': DateTime.now().add(const Duration(days: 35)),
        'time': '8:00 AM - 12:00 PM',
        'location': 'Respective Classrooms',
        'type': 'meeting',
        'description': 'Quarterly parent-teacher meetings to discuss student progress',
      },
      {
        'id': 'EVT005',
        'title': 'National Achievement Test (NAT)',
        'date': DateTime.now().add(const Duration(days: 40)),
        'endDate': DateTime.now().add(const Duration(days: 41)),
        'time': '8:00 AM - 12:00 PM',
        'location': 'Testing Centers',
        'type': 'assessment',
        'description': 'National Achievement Test for Grade 6 and 10 students',
      },
    ];
  }

  /// 💳 Process a payment (placeholder for real payment integration)
  Future<bool> processPayment(Map<String, dynamic> payment) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing
    // In real app, integrate with payment gateway
    return true; // Success
  }

  // 🏗️ PRIVATE HELPER METHOD: Creates a complete student model
  StudentModel _createStudentModel({
    required String id,
    required String name,
    required String grade,
    required String className,
  }) {
    // Create realistic monthly attendance records
    final monthlyRecords = [
      MonthlyAttendance(
        month: 'June',
        year: 2024,
        present: name == 'John Smith' ? 18 : 17,
        absent: name == 'John Smith' ? 1 : 2,
        late: name == 'John Smith' ? 1 : 1,
        dailyRecords: [],
      ),
      MonthlyAttendance(
        month: 'July',
        year: 2024,
        present: name == 'John Smith' ? 21 : 19,
        absent: name == 'John Smith' ? 0 : 1,
        late: name == 'John Smith' ? 1 : 2,
        dailyRecords: [],
      ),
      MonthlyAttendance(
        month: 'August',
        year: 2024,
        present: name == 'John Smith' ? 20 : 18,
        absent: name == 'John Smith' ? 1 : 2,
        late: name == 'John Smith' ? 1 : 2,
        dailyRecords: [],
      ),
    ];

    // Create quarter records based on DepEd grading system
    final quarters = [
      QuarterRecord(quarter: 1, grade: 88.5, exams: [], quizzes: [], projects: []),
      QuarterRecord(quarter: 2, grade: 90.0, exams: [], quizzes: [], projects: []),
    ];

    // Create subject records based on K-12 curriculum
    final subjects = grade == 'Grade 10' ? [
      SubjectRecord(subject: 'English', teacher: 'Ms. Garcia', currentGrade: 88.5, quarterGrades: []),
      SubjectRecord(subject: 'Filipino', teacher: 'Mrs. Santos', currentGrade: 92.0, quarterGrades: []),
      SubjectRecord(subject: 'Mathematics', teacher: 'Mr. Cruz', currentGrade: 85.5, quarterGrades: []),
      SubjectRecord(subject: 'Science', teacher: 'Ms. Reyes', currentGrade: 90.0, quarterGrades: []),
      SubjectRecord(subject: 'Araling Panlipunan', teacher: 'Mr. Dela Cruz', currentGrade: 87.0, quarterGrades: []),
      SubjectRecord(subject: 'Values Education', teacher: 'Mrs. Lopez', currentGrade: 95.0, quarterGrades: []),
      SubjectRecord(subject: 'PE and Health', teacher: 'Coach Martinez', currentGrade: 93.0, quarterGrades: []),
      SubjectRecord(subject: 'TLE - ICT', teacher: 'Mr. Fernandez', currentGrade: 89.0, quarterGrades: []),
    ] : [
      SubjectRecord(subject: 'English', teacher: 'Ms. Hernandez', currentGrade: 86.0, quarterGrades: []),
      SubjectRecord(subject: 'Filipino', teacher: 'Mrs. Morales', currentGrade: 90.5, quarterGrades: []),
      SubjectRecord(subject: 'Mathematics', teacher: 'Mr. Villanueva', currentGrade: 82.3, quarterGrades: []),
      SubjectRecord(subject: 'Science', teacher: 'Ms. Castro', currentGrade: 87.5, quarterGrades: []),
      SubjectRecord(subject: 'Araling Panlipunan', teacher: 'Mr. Torres', currentGrade: 85.0, quarterGrades: []),
      SubjectRecord(subject: 'Values Education', teacher: 'Mrs. Ramos', currentGrade: 94.0, quarterGrades: []),
      SubjectRecord(subject: 'PE and Health', teacher: 'Coach Silva', currentGrade: 91.0, quarterGrades: []),
      SubjectRecord(subject: 'TLE - HE', teacher: 'Mrs. Valdez', currentGrade: 88.0, quarterGrades: []),
    ];

    // Create DepEd card with proper subjects
    final depEdCard = DepEdCard(
      learnerReferenceNumber: id,
      schoolYear: '2023-2024',
      track: grade == 'Grade 10' ? 'Academic Track' : 'N/A',
      strand: grade == 'Grade 10' ? 'STEM' : 'N/A',
      coreSubjects: {
        'English': 88.0,
        'Filipino': 92.0,
        'Mathematics': 85.0,
        'Science': 90.0,
        'Araling Panlipunan': 87.0,
      },
      appliedSubjects: {
        'PE and Health': 95.0,
        'Values Education': 93.0,
      },
      specializedSubjects: grade == 'Grade 10' ? {
        'Pre-Calculus': 89.0,
        'General Chemistry': 91.0,
        'General Physics': 88.0,
      } : {},
    );

    return StudentModel(
      id: id,
      name: name,
      grade: grade,
      className: className,
      profileImage: null,
      attendance: AttendanceRecord(
        percentage: name == 'John Smith' ? 95.5 : 89.2,
        daysPresent: name == 'John Smith' ? 172 : 160,
        totalDays: 180,
        lastAttendance: DateTime.now().subtract(const Duration(days: 1)),
        monthlyRecords: monthlyRecords,
      ),
      academics: AcademicRecord(
        gpa: name == 'John Smith' ? 3.8 : 3.6,
        lastExamScore: name == 'John Smith' ? 88.5 : 82.3,
        lastQuizScore: name == 'John Smith' ? 92.0 : 87.5,
        rank: name == 'John Smith' ? 5 : 8,
        totalStudents: name == 'John Smith' ? 45 : 42,
        quarters: quarters,
        subjects: subjects,
      ),
      fees: FeesRecord(
        totalDue: name == 'John Smith' ? 15000.0 : 12000.0,
        paid: name == 'John Smith' ? 12000.0 : 12000.0,
        pending: name == 'John Smith' ? 3000.0 : 0.0,
        nextDueDate: DateTime.now().add(const Duration(days: 15)),
        paymentHistory: [],
      ),
      behavior: BehaviorRecord(
        rating: name == 'John Smith' ? 'Excellent' : 'Good',
        disciplinaryActions: name == 'John Smith' ? 0 : 1,
        teacherComments: name == 'John Smith' 
            ? 'Very well-behaved and participative student. Shows excellent leadership qualities.'
            : 'Shows improvement in class participation. Good attitude towards learning.',
      ),
      recentActivities: name == 'John Smith' ? [
        'Scored 95% in Mathematics Test',
        'Participated in Science Fair',
        'Won 1st place in Quiz Bee',
        'Completed Science Project ahead of deadline',
      ] : [
        'Won 2nd place in Art Competition',
        'Completed all assignments this week',
        'Participated in English Drama',
        'Improved attendance this month',
      ],
      depEdCard: depEdCard,
    );
  }
}