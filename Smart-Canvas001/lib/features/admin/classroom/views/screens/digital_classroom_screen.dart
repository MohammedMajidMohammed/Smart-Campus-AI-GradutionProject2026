import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_canvas/core/components/custom_elevated_button.dart';
import 'package:smart_canvas/core/components/custom_text_form_field.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';

class DigitalClassroomScreen extends StatefulWidget {
  const DigitalClassroomScreen({super.key});

  @override
  State<DigitalClassroomScreen> createState() => _DigitalClassroomScreenState();
}

class _DigitalClassroomScreenState extends State<DigitalClassroomScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionsControllers = [TextEditingController(), TextEditingController()];
  
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _colleges = [];
  List<Map<String, dynamic>> _programs = []; 
  List<Map<String, dynamic>> _activePolls = [];
  
  String? _selectedCollegeId;
  String? _selectedProgramId; 
  String? _selectedAcademicYearId;
  int _selectedDurationHours = 24;
  String? _editingPollId;
  bool _isLoading = false;

  File? _selectedFile;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTargetingData();
    _fetchActivePolls();
  }

  Future<void> _fetchTargetingData() async {
    setState(() => _isLoading = true);
    try {
      final collegesRes = await _supabase.from('colleges').select('id, name, duration_years');
      final academicYearsRes = await _supabase.from('academic_years').select('id, name, college_id');
      
      setState(() {
        _colleges = List<Map<String, dynamic>>.from(collegesRes);
        _programs = List<Map<String, dynamic>>.from(academicYearsRes);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching targeting data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchActivePolls() async {
    try {
      final pollsRes = await _supabase
          .from('polls')
          .select('*, poll_votes(option_index)')
          .order('created_at', ascending: false);
      
      setState(() {
        _activePolls = List<Map<String, dynamic>>.from(pollsRes);
      });
    } catch (e) {
      debugPrint("Error fetching polls: $e");
    }
  }

  Future<void> _deletePoll(String pollId) async {
    try {
      await _supabase.from('polls').delete().eq('id', pollId);
      _fetchActivePolls();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Poll deleted successfully")));
      }
    } catch (e) {
      debugPrint("Error deleting poll: $e");
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _addOption() {
    setState(() {
      _optionsControllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text("Digital Classroom", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.kPrimaryColor),
        titleTextStyle: const TextStyle(color: AppColors.kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.kPrimaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.kPrimaryColor,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "Live Polls", icon: Icon(LineIcons.poll)),
            Tab(text: "Assignments", icon: Icon(LineIcons.tasks)),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [const Color(0xFF0F0E0A), const Color(0xFF1E1B15)]
                : [const Color(0xFFFAF9F5), Colors.white],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPollsTab(isDark),
                    _buildAssignmentsTab(isDark),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPollsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPremiumContainer(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderIcon(LineIcons.poll, _editingPollId == null ? "Create New Poll" : "Edit Active Poll"),
                const SizedBox(height: 25),
                _buildSectionTitle("QUESTION", isDark),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: _questionController,
                  hintText: "What's on your mind?",
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                ),
                const SizedBox(height: 25),
                _buildSectionTitle("OPTIONS", isDark),
                const SizedBox(height: 10),
                ...List.generate(_optionsControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            controller: _optionsControllers[index],
                            hintText: "Option ${index + 1}",
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                          ),
                        ),
                        if (index > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => _optionsControllers.removeAt(index));
                            },
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text("Add Option", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.kPrimaryColor),
                ),
                const Divider(height: 40),
                _buildSectionTitle("DURATION", isDark),
                const SizedBox(height: 10),
                _buildDropdown(
                  hint: "Select Duration",
                  value: _selectedDurationHours.toString(),
                  items: [
                    {'id': '1', 'name': '1 Hour'},
                    {'id': '6', 'name': '6 Hours'},
                    {'id': '12', 'name': '12 Hours'},
                    {'id': '24', 'name': '24 Hours (1 Day)'},
                    {'id': '48', 'name': '48 Hours (2 Days)'},
                    {'id': '168', 'name': '1 Week'},
                  ],
                  onChanged: (val) => setState(() => _selectedDurationHours = int.parse(val!)),
                  isDark: isDark,
                ),
                const SizedBox(height: 25),
                _buildTargetingSection(isDark),
                const SizedBox(height: 35),
                _buildActionButton(_editingPollId == null ? "Broadcast Poll" : "Update Poll", _editingPollId == null ? LineIcons.broadcastTower : LineIcons.edit, () async {
                  if (_questionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a question")));
                    return;
                  }
                  if (_selectedCollegeId == null || _selectedProgramId == null || _selectedAcademicYearId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Targeting missing: Select College, Program, and Year")));
                    return;
                  }

                  final options = _optionsControllers
                      .map((c) => c.text)
                      .where((text) => text.isNotEmpty)
                      .toList();

                  if (options.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("At least 2 options required")));
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    final user = _supabase.auth.currentUser;
                    if (user == null) throw "Authentication Error: No user logged in.";

                    final expiresAt = DateTime.now().add(Duration(hours: _selectedDurationHours)).toIso8601String();

                    final data = {
                      'question': _questionController.text,
                      'options': options,
                      'college_id': _selectedCollegeId,
                      'academic_year_id': _selectedProgramId,
                      'year_level': int.tryParse(_selectedAcademicYearId!),
                      'created_by': user.id,
                      'expires_at': expiresAt,
                    };

                    if (_editingPollId == null) {
                      await _supabase.from('polls').insert(data);
                    } else {
                      await _supabase.from('polls').update(data).eq('id', _editingPollId!);
                    }

                    await _fetchActivePolls();

                    await EnhancedNotificationService().showNotification(
                      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                      title: _editingPollId == null ? "Poll Sent! 📊" : "Poll Updated! 📝",
                      body: _questionController.text,
                      type: NotificationType.announcement,
                    );

                    if (mounted) {
                      final isNew = _editingPollId == null;
                      _questionController.clear();
                      for (var controller in _optionsControllers) { controller.clear(); }
                      setState(() { _editingPollId = null; });
                      
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
                          content: Text(isNew ? "Success! Poll is now live." : "Success! Poll has been updated."),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Awesome"))],
                        )
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Database Error"),
                          content: Text("Failed to save poll. Make sure the 'expires_at' column exists in your database.\n\nError: $e"),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
                        )
                      );
                    }
                  } finally {
                    setState(() => _isLoading = false);
                  }
                }),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildSectionTitle("ACTIVE POLLS & RESULTS", isDark),
          const SizedBox(height: 15),
          _activePolls.isEmpty 
              ? Center(child: Text("No active polls yet", style: TextStyle(color: Colors.grey.withValues(alpha: 0.5))))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activePolls.length,
                  itemBuilder: (context, index) {
                    final poll = _activePolls[index];
                    final List<dynamic> options = poll['options'];
                    final List<dynamic> votes = poll['poll_votes'] ?? [];
                    final totalVotes = votes.length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(poll['question'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E8449), size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _editingPollId = poll['id'].toString();
                                        _questionController.text = poll['question'];
                                        _selectedCollegeId = poll['college_id'].toString();
                                        _selectedProgramId = poll['academic_year_id'].toString();
                                        _selectedAcademicYearId = poll['year_level'].toString();
                                        
                                        final List<dynamic> pOpts = poll['options'];
                                        _optionsControllers.clear();
                                        for (var opt in pOpts) {
                                          _optionsControllers.add(TextEditingController(text: opt.toString()));
                                        }
                                        _tabController.animateTo(0);
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deletePoll(poll['id']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          ...List.generate(options.length, (optIndex) {
                            final oVotes = votes.where((v) => v['option_index'] == optIndex).length;
                            final pct = totalVotes == 0 ? 0.0 : (oVotes / totalVotes);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(options[optIndex], style: const TextStyle(fontSize: 13)),
                                    Text("${(pct * 100).toStringAsFixed(1)}% ($oVotes)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.kPrimaryColor.withValues(alpha: 0.7)),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          }),
                          const SizedBox(height: 5),
                          Text("Total Votes: $totalVotes", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Column(
        children: [
          _buildPremiumContainer(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderIcon(LineIcons.upload, "Broadcast Assignment"),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Icon(_selectedFile == null ? LineIcons.fileContract : LineIcons.fileAlt, 
                           size: 60, color: AppColors.kPrimaryColor),
                      const SizedBox(height: 20),
                      Text(
                        _selectedFileName ?? "Upload Materials",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile == null ? "PDF or Word documents only." : "File selected successfully.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 25),
                      CustomElevatedButton(
                        name: _selectedFile == null ? "Select File" : "Change File",
                        onPressed: _pickFile,
                        backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                        forgroundColor: isDark ? Colors.white : Colors.black,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 50),
                _buildTargetingSection(isDark),
                const SizedBox(height: 35),
                _buildActionButton("Send to Students", LineIcons.paperPlane, () async {
                  if (_selectedFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a file first")));
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    final userId = _supabase.auth.currentUser!.id;
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final fileExt = _selectedFileName!.split('.').last;
                    final fileName = '$userId/assignments/$timestamp.$fileExt';
                    final bytes = await _selectedFile!.readAsBytes();
                    
                    await _supabase.storage.from('materials').uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
                    final fileUrl = _supabase.storage.from('materials').getPublicUrl(fileName);

                    await _supabase.from('broadcast_assignments').insert({
                      'title': _selectedFileName,
                      'file_url': fileUrl,
                      'college_id': _selectedCollegeId,
                      'academic_year_id': _selectedProgramId,
                      'year_level': _selectedAcademicYearId != null ? int.parse(_selectedAcademicYearId!) : null,
                      'created_by': userId,
                    });

                    await EnhancedNotificationService().showNotification(
                      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                      title: "New Assignment 📚",
                      body: "New material: $_selectedFileName",
                      type: NotificationType.material,
                    );

                    if (mounted) {
                      setState(() { _selectedFile = null; _selectedFileName = null; });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Assignment sent!"), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red)); }
                  } finally {
                    setState(() => _isLoading = false);
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetingSection(bool isDark) {
    final filtered = _selectedCollegeId == null ? <Map<String, dynamic>>[] : _programs.where((p) => p['college_id'].toString() == _selectedCollegeId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("TARGET AUDIENCE", isDark),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildDropdown(hint: "Select College", value: _selectedCollegeId, items: _colleges, onChanged: (val) { setState(() { _selectedCollegeId = val; _selectedProgramId = null; _selectedAcademicYearId = null; }); }, isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown(hint: "Select Program", value: _selectedProgramId, items: filtered, onChanged: (val) => setState(() => _selectedProgramId = val), isDark: isDark)),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          hint: "Select Year",
          value: _selectedAcademicYearId,
          items: List.generate(
            _selectedCollegeId == null ? 5 : (_colleges.firstWhere((c) => c['id'].toString() == _selectedCollegeId)['duration_years'] ?? 5), 
            (i) => {'id': (i + 1).toString(), 'name': "Year ${i + 1}"}
          ),
          onChanged: (val) => setState(() => _selectedAcademicYearId = val),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildDropdown({required String hint, required String? value, required List<Map<String, dynamic>> items, required Function(String?) onChanged, required bool isDark}) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      hint: Text(hint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      items: items.map((item) => DropdownMenuItem<String>(value: item['id'].toString(), child: Text(item['name'].toString(), style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPremiumContainer({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: child,
    );
  }

  Widget _buildHeaderIcon(IconData icon, String title) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.kPrimaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.kPrimaryColor, size: 22)),
      const SizedBox(width: 15),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
    ]);
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey.shade500, letterSpacing: 1.5));
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: AppColors.kPrimaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
      ),
    );
  }
}
