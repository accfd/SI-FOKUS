import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/user_model.dart';
import '../../bloc/gamification/gamification_bloc.dart';
import '../../bloc/gamification/gamification_event.dart';
import '../../bloc/gamification/gamification_state.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<GamificationBloc>().add(const LoadLeaderboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text(
          'Leaderboard Kelas',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<GamificationBloc, GamificationState>(
        builder: (context, state) {
          if (state is GamificationLoading || state is GamificationInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GamificationError) {
            return Center(
              child: Text(
                state.message,
                style: GoogleFonts.outfit(color: Colors.red),
              ),
            );
          }
          if (state is LeaderboardLoaded) {
            return _buildLeaderboardContent(state.topStudents);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLeaderboardContent(List<UserModel> users) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          'Belum ada data skor.',
          style: GoogleFonts.outfit(fontSize: 16),
        ),
      );
    }

    // Split Top 3 and others
    final top3 = users.take(3).toList();
    final others = users.length > 3 ? users.sublist(3) : <UserModel>[];

    return Column(
      children: [
        // Podium Area
        Container(
          padding: const EdgeInsets.only(top: 32, bottom: 24, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.indigo.shade900,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (top3.length > 1) _buildPodium(top3[1], 2, 120, Colors.grey.shade300),
              if (top3.isNotEmpty) _buildPodium(top3[0], 1, 160, Colors.amber),
              if (top3.length > 2) _buildPodium(top3[2], 3, 100, Colors.brown.shade300),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Daftar Peringkat 4 ke atas
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: others.length,
            itemBuilder: (context, index) {
              final student = others[index];
              final rank = index + 4;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                  ),
                  title: Text(
                    student.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Level ${student.level} • ${student.unlockedBadges.length} Badges',
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${student.xp}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                      Text(
                        'XP',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.indigo.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(UserModel student, int rank, double height, Color color) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: rank == 1 ? 35 : 28,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: rank == 1 ? 32 : 25,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(Icons.person, color: color, size: rank == 1 ? 40 : 30),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            student.name.split(' ').first,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: rank == 1 ? 16 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${student.xp} XP',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$rank',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
