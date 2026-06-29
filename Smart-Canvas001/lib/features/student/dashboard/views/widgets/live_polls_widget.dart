import 'package:flutter/material.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:line_icons/line_icons.dart';

class LivePollsWidget extends StatefulWidget {
  const LivePollsWidget({super.key});

  @override
  State<LivePollsWidget> createState() => _LivePollsWidgetState();
}

class _LivePollsWidgetState extends State<LivePollsWidget> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activePolls = [];
  bool _isLoading = true;
  Set<String> _votedPollIds = {};

  @override
  void initState() {
    super.initState();
    _fetchPolls();
  }

  Future<void> _fetchPolls() async {
    setState(() => _isLoading = true);
    try {
      final user = getIt<CacheHelper>().getUserModel();
      if (user == null) return;

      // Fetch polls that target this student's college/program/year AND are not expired
      final pollsRes = await _supabase
          .from('polls')
          .select('*, poll_votes(user_id, option_index)')
          .eq('college_id', user.collegeId as Object)
          .eq('academic_year_id', user.academicYearId as Object)
          .eq('year_level', user.yearLevel as Object)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      // Check which polls the student has already voted on
      final votedRes = await _supabase
          .from('poll_votes')
          .select('poll_id')
          .eq('user_id', user.id);
      
      final votedIds = List<String>.from(votedRes.map((v) => v['poll_id'].toString()));

      setState(() {
        _activePolls = List<Map<String, dynamic>>.from(pollsRes);
        _votedPollIds = votedIds.toSet();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching student polls: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _vote(String pollId, int optionIndex) async {
    try {
      final user = getIt<CacheHelper>().getUserModel();
      await _supabase.from('poll_votes').insert({
        'poll_id': pollId,
        'user_id': user!.id,
        'option_index': optionIndex,
      });
      
      // Refresh to show results
      _fetchPolls();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vote submitted!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error voting: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Voting failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox();
    if (_activePolls.isEmpty) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12),
          child: Row(
            children: [
              const Icon(LineIcons.poll, color: AppColors.kPrimaryColor, size: 28),
              const SizedBox(width: 10),
              Text(
                "Live Polls",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E1B15),
                ),
              ),
            ],
          ),
        ),
        ..._activePolls.map((poll) => _buildPollCard(poll, isDark)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPollCard(Map<String, dynamic> poll, bool isDark) {
    final pollId = poll['id'].toString();
    final hasVoted = _votedPollIds.contains(pollId);
    final List<dynamic> options = poll['options'];
    final List<dynamic> votes = poll['poll_votes'] ?? [];
    final totalVotes = votes.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll['question'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...List.generate(options.length, (index) {
            final optionVotes = votes.where((v) => v['option_index'] == index).length;
            final percentage = totalVotes == 0 ? 0.0 : (optionVotes / totalVotes);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: hasVoted ? null : () => _vote(pollId, index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
                    border: Border.all(
                      color: AppColors.kPrimaryColor.withValues(alpha: hasVoted ? 0.3 : 0.1),
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (hasVoted)
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              options[index],
                              style: TextStyle(
                                fontWeight: hasVoted ? FontWeight.bold : FontWeight.normal,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            if (hasVoted)
                              Text(
                                "${(percentage * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.kPrimaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (hasVoted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Total Votes: $totalVotes",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
