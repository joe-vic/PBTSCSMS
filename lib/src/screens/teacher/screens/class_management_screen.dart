import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../models/class_model.dart';
import '../services/class_service.dart';
import 'attendance_screen.dart';
import 'student_selection_screen.dart';

enum ClassManagementMode { create, edit, view }

class ClassManagementScreen extends StatefulWidget {
  final ClassManagementMode mode;
  final ClassModel? classModel;

  const ClassManagementScreen({
    Key? key,
    required this.mode,
    this.classModel,
  }) : super(key: key);

  @override
  _ClassManagementScreenState createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final ClassService _classService = ClassService();
  late TextEditingController _nameController;
  late TextEditingController _gradeLevelController;
  late TextEditingController _sectionController;
  late TextEditingController _subjectsController;
  bool _isHomeroom = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.classModel?.name ?? '');
    _gradeLevelController =
        TextEditingController(text: widget.classModel?.gradeLevel ?? '');
    _sectionController =
        TextEditingController(text: widget.classModel?.section ?? '');
    _subjectsController = TextEditingController(
        text: widget.classModel?.subjects.join(', ') ?? '');
    _isHomeroom = widget.classModel?.isHomeroom ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeLevelController.dispose();
    _sectionController.dispose();
    _subjectsController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherId = authProvider.user?.uid ?? '';

      final subjects = _subjectsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final classModel = ClassModel(
        id: widget.classModel?.id ?? '',
        name: _nameController.text,
        teacherId: teacherId,
        subjects: subjects,
        isHomeroom: _isHomeroom,
        gradeLevel: _gradeLevelController.text,
        section: _sectionController.text,
        studentIds: widget.classModel?.studentIds ?? [],
        createdAt: widget.classModel?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.mode == ClassManagementMode.create) {
        await _classService.createClass(classModel);
      } else {
        await _classService.updateClass(classModel);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Class saved successfully',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save class: $e',
            style: TextStyle(fontFamily: 'Poppins',),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addStudentsByGradeLevel() async {
    final selectedStudents = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => StudentSelectionScreen(
          gradeLevel: widget.classModel?.gradeLevel ?? '',
          alreadySelectedStudents: widget.classModel?.studentIds ?? [],
        ),
      ),
    );

    if (selectedStudents != null && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (widget.classModel != null) {
          await _classService.addStudentsToClass(
            widget.classModel!.id,
            selectedStudents,
          );

          // Refresh the class data
          final updatedClass =
              await _classService.getClassById(widget.classModel!.id);
          if (updatedClass != null && mounted) {
            setState(() {
              widget.classModel!.studentIds = updatedClass.studentIds;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding students: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: SMSTheme.primaryColor,
        actions: [
          if (widget.mode == ClassManagementMode.view)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassManagementScreen(
                      mode: ClassManagementMode.edit,
                      classModel: widget.classModel,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.mode == ClassManagementMode.view) ...[
                    _buildViewMode(),
                  ] else ...[
                    _buildEditMode(),
                  ],
                ],
              ),
            ),
      floatingActionButton: widget.mode == ClassManagementMode.view
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendanceScreen(
                      classModel: widget.classModel!,
                    ),
                  ),
                );
              },
              backgroundColor: SMSTheme.primaryColor,
              icon: const Icon(Icons.how_to_reg),
              label: Text(
                'Take Attendance',
                style: TextStyle(fontFamily: 'Poppins',),
              ),
            )
          : null,
    );
  }

  String _getTitle() {
    switch (widget.mode) {
      case ClassManagementMode.create:
        return 'Create Class';
      case ClassManagementMode.edit:
        return 'Edit Class';
      case ClassManagementMode.view:
        return widget.classModel?.name ?? 'View Class';
    }
  }

  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Class Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a class name';
              }
              return null;
            },
            style: TextStyle(fontFamily: 'Poppins',),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _gradeLevelController,
                  decoration: InputDecoration(
                    labelText: 'Grade Level',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a grade level';
                    }
                    return null;
                  },
                  style: TextStyle(fontFamily: 'Poppins',),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _sectionController,
                  decoration: InputDecoration(
                    labelText: 'Section',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a section';
                    }
                    return null;
                  },
                  style: TextStyle(fontFamily: 'Poppins',),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _subjectsController,
            decoration: InputDecoration(
              labelText: 'Subjects (comma-separated)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Math, Science, English',
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter at least one subject';
              }
              return null;
            },
            style: TextStyle(fontFamily: 'Poppins',),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Homeroom Class',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            value: _isHomeroom,
            onChanged: (value) {
              setState(() {
                _isHomeroom = value;
              });
            },
            activeColor: SMSTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveClass,
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save Class',
              style: TextStyle(fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewMode() {
    if (widget.classModel == null) {
      return const Center(child: Text('Class not found'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: widget.classModel!.isHomeroom
                          ? Colors.orange
                          : Colors.purple,
                      child: Icon(
                        widget.classModel!.isHomeroom ? Icons.home : Icons.book,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.classModel!.name,
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Grade ${widget.classModel!.gradeLevel} - Section ${widget.classModel!.section}',
                            style: TextStyle(fontFamily: 'Poppins',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildInfoRow('Type',
                    widget.classModel!.isHomeroom ? 'Homeroom' : 'Subject'),
                _buildInfoRow(
                    'Subjects', widget.classModel!.subjects.join(', ')),
                _buildInfoRow(
                    'Students', '${widget.classModel!.studentIds.length}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Students',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.classModel!.studentIds.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No students yet',
                  style: TextStyle(fontFamily: 'Poppins',
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.classModel!.studentIds.length,
            itemBuilder: (context, index) {
              final studentId = widget.classModel!.studentIds[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    'Student ID: $studentId',
                    style: TextStyle(fontFamily: 'Poppins',),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Remove Student',
                            style: TextStyle(fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600),
                          ),
                          content: Text(
                            'Are you sure you want to remove this student from the class?',
                            style: TextStyle(fontFamily: 'Poppins',),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(fontFamily: 'Poppins',color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Remove',
                                style: TextStyle(fontFamily: 'Poppins',color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm ?? false) {
                        try {
                          await _classService.removeStudentsFromClass(
                              widget.classModel!.id, [studentId]);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Student removed successfully',
                                  style: TextStyle(fontFamily: 'Poppins',),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to remove student: $e',
                                  style: TextStyle(fontFamily: 'Poppins',),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ElevatedButton(
          onPressed: _addStudentsByGradeLevel,
          style: ElevatedButton.styleFrom(
            backgroundColor: SMSTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add),
              const SizedBox(width: 8),
              Text(
                'Add Students',
                style: TextStyle(fontFamily: 'Poppins',),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Poppins',),
            ),
          ),
        ],
      ),
    );
  }
}
