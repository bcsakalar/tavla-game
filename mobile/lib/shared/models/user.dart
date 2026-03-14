import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final int eloRating;
  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final int totalGammons;
  final int totalBackgammons;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.eloRating = 1200,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalDraws = 0,
    this.totalGammons = 0,
    this.totalBackgammons = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      email: json['email'],
      avatarUrl: json['avatar_url'],
      eloRating: json['elo_rating'] ?? 1200,
      totalWins: json['total_wins'] ?? 0,
      totalLosses: json['total_losses'] ?? 0,
      totalDraws: json['total_draws'] ?? 0,
      totalGammons: json['total_gammons'] ?? 0,
      totalBackgammons: json['total_backgammons'] ?? 0,
    );
  }

  int get totalGamesPlayed => totalWins + totalLosses + totalDraws;

  double get winRate =>
      totalGamesPlayed > 0 ? (totalWins / totalGamesPlayed) * 100 : 0;

  String get ratingTier {
    if (eloRating >= 2200) return 'Grandmaster';
    if (eloRating >= 2000) return 'Master';
    if (eloRating >= 1800) return 'Expert';
    if (eloRating >= 1600) return 'Advanced';
    if (eloRating >= 1400) return 'Intermediate';
    if (eloRating >= 1200) return 'Beginner';
    return 'Novice';
  }

  @override
  List<Object?> get props => [id, username, eloRating];
}
