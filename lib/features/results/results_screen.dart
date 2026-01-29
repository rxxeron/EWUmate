import 'package:flutter/material.dart';
import 'results_repository.dart';
import '../../core/models/result_models.dart';
import '../../core/widgets/glass_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ResultsRepository _repo = ResultsRepository();
  final User? user = FirebaseAuth.instance.currentUser;

  bool _loading = true;
  AcademicProfile? _profile;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final profile = await _repo.fetchAcademicProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const FullGradientScaffold(
          body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent)));
    }

    return FullGradientScaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            title: const Text("Degree Progress",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.print, color: Colors.cyanAccent),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Download PDF coming soon!")));
                },
              )
            ],
          ),
        ],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(color: Colors.cyanAccent, thickness: 1),
              const SizedBox(height: 10),
              if (_profile != null && _profile!.semesters.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No academic history found.",
                            style: TextStyle(color: Colors.white70))))
              else if (_profile != null)
                ..._profile!.semesters.map((sem) => _buildSemesterBlock(sem)),
              const Divider(color: Colors.cyanAccent, thickness: 1),
              _buildSummary(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Formal University Header
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("EAST WEST UNIVERSITY",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Serif',
                        color: Colors.white)),
                SizedBox(height: 2),
                Text("Student's Copy",
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
            Icon(Icons.school, color: Colors.cyanAccent, size: 30)
          ],
        ),
        const SizedBox(height: 15),

        // 2. Student Info Map
        GlassContainer(
          padding: const EdgeInsets.all(12),
          borderRadius: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow("Name:",
                  _profile?.studentName ?? user?.displayName ?? 'Student'),
              const SizedBox(height: 4),
              _infoRow("ID:", _profile?.studentId ?? 'N/A'),
              const SizedBox(height: 4),
              _infoRow(
                  "Degree:",
                  (_profile?.program ?? "").isNotEmpty
                      ? _profile!.program
                      : 'B.Sc. in CSE'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Stats Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _statCard(
                "Completed Credits",
                "${_profile?.totalCreditsEarned.toStringAsFixed(1)}",
                Colors.blueAccent),
            _statCard("Completed Courses", "${_profile?.totalCoursesCompleted}",
                Colors.orangeAccent),
            _statCard("CGPA", "${_profile?.cgpa.toStringAsFixed(2)}",
                Colors.greenAccent),
            _statCard(
                "Remaining Credits",
                "${_profile?.remainedCredits.toStringAsFixed(1)}",
                Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white70))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white))),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 10,
      color: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSemesterBlock(SemesterResult sem) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 24.0),
      borderRadius: 12,
      opacity: 0.05,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sem.semesterName,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent)),
          const Divider(color: Colors.white10),

          // Table Header
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5), // Course
              1: FlexColumnWidth(3), // Title
              2: FlexColumnWidth(0.7), // cr
              3: FlexColumnWidth(0.7), // grd
              4: FlexColumnWidth(0.8), // gp
              5: FlexColumnWidth(0.8), // gpacr
            },
            children: [
              const TableRow(children: [
                Text("Course",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
                Text("Title of the Course",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
                Text("cr",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
                Text("grd",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
                Text("gp",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
                Text("gpacr",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
              ]),

              // Spacer
              const TableRow(children: [
                SizedBox(height: 5),
                SizedBox(),
                SizedBox(),
                SizedBox(),
                SizedBox(),
                SizedBox()
              ]),

              // Rows
              ...sem.courses.map((c) => TableRow(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(c.courseCode,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(c.courseTitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white)),
                    ),
                    Text(c.credits.toStringAsFixed(1),
                        textAlign: TextAlign.right,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white)),
                    Text(c.grade,
                        textAlign: TextAlign.right,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white)),
                    Text(c.gradePoint.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white)),
                    Text(c.totalPoints.toStringAsFixed(1),
                        textAlign: TextAlign.right,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white)),
                  ])),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10),

          // Semester Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("CGPA: ${sem.cumulativeGPA.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.greenAccent)),
                  Text("Term GPA: ${sem.termGPA.toStringAsFixed(2)}",
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        color: Colors.cyanAccent.withValues(alpha: 0.1),
        borderColor: Colors.cyanAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Summary:   CGPA: ${_profile?.cgpa.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white)),
            Text(
                "Credit Earned: ${_profile?.totalCreditsEarned.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
