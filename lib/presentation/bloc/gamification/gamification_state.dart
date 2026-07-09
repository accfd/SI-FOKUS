import 'package:equatable/equatable.dart';
import '../../../../data/models/user_model.dart';

abstract class GamificationState extends Equatable {
  const GamificationState();

  @override
  List<Object?> get props => [];
}

class GamificationInitial extends GamificationState {}

class GamificationLoading extends GamificationState {}

class LeaderboardLoaded extends GamificationState {
  final List<UserModel> topStudents;

  const LeaderboardLoaded(this.topStudents);

  @override
  List<Object?> get props => [topStudents];
}

class GamificationAchieved extends GamificationState {
  final int xpGained;
  final int? newLevel;
  final List<String> newBadges;

  const GamificationAchieved({
    required this.xpGained,
    this.newLevel,
    this.newBadges = const [],
  });

  @override
  List<Object?> get props => [xpGained, newLevel, newBadges];
}

class GamificationError extends GamificationState {
  final String message;

  const GamificationError(this.message);

  @override
  List<Object?> get props => [message];
}
