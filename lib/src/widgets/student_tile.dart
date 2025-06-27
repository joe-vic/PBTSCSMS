import 'package:flutter/material.dart';
import '../models/student.dart';

class StudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback? onTap;

  const StudentTile({required this.student, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${student.firstName} ${student.lastName}'),
      subtitle: Text('Grade: ${student.gradeLevel}'),
      onTap: onTap,
    );
  }
}