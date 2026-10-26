import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TeacherApp());
}

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class TeacherApp extends StatelessWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'إدارة سنتر أستاذ أحمد الخولي',
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF2563EB),
            brightness: Brightness.light,
            fontFamily: 'Cairo',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF2563EB),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF070D12),
            cardColor: const Color(0xFF0F1720),
            fontFamily: 'Cairo',
          ),
          home: const SplashScreen(teacherName: 'أستاذ أحمد الخولي'),
        );
      },
    );
  }
}

// ================= شاشة الترحيب (7 ثواني مع الكرات المتحركة وتوقيع المطور) =================
class SplashScreen extends StatefulWidget {
  final String teacherName;
  const SplashScreen({super.key, required this.teacherName});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GradesHomeDashboard(teacherName: widget.teacherName)),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BallBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 75, color: Colors.amberAccent),
                ),
                const SizedBox(height: 24),
                Text(widget.teacherName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('الأول على كلية الرياضيات 🌟', style: TextStyle(fontSize: 16, color: Colors.cyanAccent, fontWeight: FontWeight.w600)),
                const SizedBox(height: 30),
                const Text('صنع بواسطة: حازم ناصر عبدالظاهر\n📞 01127485412', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 30),
                const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= خلفية الكرات المتحركة =================
class BallBackground extends StatelessWidget {
  final Widget child;
  const BallBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D12),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBallsCustomPaint()),
          child,
        ],
      ),
    );
  }
}

class AnimatedBallsCustomPaint extends StatefulWidget {
  const AnimatedBallsCustomPaint({super.key});

  @override
  State<AnimatedBallsCustomPaint> createState() => _AnimatedBallsCustomPaintState();
}

class _AnimatedBallsCustomPaintState extends State<AnimatedBallsCustomPaint> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(painter: BallsPainter(_animController.value), size: Size.infinite);
      },
    );
  }
}

class BallsPainter extends CustomPainter {
  final double progress;
  BallsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2.5);
    paint.color = const Color(0xFF2563EB).withOpacity(0.05);
    canvas.drawCircle(center, 150 + math.sin(progress * 2 * math.pi) * 20, paint);

    final ballPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8;
    final List<Offset> positions = [
      Offset(size.width * 0.2, size.height * 0.15),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.85, size.height * 0.9),
    ];

    for (int i = 0; i < positions.length; i++) {
      double angle = progress * 2 * math.pi + i;
      double x = positions[i].dx + math.cos(angle) * 20;
      double y = positions[i].dy + math.sin(angle * 0.8) * 20;
      double radius = 20 + math.sin(progress * 4 * math.pi + i) * 8;
      ballPaint.color = Colors.cyanAccent.withOpacity(0.12 + (i * 0.03));
      canvas.drawCircle(Offset(x, y), radius, ballPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// نماذج البيانات
class StudyGroup {
  String days;
  String timeFrom;
  String timeTo;

  StudyGroup({required this.days, required this.timeFrom, required this.timeTo});

  Map<String, dynamic> toJson() => {'days': days, 'timeFrom': timeFrom, 'timeTo': timeTo};
  factory StudyGroup.fromJson(Map<String, dynamic> json) => StudyGroup(
        days: json['days'],
        timeFrom: json['timeFrom'],
        timeTo: json['timeTo'],
      );
}

class Student {
  String name;
  String phone;
  String groupDetails;
  bool isPresent;
  String attendanceTime;
  Map<String, bool> paidMonths;
  double customPaidAmount; // المبلغ الإجمالي المدفوع للتحقق من الزيادة والنقصان

  Student({
    required this.name,
    required this.phone,
    required this.groupDetails,
    this.isPresent = false,
    this.attendanceTime = '-',
    Map<String, bool>? paidMonths,
    this.customPaidAmount = 0.0,
  }) : paidMonths = paidMonths ?? {
          // الترم الأول
          'سبتمبر (ترم 1)': false, 'أكتوبر (ترم 1)': false, 'نوفمبر (ترم 1)': false, 'ديسمبر (ترم 1)': false, 'يناير (ترم 1)': false,
          // الترم الثاني
          'فبراير (ترم 2)': false, 'مارس (ترم 2)': false, 'أبريل (ترم 2)': false, 'مايو (ترم 2)': false, 'يونيو (ترم 2)': false
        };

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'groupDetails': groupDetails,
        'isPresent': isPresent,
        'attendanceTime': attendanceTime,
        'paidMonths': paidMonths,
        'customPaidAmount': customPaidAmount,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        name: json['name'],
        phone: json['phone'] ?? '',
        groupDetails: json['groupDetails'] ?? 'بدون مجموعة',
        isPresent: json['isPresent'] ?? false,
        attendanceTime: json['attendanceTime'] ?? '-',
        paidMonths: json['paidMonths'] != null ? Map<String, bool>.from(json['paidMonths']) : null,
        customPaidAmount: json['customPaidAmount'] != null ? (json['customPaidAmount'] as num).toDouble() : 0.0,
      );
}

// ================= شاشة الصفوف الرئيسية =================
class GradesHomeDashboard extends StatelessWidget {
  final String teacherName;
  const GradesHomeDashboard({super.key, required this.teacherName});

  void _openGradeScreen(BuildContext context, String gradeName) async {
    final prefs = await SharedPreferences.getInstance();
    double? savedAmount = prefs.getDouble('grade_amount_$gradeName');
    if (savedAmount != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => GradeDetailScreen(gradeName: gradeName, initialAmount: savedAmount)));
    } else {
      _showAmountDialog(context, gradeName);
    }
  }

  void _showAmountDialog(BuildContext context, String gradeName) {
    final ctrl = TextEditingController(text: '150');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('سعر الشهر لـ $gradeName'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'المبلغ الأساسي (ج.م)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () async {
              double val = double.tryParse(ctrl.text) ?? 150;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('grade_amount_$gradeName', val);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => GradeDetailScreen(gradeName: gradeName, initialAmount: val)));
              }
            },
            child: const Text('حسن / موافق'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚙️ الإعدادات ولمحة عن التطبيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6, color: Colors.cyanAccent),
              title: const Text('الوضع الداكن / الساطع'),
              trailing: Switch(
                value: themeNotifier.value == ThemeMode.dark,
                onChanged: (val) {
                  themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(),
            const Text('لمحة عن التطبيق:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
            const SizedBox(height: 6),
            const Text('إدارة سنتر أستاذ أحمد الخولي - الأول على كلية الرياضيات.\nصنع بواسطة: حازم ناصر عبدالظاهر\n📞 01127485412', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> grades = ['الصف الأول الإعدادي', 'الصف الثاني الإعدادي', 'الصف الثالث الإعدادي'];

    return BallBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('أهلاً بك، $teacherName 🌟', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              const Text('الأول على كلية الرياضيات', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.cyanAccent),
              tooltip: 'الإعدادات',
              onPressed: () => _showSettingsDialog(context),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اختر الصف الدراسي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: grades.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            color: const Color(0xFF0F1720),
                            elevation: 3,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _openGradeScreen(context, grades[index]),
                              child: Padding(
                                padding: const EdgeInsets.all(22.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.15), shape: BoxShape.circle),
                                      child: const Icon(Icons.school_outlined, color: Color(0xFF2563EB), size: 26),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(grades[index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                          const SizedBox(height: 4),
                                          const Text('إدارة المجموعات، الحضور، والترم الأول والثاني', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.cyanAccent, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= شاشة تفاصيل الصف والترم الأول والثاني =================
class GradeDetailScreen extends StatefulWidget {
  final String gradeName;
  final double initialAmount;
  const GradeDetailScreen({super.key, required this.gradeName, required this.initialAmount});

  @override
  State<GradeDetailScreen> createState() => _GradeDetailScreenState();
}

class _GradeDetailScreenState extends State<GradeDetailScreen> with SingleTickerProviderStateMixin {
  late double gradeRequiredAmount;
  List<StudyGroup> groups = [];
  List<Student> students = [];
  late TabController _tabController;
  
  String selectedFilter = 'كل الطلاب';
  String attendanceFilter = 'الكل';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    gradeRequiredAmount = widget.initialAmount;
    _tabController = TabController(length: 2, vsync: this);
    _loadDataFromDevice();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _loadDataFromDevice() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? gData = prefs.getString('groups_${widget.gradeName}');
    if (gData != null) {
      groups = (jsonDecode(gData) as List).map((e) => StudyGroup.fromJson(e)).toList();
    } else {
      groups = [StudyGroup(days: 'سبت، اثنين، أربعاء', timeFrom: '02:00 م', timeTo: '04:00 م')];
    }

    String? sData = prefs.getString('students_${widget.gradeName}');
    if (sData != null) {
      students = (jsonDecode(sData) as List).map((e) => Student.fromJson(e)).toList();
    } else {
      students = [];
    }
    setState(() {});
  }

  void _saveDataToDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groups_${widget.gradeName}', jsonEncode(groups.map((e) => e.toJson()).toList()));
    await prefs.setString('students_${widget.gradeName}', jsonEncode(students.map((e) => e.toJson()).toList()));
  }

  void _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanPhone");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  void _editGradeAmountDialog() {
    final ctrl = TextEditingController(text: gradeRequiredAmount.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تعديل سعر الشهر لـ ${widget.gradeName}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'المبلغ الجديد للشهر (ج.م)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () async {
              double val = double.tryParse(ctrl.text) ?? gradeRequiredAmount;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('grade_amount_${widget.gradeName}', val);
              setState(() => gradeRequiredAmount = val);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ التعديل'),
          ),
        ],
      ),
    );
  }

  void _addGroupDialog({StudyGroup? groupToEdit}) {
    String selectedDays = groupToEdit?.days ?? 'سبت، اثنين، أربعاء';
    final timeFromCtrl = TextEditingController(text: groupToEdit?.timeFrom ?? '02:00 م');
    final timeToCtrl = TextEditingController(text: groupToEdit?.timeTo ?? '04:00 م');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(groupToEdit == null ? 'إضافة مجموعة جديدة (من وإلى)' : 'تعديل المجموعة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDays,
                decoration: InputDecoration(labelText: 'الأيام', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 'سبت، اثنين، أربعاء', child: Text('سبت، اثنين، أربعاء')),
                  DropdownMenuItem(value: 'حد، ثلاثاء، خميس', child: Text('حد، ثلاثاء، خميس')),
                ],
                onChanged: (val) => setDialogState(() => selectedDays = val!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: timeFromCtrl, decoration: InputDecoration(labelText: 'من', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: timeToCtrl, decoration: InputDecoration(labelText: 'إلى', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  if (groupToEdit == null) {
                    groups.add(StudyGroup(days: selectedDays, timeFrom: timeFromCtrl.text, timeTo: timeToCtrl.text));
                  } else {
                    groupToEdit.days = selectedDays;
                    groupToEdit.timeFrom = timeFromCtrl.text;
                    groupToEdit.timeTo = timeToCtrl.text;
                  }
                  _saveDataToDevice();
                });
                Navigator.pop(context);
              },
              child: const Text('حسن / موافق'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteGroup(StudyGroup group) {
    String gStr = '${group.days} (${group.timeFrom} إلى ${group.timeTo})';
    setState(() {
      groups.remove(group);
      students.removeWhere((s) => s.groupDetails == gStr);
      if (selectedFilter == gStr) selectedFilter = 'كل الطلاب';
      _saveDataToDevice();
    });
  }

  void _addOrEditStudentDialog(String assignedGroup, {Student? studentToEdit}) {
    final nameCtrl = TextEditingController(text: studentToEdit?.name ?? '');
    final phoneCtrl = TextEditingController(text: studentToEdit?.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(studentToEdit == null ? 'إضافة طالب للمجموعة ($assignedGroup)' : 'تعديل بيانات الطالب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'اسم الطالب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'رقم الواتساب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  if (studentToEdit == null) {
                    students.add(Student(name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim(), groupDetails: assignedGroup));
                  } else {
                    studentToEdit.name = nameCtrl.text.trim();
                    studentToEdit.phone = phoneCtrl.text.trim();
                  }
                  _saveDataToDevice();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('حسن / موافق'),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(Student student) {
    setState(() {
      students.remove(student);
      _saveDataToDevice();
    });
  }

  // نافذة إدخال المبلغ المدفوع الفعلي وحساب الزيادة (باقي له) أو النقصان (باقي عليه)
  void _editStudentPaymentDialog(Student student) {
    final amountCtrl = TextEditingController(text: student.customPaidAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تسجيل المبلغ المدفوع لـ ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'إجمالي المبلغ المدفوع (ج.م)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                student.customPaidAmount = double.tryParse(amountCtrl.text) ?? 0.0;
                _saveDataToDevice();
              });
              Navigator.pop(context);
            },
            child: const Text('حساب وحفظ'),
          ),
        ],
      ),
    );
  }

  void _showStudentReceipt(Student student) {
    int paidMonthsCount = student.paidMonths.values.where((v) => v).length;
    double requiredTotal = paidMonthsCount * gradeRequiredAmount;
    double diff = student.customPaidAmount - requiredTotal;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF0F1720),
        title: const Text('🧾 إيصال سداد المصروفات والترمات', style: TextStyle(color: Colors.amberAccent, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اسم الطالب: ${student.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('المجموعة: ${student.groupDetails}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
            const Divider(color: Colors.white24),
            Text('الشهور المدفوعة: $paidMonthsCount أشهر', style: const TextStyle(color: Colors.white)),
            Text('المطلوب إجمالياً: $requiredTotal ج.م', style: const TextStyle(color: Colors.grey)),
            Text('المدفوع الفعلي: ${student.customPaidAmount} ج.م', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24),
            if (diff > 0)
              Text('🟢 باقي له (رصيد دائن): +$diff ج.م', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))
            else if (diff < 0)
              Text('🔴 باقي عليه (مديونية): $diff ج.م', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
            else
              const Text('⚖️ الحساب متوازن تماماً', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('🌟 تم الاعتماد من أستاذ أحمد الخولي', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const Text('صنع بواسطة: حازم ناصر عبدالظاهر (01127485412)', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Student> displayedStudents = students.where((s) {
      bool matchesFilter = (selectedFilter == 'كل الطلاب') || 
                           (selectedFilter == 'كل المجاميع') || 
                           (s.groupDetails == selectedFilter);
      bool matchesSearch = s.name.toLowerCase().contains(searchController.text.toLowerCase());
      
      bool matchesAttendance = true;
      if (attendanceFilter == 'حاضر') matchesAttendance = s.isPresent;
      if (attendanceFilter == 'غائب') matchesAttendance = !s.isPresent;

      return matchesFilter && matchesSearch && matchesAttendance;
    }).toList();

    List<String> filterOptions = ['كل الطلاب', 'كل المجاميع', ...groups.map((g) => '${g.days} (${g.timeFrom} إلى ${g.timeTo})')];
    
    int presentCount = students.where((s) => s.isPresent).length;
    int absentCount = students.length - presentCount;

    return BallBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.gradeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              Text('سعر الشهر: $gradeRequiredAmount ج.م | الحضور: $presentCount | الغياب: $absentCount', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.amberAccent),
              tooltip: 'تعديل سعر الشهر',
              onPressed: _editGradeAmountDialog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF2563EB),
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.fact_check_outlined, size: 18), text: 'الحضور والمجموعات'),
              Tab(icon: Icon(Icons.payment_outlined, size: 18), text: 'نظام الدفع والترمات'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // التبويب الأول: الحضور والمجموعات
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن اسم الطالب...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                      filled: true,
                      fillColor: const Color(0xFF0F1720),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => _addGroupDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة مجموعة جديدة (من وإلى)'),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filterOptions.map((opt) {
                        bool isSelected = selectedFilter == opt;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(opt),
                            selected: isSelected,
                            selectedColor: const Color(0xFF2563EB),
                            backgroundColor: const Color(0xFF0F1720),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                            onSelected: (val) => setState(() => selectedFilter = opt),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['الكل', 'حاضر', 'غائب'].map((status) {
                      bool isSel = attendanceFilter == status;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSel,
                          selectedColor: Colors.cyanAccent.withOpacity(0.2),
                          backgroundColor: const Color(0xFF0F1720),
                          labelStyle: TextStyle(color: isSel ? Colors.cyanAccent : Colors.grey, fontSize: 11),
                          onSelected: (val) => setState(() => attendanceFilter = status),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        ...groups.map((g) {
                          String gStr = '${g.days} (${g.timeFrom} إلى ${g.timeTo})';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: const Color(0xFF0F1720),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('مجموعة الأيام: ${g.days}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text('من ${g.timeFrom} إلى ${g.timeTo}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 6)),
                                        onPressed: () => setState(() => selectedFilter = gStr),
                                        child: const Text('عرض', style: TextStyle(fontSize: 10)),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.attach_money, color: Colors.amberAccent, size: 18),
                                        tooltip: 'تعديل السعر',
                                        onPressed: _editGradeAmountDialog,
                                      ),
                                      IconButton(icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 18), onPressed: () => _addGroupDialog(groupToEdit: g)),
                                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), onPressed: () => _deleteGroup(g)),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 6)),
                                        onPressed: () => _addOrEditStudentDialog(gStr),
                                        child: const Text('طالب', style: TextStyle(fontSize: 10)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const Divider(color: Colors.white24, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('قائمة الحضور والغياب:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                            Text('العدد: ${displayedStudents.length}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...displayedStudents.map((student) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: const Color(0xFF0F1720),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(student.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text('المجموعة: ${student.groupDetails}\nالحالة: ${student.isPresent ? "حاضر (${student.attendanceTime})" : "غائب"}', 
                                style: TextStyle(fontSize: 11, color: student.isPresent ? Colors.greenAccent : Colors.redAccent)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.chat, color: Colors.green, size: 18), onPressed: () => _openWhatsApp(student.phone)),
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 18), onPressed: () => _addOrEditStudentDialog(student.groupDetails, studentToEdit: student)),
                                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), onPressed: () => _deleteStudent(student)),
                                  Switch(
                                    value: student.isPresent,
                                    activeColor: Colors.green,
                                    inactiveThumbColor: Colors.redAccent,
                                    onChanged: (val) {
                                      setState(() {
                                        student.isPresent = val;
                                        student.attendanceTime = val ? DateFormat('hh:mm a').format(DateTime.now()) : '-';
                                        _saveDataToDevice();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // التبويب الثاني: نظام الدفع والترمات (الترم الأول والترم الثاني وحساب الزيادة والنقصان)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filterOptions.map((opt) {
                        bool isSelected = selectedFilter == opt;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(opt),
                            selected: isSelected,
                            selectedColor: const Color(0xFF2563EB),
                            backgroundColor: const Color(0xFF0F1720),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                            onSelected: (val) => setState(() => selectedFilter = opt),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: displayedStudents.isEmpty
                        ? const Center(child: Text('لا توجد بيانات دفع للعرض', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: displayedStudents.length,
                            itemBuilder: (context, index) {
                              final student = displayedStudents[index];
                              int paidCount = student.paidMonths.values.where((v) => v).length;
                              double reqTotal = paidCount * gradeRequiredAmount;
                              double diff = student.customPaidAmount - reqTotal;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: const Color(0xFF0F1720),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ExpansionTile(
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.payments_outlined, color: Colors.cyanAccent, size: 20),
                                            tooltip: 'تسجيل المبلغ المدفوع الفعلي',
                                            onPressed: () => _editStudentPaymentDialog(student),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.receipt_long_rounded, color: Colors.amberAccent, size: 20),
                                            tooltip: 'إيصال السداد',
                                            onPressed: () => _showStudentReceipt(student),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('المدفوع: ${student.customPaidAmount} ج.م | مطلوب: $reqTotal ج.م', style: const TextStyle(fontSize: 12, color: Colors.cyanAccent)),
                                      if (diff > 0)
                                        Text('🟢 باقي له (رصيد دائن): +$diff ج.م', style: const TextStyle(fontSize: 11, color: Colors.greenAccent))
                                      else if (diff < 0)
                                        Text('🔴 باقي عليه (مديونية): $diff ج.م', style: const TextStyle(fontSize: 11, color: Colors.redAccent))
                                      else
                                        const Text('⚖️ الحساب متوازن', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('📅 توزيع الترم الأول والترم الثاني:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                                          const SizedBox(height: 8),
                                          ...student.paidMonths.keys.map((month) {
                                            bool isPaid = student.paidMonths[month] ?? false;
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(month, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                                  Row(
                                                    children: [
                                                      Switch(
                                                        value: isPaid,
                                                        activeColor: Colors.green,
                                                        inactiveThumbColor: Colors.redAccent,
                                                        onChanged: (val) {
                                                          setState(() {
                                                            student.paidMonths[month] = val;
                                                            _saveDataToDevice();
                                                          });
                                                        },
                                                      ),
                                                      Text(isPaid ? 'مدفوع' : 'غير مدفوع', style: TextStyle(fontSize: 11, color: isPaid ? Colors.greenAccent : Colors.redAccent)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}