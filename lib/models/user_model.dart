class UserModel {
  // Core identity
  final String id;
  final String username;
  final String email;
  final String? profilePicture;
  final String? bio;
  final int? age;
  final String? country;
  final String? location;
  final String? realName;
  final String? inGameName;
  final String? primaryGame;
  final String? inGameRole;
  final List<String>? languages;

  // Status / meta
  final int? aegisRating;
  final String? teamStatus;
  final String? profileVisibility;
  final String? cardTheme;
  final int? coins;
  final Statistics? statistics;
  final DateTime? createdAt;

  // Socials
  final String? discordTag;
  final String? twitch;
  final String? youtube;
  final String? twitter;

  // Team reference
  final Team? team;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profilePicture,
    this.bio,
    this.age,
    this.country,
    this.location,
    this.realName,
    this.inGameName,
    this.primaryGame,
    this.inGameRole,
    this.languages,
    this.aegisRating,
    this.teamStatus,
    this.profileVisibility,
    this.cardTheme,
    this.coins,
    this.statistics,
    this.createdAt,
    this.discordTag,
    this.twitch,
    this.youtube,
    this.twitter,
    this.team,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'],
      bio: json['bio'],
      age: json['age'],
      country: json['country'],
      location: json['location'],
      realName: json['realName'],
      inGameName: json['inGameName'],
      primaryGame: json['primaryGame'],
      inGameRole: json['inGameRole'],
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
      aegisRating: json['aegisRating'],
      teamStatus: json['teamStatus'],
      profileVisibility: json['profileVisibility'],
      cardTheme: json['cardTheme'],
      coins: json['coins'],
      statistics: json['statistics'] != null
          ? Statistics.fromJson(json['statistics'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      discordTag: json['discordTag'],
      twitch: json['twitch'],
      youtube: json['youtube'],
      twitter: json['twitter'],
      team: json['team'] != null ? Team.fromJson(json['team']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'profilePicture': profilePicture,
      'bio': bio,
      'age': age,
      'country': country,
      'location': location,
      'realName': realName,
      'inGameName': inGameName,
      'primaryGame': primaryGame,
      'inGameRole': inGameRole,
      'languages': languages,
      'aegisRating': aegisRating,
      'teamStatus': teamStatus,
      'profileVisibility': profileVisibility,
      'cardTheme': cardTheme,
      'coins': coins,
      'statistics': statistics?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'discordTag': discordTag,
      'twitch': twitch,
      'youtube': youtube,
      'twitter': twitter,
      'team': team?.toJson(),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? profilePicture,
    String? bio,
    int? age,
    String? country,
    String? location,
    String? realName,
    String? inGameName,
    String? primaryGame,
    String? inGameRole,
    List<String>? languages,
    int? aegisRating,
    String? teamStatus,
    String? profileVisibility,
    String? cardTheme,
    int? coins,
    Statistics? statistics,
    DateTime? createdAt,
    String? discordTag,
    String? twitch,
    String? youtube,
    String? twitter,
    Team? team,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      country: country ?? this.country,
      location: location ?? this.location,
      realName: realName ?? this.realName,
      inGameName: inGameName ?? this.inGameName,
      primaryGame: primaryGame ?? this.primaryGame,
      inGameRole: inGameRole ?? this.inGameRole,
      languages: languages ?? this.languages,
      aegisRating: aegisRating ?? this.aegisRating,
      teamStatus: teamStatus ?? this.teamStatus,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      cardTheme: cardTheme ?? this.cardTheme,
      coins: coins ?? this.coins,
      statistics: statistics ?? this.statistics,
      createdAt: createdAt ?? this.createdAt,
      discordTag: discordTag ?? this.discordTag,
      twitch: twitch ?? this.twitch,
      youtube: youtube ?? this.youtube,
      twitter: twitter ?? this.twitter,
      team: team ?? this.team,
    );
  }
}

class Statistics {
  final int? matchesPlayed;
  final int? wins;
  final int? losses;
  final double? kdRatio;
  final int? totalKills;
  final int? totalDeaths;
  final double? winRate;

  Statistics({
    this.matchesPlayed,
    this.wins,
    this.losses,
    this.kdRatio,
    this.totalKills,
    this.totalDeaths,
    this.winRate,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      matchesPlayed: json['matchesPlayed'],
      wins: json['wins'],
      losses: json['losses'],
      kdRatio: json['kdRatio']?.toDouble(),
      totalKills: json['totalKills'],
      totalDeaths: json['totalDeaths'],
      winRate: json['winRate']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
      'kdRatio': kdRatio,
      'totalKills': totalKills,
      'totalDeaths': totalDeaths,
      'winRate': winRate,
    };
  }
}

class Team {
  final String id;
  final String teamName;
  final String? teamTag;
  final String? logo;
  final String? primaryGame;
  final String? region;
  final String? bio;
  final String? status;
  final String? profileVisibility;
  final int? aegisRating;
  final double? totalEarnings;
  final bool? lookingForPlayers;
  final List<String>? openRoles;
  final DateTime? establishedDate;
  final Statistics? statistics;
  final double? winRatePercentage;
  final double? averageKillsPerMatch;
  final int? memberCount;
  final Captain? captain;

  Team({
    required this.id,
    required this.teamName,
    this.teamTag,
    this.logo,
    this.primaryGame,
    this.region,
    this.bio,
    this.status,
    this.profileVisibility,
    this.aegisRating,
    this.totalEarnings,
    this.lookingForPlayers,
    this.openRoles,
    this.establishedDate,
    this.statistics,
    this.winRatePercentage,
    this.averageKillsPerMatch,
    this.memberCount,
    this.captain,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['_id'] ?? json['id'] ?? '',
      teamName: json['teamName'] ?? '',
      teamTag: json['teamTag'],
      logo: json['logo'],
      primaryGame: json['primaryGame'],
      region: json['region'],
      bio: json['bio'],
      status: json['status'],
      profileVisibility: json['profileVisibility'],
      aegisRating: json['aegisRating'],
      totalEarnings: json['totalEarnings']?.toDouble(),
      lookingForPlayers: json['lookingForPlayers'],
      openRoles: json['openRoles'] != null
          ? List<String>.from(json['openRoles'])
          : null,
      establishedDate: json['establishedDate'] != null
          ? DateTime.parse(json['establishedDate'])
          : null,
      statistics: json['statistics'] != null
          ? Statistics.fromJson(json['statistics'])
          : null,
      winRatePercentage: json['winRatePercentage']?.toDouble(),
      averageKillsPerMatch: json['averageKillsPerMatch']?.toDouble(),
      memberCount: json['memberCount'],
      captain: json['captain'] != null
          ? Captain.fromJson(json['captain'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'teamName': teamName,
      'teamTag': teamTag,
      'logo': logo,
      'primaryGame': primaryGame,
      'region': region,
      'bio': bio,
      'status': status,
      'profileVisibility': profileVisibility,
      'aegisRating': aegisRating,
      'totalEarnings': totalEarnings,
      'lookingForPlayers': lookingForPlayers,
      'openRoles': openRoles,
      'establishedDate': establishedDate?.toIso8601String(),
      'statistics': statistics?.toJson(),
      'winRatePercentage': winRatePercentage,
      'averageKillsPerMatch': averageKillsPerMatch,
      'memberCount': memberCount,
      'captain': captain?.toJson(),
    };
  }
}

class Captain {
  final String id;
  final String username;
  final String? profilePicture;
  final String? primaryGame;
  final int? aegisRating;
  final String? inGameName;

  Captain({
    required this.id,
    required this.username,
    this.profilePicture,
    this.primaryGame,
    this.aegisRating,
    this.inGameName,
  });

  factory Captain.fromJson(Map<String, dynamic> json) {
    return Captain(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      profilePicture: json['profilePicture'],
      primaryGame: json['primaryGame'],
      aegisRating: json['aegisRating'],
      inGameName: json['inGameName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'profilePicture': profilePicture,
      'primaryGame': primaryGame,
      'aegisRating': aegisRating,
      'inGameName': inGameName,
    };
  }
}

