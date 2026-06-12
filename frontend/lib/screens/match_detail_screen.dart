import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

String? getIplLogoAsset(String teamName) {
  final name = teamName.toLowerCase().trim();
  if (name.contains("chennai") || name.contains("super kings") || name.contains("csk")) {
    return "assets/logos/csk logo.png";
  } else if (name.contains("mumbai") || name == "mi" || name.contains("mumbai indians")) {
    return "assets/logos/MI logo.jpg";
  } else if (name.contains("royal challengers") || name.contains("rcb") || name.contains("bengaluru") || name.contains("bangalore")) {
    return "assets/logos/RCB logo.jpg";
  } else if (name.contains("kolkata") || name.contains("knight riders") || name.contains("kkr")) {
    return "assets/logos/kkr logo.jpg";
  } else if (name.contains("rajasthan") || name == "rr" || name.contains("rajasthan royals")) {
    return "assets/logos/Rajasthan royal.jpg";
  } else if (name.contains("delhi") || name == "dc" || name.contains("delhi capitals")) {
    return "assets/logos/delhi capitals logo.png";
  } else if (name.contains("punjab") || name.contains("kings xi") || name == "pbks" || name.contains("punjab kings")) {
    return "assets/logos/Punjab kings logo.jpg";
  } else if (name.contains("sunrisers") || name.contains("hyderabad") || name == "srh") {
    return "assets/logos/sunrisers hyderabad logo.png";
  } else if (name.contains("gujarat") || name == "gt" || name.contains("gujarat titans")) {
    return "assets/logos/GT logo.png";
  } else if (name.contains("lucknow") || name.contains("super giants") || name == "lsg") {
    return "assets/logos/LSG logo.jpg";
  }
  return null;
}

String? getKabaddiLogoAsset(String teamName) {
  final name = teamName.toLowerCase().trim();
  if (name.contains("patna") || name.contains("pirates") || name == "pat") {
    return "assets/logos/patna_pirates.png";
  } else if (name.contains("mumba") || name == "mum") {
    return "assets/logos/u_mumba.png";
  } else if (name.contains("jaipur") || name.contains("panthers") || name == "jai") {
    return "assets/logos/jaipur_pink_panthers.png";
  } else if (name.contains("bengaluru") || name.contains("bulls") || name == "blr") {
    return "assets/logos/bengaluru_bulls.png";
  } else if (name.contains("delhi") || name.contains("dabang") || name == "del") {
    return "assets/logos/dabang_delhi.png";
  } else if (name.contains("puneri") || name.contains("paltan") || name == "pun") {
    return "assets/logos/puneri_paltan.png";
  }
  return null;
}

class PlayerInfo {
  final String name;
  final String role;
  final String number;
  final String nationality;
  final String stats;
  /// Cricbuzz player ID used to load the face photo via the backend proxy.
  final String? imageId;

  const PlayerInfo({
    required this.name,
    required this.role,
    required this.number,
    required this.nationality,
    required this.stats,
    this.imageId,
  });
}

class MatchDetailScreen extends StatefulWidget {
  final String homeTeam;
  final String awayTeam;
  final String? homeLogoUrl;
  final String? awayLogoUrl;
  final String statusText;
  final String scoreText;
  final bool isLive;
  final String venue;
  final bool isCricket;
  final bool isKabaddi;
  final String? matchId;

  const MatchDetailScreen({
    super.key,
    this.homeTeam = 'MUMBAI',
    this.awayTeam = 'CHENNAI',
    this.homeLogoUrl,
    this.awayLogoUrl,
    this.statusText = '● LIVE - 2nd Half',
    this.scoreText = '2 - 1',
    this.isLive = true,
    this.venue = 'Wankhede Stadium',
    this.isCricket = false,
    this.isKabaddi = false,
    this.matchId,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  bool _isLoadingScorecard = false;
  Map<String, List<PlayerInfo>> _apiSquads = {};
  Map<String, List<PlayerInfo>> _apiPlayingXIs = {};
  Map<String, List<PlayerInfo>> _apiBenches = {};
  Map<String, dynamic>? _liveState;
  int _activeTab = 0;
  int _selectedLineupTeamIndex = 0;

  static const Map<String, List<PlayerInfo>> _teamSquads = {
    'arsenal': [
      PlayerInfo(name: 'David Raya', role: 'GK', number: '1', nationality: 'Spain', stats: 'Clean sheets: 16'),
      PlayerInfo(name: 'Ben White', role: 'DF', number: '4', nationality: 'England', stats: 'Goals: 4, Assists: 4'),
      PlayerInfo(name: 'William Saliba', role: 'DF', number: '2', nationality: 'France', stats: 'Interceptions: 45'),
      PlayerInfo(name: 'Gabriel Magalhães', role: 'DF', number: '6', nationality: 'Brazil', stats: 'Goals: 3'),
      PlayerInfo(name: 'Oleksandr Zinchenko', role: 'DF', number: '35', nationality: 'Ukraine', stats: 'Pass Accuracy: 89%'),
      PlayerInfo(name: 'Declan Rice', role: 'MF', number: '41', nationality: 'England', stats: 'Goals: 7, Assists: 8'),
      PlayerInfo(name: 'Martin Ødegaard', role: 'MF', number: '8', nationality: 'Norway', stats: 'Goals: 8, Assists: 10'),
      PlayerInfo(name: 'Kai Havertz', role: 'MF', number: '29', nationality: 'Germany', stats: 'Goals: 13, Assists: 7'),
      PlayerInfo(name: 'Bukayo Saka', role: 'FW', number: '7', nationality: 'England', stats: 'Goals: 16, Assists: 9'),
      PlayerInfo(name: 'Gabriel Martinelli', role: 'FW', number: '11', nationality: 'Brazil', stats: 'Goals: 6, Assists: 4'),
      PlayerInfo(name: 'Leandro Trossard', role: 'FW', number: '19', nationality: 'Belgium', stats: 'Goals: 12, Assists: 1'),
      PlayerInfo(name: 'Aaron Ramsdale', role: 'GK', number: '32', nationality: 'England', stats: 'DNP'),
      PlayerInfo(name: 'Gabriel Jesus', role: 'FW', number: '9', nationality: 'Brazil', stats: 'DNP'),
      PlayerInfo(name: 'Thomas Partey', role: 'MF', number: '5', nationality: 'Ghana', stats: 'DNP'),
      PlayerInfo(name: 'Jorginho', role: 'MF', number: '20', nationality: 'Italy', stats: 'DNP'),
    ],
    'real madrid': [
      PlayerInfo(name: 'Thibaut Courtois', role: 'GK', number: '1', nationality: 'Belgium', stats: 'Saves: 78'),
      PlayerInfo(name: 'Dani Carvajal', role: 'DF', number: '2', nationality: 'Spain', stats: 'Goals: 6, Assists: 5'),
      PlayerInfo(name: 'Antonio Rüdiger', role: 'DF', number: '22', nationality: 'Germany', stats: 'Tackles: 38'),
      PlayerInfo(name: 'Éder Militão', role: 'DF', number: '3', nationality: 'Brazil', stats: 'Clearances: 52'),
      PlayerInfo(name: 'Ferland Mendy', role: 'DF', number: '23', nationality: 'France', stats: 'Interceptions: 34'),
      PlayerInfo(name: 'Aurelien Tchouaméni', role: 'MF', number: '18', nationality: 'France', stats: 'Pass Accuracy: 92%'),
      PlayerInfo(name: 'Federico Valverde', role: 'MF', number: '15', nationality: 'Uruguay', stats: 'Goals: 3, Assists: 7'),
      PlayerInfo(name: 'Jude Bellingham', role: 'MF', number: '5', nationality: 'England', stats: 'Goals: 19, Assists: 6'),
      PlayerInfo(name: 'Rodrygo Goes', role: 'FW', number: '11', nationality: 'Brazil', stats: 'Goals: 10, Assists: 5'),
      PlayerInfo(name: 'Vinícius Júnior', role: 'FW', number: '7', nationality: 'Brazil', stats: 'Goals: 15, Assists: 5'),
      PlayerInfo(name: 'Kylian Mbappé', role: 'FW', number: '9', nationality: 'France', stats: 'Goals: 28, Assists: 7'),
      PlayerInfo(name: 'Andriy Lunin', role: 'GK', number: '13', nationality: 'Ukraine', stats: 'DNP'),
      PlayerInfo(name: 'Luka Modrić', role: 'MF', number: '10', nationality: 'Croatia', stats: 'DNP'),
      PlayerInfo(name: 'Brahim Díaz', role: 'FW', number: '21', nationality: 'Morocco', stats: 'DNP'),
      PlayerInfo(name: 'Fran García', role: 'DF', number: '20', nationality: 'Spain', stats: 'DNP'),
    ],
    'bayern münchen': [
      PlayerInfo(name: 'Manuel Neuer', role: 'GK', number: '1', nationality: 'Germany', stats: 'Saves: 65'),
      PlayerInfo(name: 'Joshua Kimmich', role: 'DF', number: '6', nationality: 'Germany', stats: 'Pass Accuracy: 91%'),
      PlayerInfo(name: 'Dayot Upamecano', role: 'DF', number: '2', nationality: 'France', stats: 'Tackles: 42'),
      PlayerInfo(name: 'Kim Min-jae', role: 'DF', number: '3', nationality: 'South Korea', stats: 'Clearances: 64'),
      PlayerInfo(name: 'Alphonso Davies', role: 'DF', number: '19', nationality: 'Canada', stats: 'Assists: 5'),
      PlayerInfo(name: 'Leon Goretzka', role: 'MF', number: '8', nationality: 'Germany', stats: 'Goals: 6, Assists: 7'),
      PlayerInfo(name: 'Konrad Laimer', role: 'MF', number: '27', nationality: 'Austria', stats: 'Interceptions: 29'),
      PlayerInfo(name: 'Jamal Musiala', role: 'MF', number: '42', nationality: 'Germany', stats: 'Goals: 10, Assists: 6'),
      PlayerInfo(name: 'Leroy Sané', role: 'FW', number: '10', nationality: 'Germany', stats: 'Goals: 8, Assists: 11'),
      PlayerInfo(name: 'Thomas Müller', role: 'FW', number: '25', nationality: 'Germany', stats: 'Goals: 5, Assists: 9'),
      PlayerInfo(name: 'Harry Kane', role: 'FW', number: '9', nationality: 'England', stats: 'Goals: 36, Assists: 8'),
      PlayerInfo(name: 'Sven Ulreich', role: 'GK', number: '26', nationality: 'Germany', stats: 'DNP'),
      PlayerInfo(name: 'Mathijs de Ligt', role: 'DF', number: '4', nationality: 'Netherlands', stats: 'DNP'),
      PlayerInfo(name: 'Aleksandar Pavlović', role: 'MF', number: '45', nationality: 'Germany', stats: 'DNP'),
      PlayerInfo(name: 'Mathys Tel', role: 'FW', number: '39', nationality: 'France', stats: 'DNP'),
    ],
    'psg': [
      PlayerInfo(name: 'Gianluigi Donnarumma', role: 'GK', number: '99', nationality: 'Italy', stats: 'Saves: 82'),
      PlayerInfo(name: 'Achraf Hakimi', role: 'DF', number: '2', nationality: 'Morocco', stats: 'Goals: 4, Assists: 5'),
      PlayerInfo(name: 'Marquinhos', role: 'DF', number: '5', nationality: 'Brazil', stats: 'Clearances: 75'),
      PlayerInfo(name: 'Milan Škriniar', role: 'DF', number: '37', nationality: 'Slovakia', stats: 'Interceptions: 48'),
      PlayerInfo(name: 'Nuno Mendes', role: 'DF', number: '25', nationality: 'Portugal', stats: 'Crosses: 34'),
      PlayerInfo(name: 'Warren Zaïre-Emery', role: 'MF', number: '33', nationality: 'France', stats: 'Pass Accuracy: 90%'),
      PlayerInfo(name: 'Vitinha', role: 'MF', number: '17', nationality: 'Portugal', stats: 'Goals: 7, Assists: 4'),
      PlayerInfo(name: 'Fabián Ruiz', role: 'MF', number: '8', nationality: 'Spain', stats: 'Goals: 3, Assists: 5'),
      PlayerInfo(name: 'Ousmane Dembélé', role: 'FW', number: '10', nationality: 'France', stats: 'Assists: 12'),
      PlayerInfo(name: 'Bradley Barcola', role: 'FW', number: '29', nationality: 'France', stats: 'Goals: 5, Assists: 7'),
      PlayerInfo(name: 'Gonçalo Ramos', role: 'FW', number: '9', nationality: 'Portugal', stats: 'Goals: 11, Assists: 1'),
      PlayerInfo(name: 'Keylor Navas', role: 'GK', number: '1', nationality: 'Costa Rica', stats: 'DNP'),
      PlayerInfo(name: 'Lucas Beraldo', role: 'DF', number: '35', nationality: 'Brazil', stats: 'DNP'),
      PlayerInfo(name: 'Danilo Pereira', role: 'MF', number: '15', nationality: 'Portugal', stats: 'DNP'),
      PlayerInfo(name: 'Randal Kolo Muani', role: 'FW', number: '23', nationality: 'France', stats: 'DNP'),
    ],
    'athletic club': [
      PlayerInfo(name: 'Julen Agirrezabala', role: 'GK', number: '13', nationality: 'Spain', stats: 'Saves: 51'),
      PlayerInfo(name: 'Óscar de Marcos', role: 'DF', number: '18', nationality: 'Spain', stats: 'Assists: 3'),
      PlayerInfo(name: 'Dani Vivian', role: 'DF', number: '3', nationality: 'Spain', stats: 'Interceptions: 35'),
      PlayerInfo(name: 'Aitor Paredes', role: 'DF', number: '4', nationality: 'Spain', stats: 'Tackles: 28'),
      PlayerInfo(name: 'Yuri Berchiche', role: 'DF', number: '17', nationality: 'Spain', stats: 'Goals: 3'),
      PlayerInfo(name: 'Iñigo Ruiz de Galarreta', role: 'MF', number: '6', nationality: 'Spain', stats: 'Pass Accuracy: 87%'),
      PlayerInfo(name: 'Beñat Prados', role: 'MF', number: '24', nationality: 'Spain', stats: 'Tackles: 41'),
      PlayerInfo(name: 'Oihan Sancet', role: 'MF', number: '8', nationality: 'Spain', stats: 'Goals: 5, Assists: 4'),
      PlayerInfo(name: 'Iñaki Williams', role: 'FW', number: '9', nationality: 'Ghana', stats: 'Goals: 12, Assists: 8'),
      PlayerInfo(name: 'Nico Williams', role: 'FW', number: '11', nationality: 'Spain', stats: 'Goals: 8, Assists: 12'),
      PlayerInfo(name: 'Gorka Guruzeta', role: 'FW', number: '12', nationality: 'Spain', stats: 'Goals: 14, Assists: 5'),
      PlayerInfo(name: 'Unai Simón', role: 'GK', number: '1', nationality: 'Spain', stats: 'DNP'),
      PlayerInfo(name: 'Yeray Álvarez', role: 'DF', number: '5', nationality: 'Spain', stats: 'DNP'),
      PlayerInfo(name: 'Ander Herrera', role: 'MF', number: '21', nationality: 'Spain', stats: 'DNP'),
      PlayerInfo(name: 'Alex Berenguer', role: 'FW', number: '7', nationality: 'Spain', stats: 'DNP'),
    ],
    'atletico madrid': [
      PlayerInfo(name: 'Jan Oblak', role: 'GK', number: '13', nationality: 'Slovenia', stats: 'Saves: 85'),
      PlayerInfo(name: 'Nahuel Molina', role: 'DF', number: '16', nationality: 'Argentina', stats: 'Goals: 2, Assists: 3'),
      PlayerInfo(name: 'Axel Witsel', role: 'DF', number: '20', nationality: 'Belgium', stats: 'Clearances: 62'),
      PlayerInfo(name: 'Jose María Giménez', role: 'DF', number: '2', nationality: 'Uruguay', stats: 'Tackles: 31'),
      PlayerInfo(name: 'Mario Hermoso', role: 'DF', number: '22', nationality: 'Spain', stats: 'Interceptions: 40'),
      PlayerInfo(name: 'Koke', role: 'MF', number: '6', nationality: 'Spain', stats: 'Pass Accuracy: 90%'),
      PlayerInfo(name: 'Rodrigo De Paul', role: 'MF', number: '5', nationality: 'Argentina', stats: 'Goals: 3, Assists: 6'),
      PlayerInfo(name: 'Marcos Llorente', role: 'MF', number: '14', nationality: 'Spain', stats: 'Goals: 6, Assists: 5'),
      PlayerInfo(name: 'Antoine Griezmann', role: 'FW', number: '7', nationality: 'France', stats: 'Goals: 16, Assists: 6'),
      PlayerInfo(name: 'Álvaro Morata', role: 'FW', number: '19', nationality: 'Spain', stats: 'Goals: 15, Assists: 2'),
      PlayerInfo(name: 'Samuel Lino', role: 'FW', number: '12', nationality: 'Brazil', stats: 'Goals: 4, Assists: 5'),
      PlayerInfo(name: 'Horatiu Moldovan', role: 'GK', number: '1', nationality: 'Romania', stats: 'DNP'),
      PlayerInfo(name: 'Stefan Savić', role: 'DF', number: '15', nationality: 'Montenegro', stats: 'DNP'),
      PlayerInfo(name: 'Saúl Ñíguez', role: 'MF', number: '8', nationality: 'Spain', stats: 'DNP'),
      PlayerInfo(name: 'Angel Correa', role: 'FW', number: '10', nationality: 'Argentina', stats: 'DNP'),
    ],
    'mumbai indians': [
      PlayerInfo(name: 'Rohit Sharma', role: 'Batter', number: '45', nationality: 'India', stats: 'Runs: 417, Sixes: 23', imageId: '576'),
      PlayerInfo(name: 'Ishan Kishan', role: 'Wicketkeeper', number: '23', nationality: 'India', stats: 'Runs: 320, Catches: 10', imageId: '10276'),
      PlayerInfo(name: 'Suryakumar Yadav', role: 'Batter', number: '63', nationality: 'India', stats: 'Strike Rate: 168.4', imageId: '8292'),
      PlayerInfo(name: 'Tilak Varma', role: 'Batter', number: '9', nationality: 'India', stats: 'Runs: 380, Avg: 42.2', imageId: '12781'),
      PlayerInfo(name: 'Hardik Pandya', role: 'All-Rounder', number: '33', nationality: 'India', stats: 'Wickets: 11, Runs: 210', imageId: '9647'),
      PlayerInfo(name: 'Tim David', role: 'Batter', number: '85', nationality: 'Australia', stats: 'Sixes: 18, Runs: 241', imageId: '11532'),
      PlayerInfo(name: 'Romario Shepherd', role: 'All-Rounder', number: '16', nationality: 'West Indies', stats: 'Runs: 115', imageId: '11406'),
      PlayerInfo(name: 'Gerald Coetzee', role: 'Bowler', number: '62', nationality: 'South Africa', stats: 'Wickets: 13, Econ: 8.9', imageId: '13217'),
      PlayerInfo(name: 'Jasprit Bumrah', role: 'Bowler', number: '93', nationality: 'India', stats: 'Wickets: 20, Econ: 6.48', imageId: '9311'),
      PlayerInfo(name: 'Piyush Chawla', role: 'Bowler', number: '11', nationality: 'India', stats: 'Wickets: 10', imageId: '376'),
      PlayerInfo(name: 'Nuwan Thushara', role: 'Bowler', number: '54', nationality: 'Sri Lanka', stats: 'Wickets: 8', imageId: '13963'),
      PlayerInfo(name: 'Dewald Brevis', role: 'Batter', number: '18', nationality: 'South Africa', stats: 'DNP', imageId: '14005'),
      PlayerInfo(name: 'Shreyas Gopal', role: 'Bowler', number: '27', nationality: 'India', stats: 'DNP', imageId: '14006'),
      PlayerInfo(name: 'Naman Dhir', role: 'All-Rounder', number: '10', nationality: 'India', stats: 'DNP', imageId: '14007'),
      PlayerInfo(name: 'Anshul Kamboj', role: 'Bowler', number: '12', nationality: 'India', stats: 'DNP', imageId: '14008'),
    ],
    'chennai super kings': [
      PlayerInfo(name: 'Ruturaj Gaikwad', role: 'Batter', number: '31', nationality: 'India', stats: 'Runs: 583, Avg: 58.3', imageId: '11813'),
      PlayerInfo(name: 'Rachin Ravindra', role: 'Batter', number: '17', nationality: 'New Zealand', stats: 'Runs: 222', imageId: '13735'),
      PlayerInfo(name: 'Ajinkya Rahane', role: 'Batter', number: '21', nationality: 'India', stats: 'Runs: 180', imageId: '1447'),
      PlayerInfo(name: 'Shivam Dube', role: 'All-Rounder', number: '25', nationality: 'India', stats: 'Sixes: 28, Runs: 396', imageId: '11801'),
      PlayerInfo(name: 'Ravindra Jadeja', role: 'All-Rounder', number: '8', nationality: 'India', stats: 'Wickets: 8, Runs: 220', imageId: '587'),
      PlayerInfo(name: 'MS Dhoni', role: 'Wicketkeeper', number: '7', nationality: 'India', stats: 'Strike Rate: 220.5', imageId: '265'),
      PlayerInfo(name: 'Mitchell Santner', role: 'All-Rounder', number: '74', nationality: 'New Zealand', stats: 'Wickets: 4', imageId: '8683'),
      PlayerInfo(name: 'Shardul Thakur', role: 'Bowler', number: '54', nationality: 'India', stats: 'Wickets: 5', imageId: '8685'),
      PlayerInfo(name: 'Tushar Deshpande', role: 'Bowler', number: '24', nationality: 'India', stats: 'Wickets: 16, Econ: 8.4', imageId: '13670'),
      PlayerInfo(name: 'Matheesha Pathirana', role: 'Bowler', number: '99', nationality: 'Sri Lanka', stats: 'Wickets: 13, Econ: 7.6', imageId: '14705'),
      PlayerInfo(name: 'Richard Gleeson', role: 'Bowler', number: '71', nationality: 'England', stats: 'Wickets: 2', imageId: '11036'),
      PlayerInfo(name: 'Sameer Rizvi', role: 'Batter', number: '1', nationality: 'India', stats: 'DNP', imageId: '14001'),
      PlayerInfo(name: 'Prashant Solanki', role: 'Bowler', number: '3', nationality: 'India', stats: 'DNP', imageId: '14002'),
      PlayerInfo(name: 'Shaik Rasheed', role: 'Batter', number: '4', nationality: 'India', stats: 'DNP', imageId: '14003'),
      PlayerInfo(name: 'Mukesh Choudhary', role: 'Bowler', number: '5', nationality: 'India', stats: 'DNP', imageId: '14004'),
    ],
    'royal challengers bengaluru': [
      PlayerInfo(name: 'Virat Kohli', role: 'Batter', number: '18', nationality: 'India', stats: 'Runs: 741, Avg: 61.75', imageId: '1413'),
      PlayerInfo(name: 'Faf du Plessis', role: 'Batter', number: '13', nationality: 'South Africa', stats: 'Runs: 430, Sixes: 21', imageId: '370'),
      PlayerInfo(name: 'Will Jacks', role: 'All-Rounder', number: '20', nationality: 'England', stats: 'Strike Rate: 175.4, 100s: 1', imageId: '11571'),
      PlayerInfo(name: 'Rajat Patidar', role: 'Batter', number: '97', nationality: 'India', stats: 'Runs: 360, 50s: 5', imageId: '10904'),
      PlayerInfo(name: 'Glenn Maxwell', role: 'All-Rounder', number: '32', nationality: 'Australia', stats: 'Wickets: 6, Runs: 52', imageId: '1844'),
      PlayerInfo(name: 'Cameron Green', role: 'All-Rounder', number: '4', nationality: 'Australia', stats: 'Runs: 255, Wickets: 10', imageId: '11782'),
      PlayerInfo(name: 'Dinesh Karthik', role: 'Wicketkeeper', number: '19', nationality: 'India', stats: 'Strike Rate: 187.3', imageId: '145'),
      PlayerInfo(name: 'Swapnil Singh', role: 'All-Rounder', number: '86', nationality: 'India', stats: 'Wickets: 6', imageId: '9042'),
      PlayerInfo(name: 'Karn Sharma', role: 'Bowler', number: '33', nationality: 'India', stats: 'Wickets: 7', imageId: '1849'),
      PlayerInfo(name: 'Mohammed Siraj', role: 'Bowler', number: '73', nationality: 'India', stats: 'Wickets: 15, Econ: 9.1', imageId: '10808'),
      PlayerInfo(name: 'Yash Dayal', role: 'Bowler', number: '12', nationality: 'India', stats: 'Wickets: 15, Econ: 8.8', imageId: '12847'),
      PlayerInfo(name: 'Anuj Rawat', role: 'Wicketkeeper', number: '55', nationality: 'India', stats: 'DNP', imageId: '14009'),
      PlayerInfo(name: 'Mahipal Lomror', role: 'All-Rounder', number: '6', nationality: 'India', stats: 'DNP', imageId: '14010'),
      PlayerInfo(name: 'Tom Curran', role: 'All-Rounder', number: '59', nationality: 'England', stats: 'DNP', imageId: '14011'),
      PlayerInfo(name: 'Lockie Ferguson', role: 'Bowler', number: '87', nationality: 'New Zealand', stats: 'DNP', imageId: '14012'),
    ],
    'delhi capitals': [
      PlayerInfo(name: 'Jake Fraser-McGurk', role: 'Batter', number: '24', nationality: 'Australia', stats: 'Strike Rate: 234.0, Runs: 330', imageId: '15160'),
      PlayerInfo(name: 'Abishek Porel', role: 'Batter', number: '22', nationality: 'India', stats: 'Runs: 280', imageId: '14197'),
      PlayerInfo(name: 'Shai Hope', role: 'Batter', number: '4', nationality: 'West Indies', stats: 'Runs: 190', imageId: '9377'),
      PlayerInfo(name: 'Rishabh Pant', role: 'Wicketkeeper', number: '17', nationality: 'India', stats: 'Runs: 446, Sixes: 25', imageId: '10744'),
      PlayerInfo(name: 'Tristan Stubbs', role: 'Batter', number: '30', nationality: 'South Africa', stats: 'Strike Rate: 190.9', imageId: '14545'),
      PlayerInfo(name: 'Axar Patel', role: 'All-Rounder', number: '20', nationality: 'India', stats: 'Wickets: 11, Runs: 235', imageId: '8293'),
      PlayerInfo(name: 'Kuldeep Yadav', role: 'Bowler', number: '23', nationality: 'India', stats: 'Wickets: 16, Econ: 7.9', imageId: '8313'),
      PlayerInfo(name: 'Rasikh Salam', role: 'Bowler', number: '77', nationality: 'India', stats: 'Wickets: 8', imageId: '13470'),
      PlayerInfo(name: 'Mukesh Kumar', role: 'Bowler', number: '19', nationality: 'India', stats: 'Wickets: 17', imageId: '11664'),
      PlayerInfo(name: 'Anrich Nortje', role: 'Bowler', number: '20', nationality: 'South Africa', stats: 'Wickets: 7', imageId: '10869'),
      PlayerInfo(name: 'Khaleel Ahmed', role: 'Bowler', number: '90', nationality: 'India', stats: 'Wickets: 17, Econ: 9.3', imageId: '10926'),
      PlayerInfo(name: 'Lalit Yadav', role: 'All-Rounder', number: '5', nationality: 'India', stats: 'DNP', imageId: '14033'),
      PlayerInfo(name: 'Kumar Kushagra', role: 'Wicketkeeper', number: '9', nationality: 'India', stats: 'DNP', imageId: '14035'),
      PlayerInfo(name: 'Pravin Dubey', role: 'Bowler', number: '27', nationality: 'India', stats: 'DNP', imageId: '14044'),
      PlayerInfo(name: 'Jhye Richardson', role: 'Bowler', number: '12', nationality: 'Australia', stats: 'DNP', imageId: '14045'),
    ],
    'kolkata knight riders': [
      PlayerInfo(name: 'Shreyas Iyer', role: 'Batter', number: '41', nationality: 'India', stats: 'Runs: 351, Strike Rate: 146.8', imageId: '9425'),
      PlayerInfo(name: 'Phil Salt', role: 'Wicketkeeper', number: '21', nationality: 'England', stats: 'Runs: 435, SR: 182.0', imageId: '10712'),
      PlayerInfo(name: 'Sunil Narine', role: 'All-Rounder', number: '74', nationality: 'West Indies', stats: 'Runs: 488, Wickets: 15', imageId: '1985'),
      PlayerInfo(name: 'Venkatesh Iyer', role: 'Batter', number: '27', nationality: 'India', stats: 'Runs: 370, Avg: 41.1', imageId: '10917'),
      PlayerInfo(name: 'Andre Russell', role: 'All-Rounder', number: '12', nationality: 'West Indies', stats: 'Runs: 222, Wickets: 16', imageId: '7736'),
      PlayerInfo(name: 'Rinku Singh', role: 'Batter', number: '35', nationality: 'India', stats: 'Strike Rate: 148.6, Sixes: 15', imageId: '10892'),
      PlayerInfo(name: 'Ramandeep Singh', role: 'All-Rounder', number: '19', nationality: 'India', stats: 'Strike Rate: 201.6', imageId: '14562'),
      PlayerInfo(name: 'Mitchell Starc', role: 'Bowler', number: '56', nationality: 'Australia', stats: 'Wickets: 12, Econ: 9.0', imageId: '7725'),
      PlayerInfo(name: 'Harshit Rana', role: 'Bowler', number: '28', nationality: 'India', stats: 'Wickets: 17, Econ: 9.1', imageId: '15061'),
      PlayerInfo(name: 'Varun Chakaravarthy', role: 'Bowler', number: '29', nationality: 'India', stats: 'Wickets: 19, Econ: 8.1', imageId: '12926'),
      PlayerInfo(name: 'Vaibhav Arora', role: 'Bowler', number: '14', nationality: 'India', stats: 'Wickets: 10', imageId: '13672'),
      PlayerInfo(name: 'Rahmanullah Gurbaz', role: 'Wicketkeeper', number: '21', nationality: 'Afghanistan', stats: 'DNP', imageId: '14013'),
      PlayerInfo(name: 'Nitish Rana', role: 'Batter', number: '27', nationality: 'India', stats: 'DNP', imageId: '14014'),
      PlayerInfo(name: 'Suyash Sharma', role: 'Bowler', number: '9', nationality: 'India', stats: 'DNP', imageId: '14015'),
      PlayerInfo(name: 'Sherfane Rutherford', role: 'Batter', number: '50', nationality: 'West Indies', stats: 'DNP', imageId: '14016'),
    ],
    'rajasthan royals': [
      PlayerInfo(name: 'Yashasvi Jaiswal', role: 'Batter', number: '64', nationality: 'India', stats: 'Runs: 435, 100s: 1', imageId: '13533'),
      PlayerInfo(name: 'Jos Buttler', role: 'Wicketkeeper', number: '63', nationality: 'England', stats: 'Runs: 359, 100s: 2', imageId: '7909'),
      PlayerInfo(name: 'Sanju Samson', role: 'Batter', number: '8', nationality: 'India', stats: 'Runs: 531, Avg: 48.2', imageId: '8271'),
      PlayerInfo(name: 'Riyan Parag', role: 'Batter', number: '12', nationality: 'India', stats: 'Runs: 567, Avg: 56.7', imageId: '12777'),
      PlayerInfo(name: 'Shimron Hetmyer', role: 'Batter', number: '18', nationality: 'West Indies', stats: 'Strike Rate: 163.2', imageId: '9376'),
      PlayerInfo(name: 'Dhruv Jurel', role: 'Batter', number: '21', nationality: 'India', stats: 'Runs: 195, SR: 138.5', imageId: '14198'),
      PlayerInfo(name: 'Ravichandran Ashwin', role: 'All-Rounder', number: '99', nationality: 'India', stats: 'Wickets: 8, Econ: 8.3', imageId: '1530'),
      PlayerInfo(name: 'Trent Boult', role: 'Bowler', number: '18', nationality: 'New Zealand', stats: 'Wickets: 14, Econ: 7.8', imageId: '7723'),
      PlayerInfo(name: 'Avesh Khan', role: 'Bowler', number: '27', nationality: 'India', stats: 'Wickets: 13, Econ: 8.9', imageId: '10918'),
      PlayerInfo(name: 'Sandeep Sharma', role: 'Bowler', number: '20', nationality: 'India', stats: 'Wickets: 11, Econ: 7.9', imageId: '8050'),
      PlayerInfo(name: 'Yuzvendra Chahal', role: 'Bowler', number: '3', nationality: 'India', stats: 'Wickets: 15, Econ: 8.8', imageId: '7910'),
      PlayerInfo(name: 'Rovman Powell', role: 'Batter', number: '14', nationality: 'West Indies', stats: 'DNP', imageId: '14021'),
      PlayerInfo(name: 'Navdeep Saini', role: 'Bowler', number: '29', nationality: 'India', stats: 'DNP', imageId: '14022'),
      PlayerInfo(name: 'Donavon Ferreira', role: 'Batter', number: '55', nationality: 'South Africa', stats: 'DNP', imageId: '14023'),
      PlayerInfo(name: 'Nandre Burger', role: 'Bowler', number: '88', nationality: 'South Africa', stats: 'DNP', imageId: '14024'),
    ],
    'sunrisers hyderabad': [
      PlayerInfo(name: 'Travis Head', role: 'Batter', number: '62', nationality: 'Australia', stats: 'Runs: 567, Strike Rate: 192.2', imageId: '8709'),
      PlayerInfo(name: 'Abhishek Sharma', role: 'Batter', number: '4', nationality: 'India', stats: 'Runs: 482, Sixes: 41', imageId: '11796'),
      PlayerInfo(name: 'Nitish Kumar Reddy', role: 'All-Rounder', number: '67', nationality: 'India', stats: 'Runs: 303, Wickets: 3', imageId: '14188'),
      PlayerInfo(name: 'Heinrich Klaasen', role: 'Wicketkeeper', number: '45', nationality: 'South Africa', stats: 'Runs: 465, SR: 171.0', imageId: '8422'),
      PlayerInfo(name: 'Abdul Samad', role: 'Batter', number: '1', nationality: 'India', stats: 'Strike Rate: 168.2', imageId: '12825'),
      PlayerInfo(name: 'Shahbaz Ahmed', role: 'All-Rounder', number: '21', nationality: 'India', stats: 'Runs: 202, Wickets: 6', imageId: '12918'),
      PlayerInfo(name: 'Pat Cummins', role: 'All-Rounder', number: '30', nationality: 'Australia', stats: 'Wickets: 17, Econ: 8.9', imageId: '8095'),
      PlayerInfo(name: 'Bhuvneshwar Kumar', role: 'Bowler', number: '15', nationality: 'India', stats: 'Wickets: 11, Econ: 9.0', imageId: '1726'),
      PlayerInfo(name: 'Jaydev Unadkat', role: 'Bowler', number: '46', nationality: 'India', stats: 'Wickets: 8, Econ: 9.3', imageId: '6410'),
      PlayerInfo(name: 'Mayank Markande', role: 'Bowler', number: '11', nationality: 'India', stats: 'Wickets: 8', imageId: '11799'),
      PlayerInfo(name: 'T Natarajan', role: 'Bowler', number: '44', nationality: 'India', stats: 'Wickets: 19, Econ: 9.0', imageId: '10884'),
      PlayerInfo(name: 'Glenn Phillips', role: 'Batter', number: '23', nationality: 'New Zealand', stats: 'DNP', imageId: '14017'),
      PlayerInfo(name: 'Washington Sundar', role: 'All-Rounder', number: '5', nationality: 'India', stats: 'DNP', imageId: '14018'),
      PlayerInfo(name: 'Umran Malik', role: 'Bowler', number: '24', nationality: 'India', stats: 'DNP', imageId: '14019'),
      PlayerInfo(name: 'Rahul Tripathi', role: 'Batter', number: '52', nationality: 'India', stats: 'DNP', imageId: '14020'),
    ],
    'gujarat titans': [
      PlayerInfo(name: 'Shubman Gill', role: 'Batter', number: '7', nationality: 'India', stats: 'Runs: 426, Avg: 38.7', imageId: '11808'),
      PlayerInfo(name: 'Sai Sudharsan', role: 'Batter', number: '23', nationality: 'India', stats: 'Runs: 527, Avg: 47.9', imageId: '14201'),
      PlayerInfo(name: 'David Miller', role: 'Batter', number: '10', nationality: 'South Africa', stats: 'Runs: 268, SR: 151.0', imageId: '571'),
      PlayerInfo(name: 'Shahrukh Khan', role: 'Batter', number: '24', nationality: 'India', stats: 'Strike Rate: 165.4', imageId: '10890'),
      PlayerInfo(name: 'Rahul Tewatia', role: 'All-Rounder', number: '20', nationality: 'India', stats: 'Runs: 188, SR: 145.0', imageId: '9631'),
      PlayerInfo(name: 'Rashid Khan', role: 'All-Rounder', number: '19', nationality: 'Afghanistan', stats: 'Wickets: 10, Econ: 8.4', imageId: '10738'),
      PlayerInfo(name: 'R Sai Kishore', role: 'Bowler', number: '8', nationality: 'India', stats: 'Wickets: 7, Econ: 9.1', imageId: '11795'),
      PlayerInfo(name: 'Mohit Sharma', role: 'Bowler', number: '18', nationality: 'India', stats: 'Wickets: 13, Econ: 9.5', imageId: '7941'),
      PlayerInfo(name: 'Umesh Yadav', role: 'Bowler', number: '70', nationality: 'India', stats: 'Wickets: 8', imageId: '1858'),
      PlayerInfo(name: 'Spencer Johnson', role: 'Bowler', number: '45', nationality: 'Australia', stats: 'Wickets: 4', imageId: '16084'),
      PlayerInfo(name: 'Noor Ahmad', role: 'Bowler', number: '15', nationality: 'Afghanistan', stats: 'Wickets: 8, Econ: 8.2', imageId: '14304'),
      PlayerInfo(name: 'Kane Williamson', role: 'Batter', number: '22', nationality: 'New Zealand', stats: 'DNP', imageId: '14025'),
      PlayerInfo(name: 'Wriddhiman Saha', role: 'Wicketkeeper', number: '6', nationality: 'India', stats: 'DNP', imageId: '14026'),
      PlayerInfo(name: 'Joshua Little', role: 'Bowler', number: '30', nationality: 'Ireland', stats: 'DNP', imageId: '14027'),
      PlayerInfo(name: 'Kartik Tyagi', role: 'Bowler', number: '13', nationality: 'India', stats: 'DNP', imageId: '14028'),
    ],
    'lucknow super giants': [
      PlayerInfo(name: 'KL Rahul', role: 'Wicketkeeper', number: '1', nationality: 'India', stats: 'Runs: 520, Avg: 37.1', imageId: '8733'),
      PlayerInfo(name: 'Devdutt Padikkal', role: 'Batter', number: '19', nationality: 'India', stats: 'Runs: 110', imageId: '11803'),
      PlayerInfo(name: 'Marcus Stoinis', role: 'All-Rounder', number: '17', nationality: 'Australia', stats: 'Runs: 388, Wickets: 4', imageId: '7974'),
      PlayerInfo(name: 'Nicholas Pooran', role: 'Batter', number: '29', nationality: 'West Indies', stats: 'Runs: 499, Sixes: 36', imageId: '9582'),
      PlayerInfo(name: 'Deepak Hooda', role: 'Batter', number: '5', nationality: 'India', stats: 'Runs: 145', imageId: '9423'),
      PlayerInfo(name: 'Ayush Badoni', role: 'Batter', number: '11', nationality: 'India', stats: 'Runs: 235, SR: 138.0', imageId: '13524'),
      PlayerInfo(name: 'Krunal Pandya', role: 'All-Rounder', number: '25', nationality: 'India', stats: 'Wickets: 6, Econ: 7.2', imageId: '9654'),
      PlayerInfo(name: 'Ravi Bishnoi', role: 'Bowler', number: '56', nationality: 'India', stats: 'Wickets: 10, Econ: 8.7', imageId: '12782'),
      PlayerInfo(name: 'Naveen-ul-Haq', role: 'Bowler', number: '78', nationality: 'Afghanistan', stats: 'Wickets: 12, Econ: 8.8', imageId: '10767'),
      PlayerInfo(name: 'Yash Thakur', role: 'Bowler', number: '34', nationality: 'India', stats: 'Wickets: 11', imageId: '12848'),
      PlayerInfo(name: 'Mayank Yadav', role: 'Bowler', number: '23', nationality: 'India', stats: 'Wickets: 7, Econ: 6.9, Speed: 156kph', imageId: '15494'),
      PlayerInfo(name: 'Quinton de Kock', role: 'Wicketkeeper', number: '12', nationality: 'South Africa', stats: 'DNP', imageId: '14029'),
      PlayerInfo(name: 'Amit Mishra', role: 'Bowler', number: '99', nationality: 'India', stats: 'DNP', imageId: '14030'),
      PlayerInfo(name: 'Prerak Mankad', role: 'All-Rounder', number: '24', nationality: 'India', stats: 'DNP', imageId: '14031'),
      PlayerInfo(name: 'Shamar Joseph', role: 'Bowler', number: '8', nationality: 'West Indies', stats: 'DNP', imageId: '14032'),
    ],
    'punjab kings': [
      PlayerInfo(name: 'Prabhsimran Singh', role: 'Batter', number: '84', nationality: 'India', stats: 'Runs: 334, SR: 156.8', imageId: '11804'),
      PlayerInfo(name: 'Jonny Bairstow', role: 'Batter', number: '51', nationality: 'England', stats: 'Runs: 298, 100s: 1', imageId: '7911'),
      PlayerInfo(name: 'Rilee Rossouw', role: 'Batter', number: '99', nationality: 'South Africa', stats: 'Runs: 211, SR: 148.0', imageId: '1878'),
      PlayerInfo(name: 'Shashank Singh', role: 'Batter', number: '25', nationality: 'India', stats: 'Runs: 354, Avg: 44.2', imageId: '10901'),
      PlayerInfo(name: 'Jitesh Sharma', role: 'Wicketkeeper', number: '23', nationality: 'India', stats: 'Runs: 187, Catches: 12', imageId: '10898'),
      PlayerInfo(name: 'Sam Curran', role: 'All-Rounder', number: '58', nationality: 'England', stats: 'Runs: 270, Wickets: 16', imageId: '10729'),
      PlayerInfo(name: 'Ashutosh Sharma', role: 'Batter', number: '12', nationality: 'India', stats: 'Strike Rate: 189.2', imageId: '13665'),
      PlayerInfo(name: 'Harpreet Brar', role: 'Bowler', number: '95', nationality: 'India', stats: 'Wickets: 8, Econ: 7.9', imageId: '11802'),
      PlayerInfo(name: 'Harshal Patel', role: 'Bowler', number: '83', nationality: 'India', stats: 'Wickets: 24, Purple Cap', imageId: '7901'),
      PlayerInfo(name: 'Rahul Chahar', role: 'Bowler', number: '2', nationality: 'India', stats: 'Wickets: 10', imageId: '10895'),
      PlayerInfo(name: 'Arshdeep Singh', role: 'Bowler', number: '9', nationality: 'India', stats: 'Wickets: 19, Econ: 9.3', imageId: '12779'),
      PlayerInfo(name: 'Chris Woakes', role: 'All-Rounder', number: '15', nationality: 'England', stats: 'DNP', imageId: '14040'),
      PlayerInfo(name: 'Tanay Thyagarajan', role: 'All-Rounder', number: '33', nationality: 'India', stats: 'DNP', imageId: '14046'),
      PlayerInfo(name: 'Nathan Ellis', role: 'Bowler', number: '12', nationality: 'Australia', stats: 'DNP', imageId: '14042'),
      PlayerInfo(name: 'Rishi Dhawan', role: 'All-Rounder', number: '22', nationality: 'India', stats: 'DNP', imageId: '14047'),
    ],
    'india': [
      PlayerInfo(name: 'Rohit Sharma', role: 'Batter', number: '45', nationality: 'India', stats: 'T20I Runs: 4231, Avg: 32.1', imageId: '576'),
      PlayerInfo(name: 'Yashasvi Jaiswal', role: 'Batter', number: '64', nationality: 'India', stats: 'T20I Strike Rate: 161.4', imageId: '13533'),
      PlayerInfo(name: 'Virat Kohli', role: 'Batter', number: '18', nationality: 'India', stats: 'T20I Runs: 4188, Avg: 48.7', imageId: '1413'),
      PlayerInfo(name: 'Suryakumar Yadav', role: 'Batter', number: '63', nationality: 'India', stats: 'T20I Rank #1 Batter', imageId: '8292'),
      PlayerInfo(name: 'Rishabh Pant', role: 'Wicketkeeper', number: '17', nationality: 'India', stats: 'Catches: 42, SR: 135.0', imageId: '10744'),
      PlayerInfo(name: 'Hardik Pandya', role: 'All-Rounder', number: '33', nationality: 'India', stats: 'Runs: 1450, Wickets: 84', imageId: '9647'),
      PlayerInfo(name: 'Ravindra Jadeja', role: 'All-Rounder', number: '8', nationality: 'India', stats: 'Wickets: 54, Econ: 7.1', imageId: '587'),
      PlayerInfo(name: 'Axar Patel', role: 'All-Rounder', number: '20', nationality: 'India', stats: 'Wickets: 49, Econ: 7.3', imageId: '8293'),
      PlayerInfo(name: 'Kuldeep Yadav', role: 'Bowler', number: '23', nationality: 'India', stats: 'Wickets: 64, Avg: 16.2', imageId: '8313'),
      PlayerInfo(name: 'Jasprit Bumrah', role: 'Bowler', number: '93', nationality: 'India', stats: 'Wickets: 89, Econ: 6.27', imageId: '9311'),
      PlayerInfo(name: 'Arshdeep Singh', role: 'Bowler', number: '9', nationality: 'India', stats: 'Wickets: 79, Avg: 19.1', imageId: '12779'),
      PlayerInfo(name: 'Sanju Samson', role: 'Batter', number: '8', nationality: 'India', stats: 'DNP', imageId: '8271'),
      PlayerInfo(name: 'Shivam Dube', role: 'All-Rounder', number: '25', nationality: 'India', stats: 'DNP', imageId: '11801'),
      PlayerInfo(name: 'Yuzvendra Chahal', role: 'Bowler', number: '3', nationality: 'India', stats: 'DNP', imageId: '7910'),
      PlayerInfo(name: 'Mohammed Siraj', role: 'Bowler', number: '73', nationality: 'India', stats: 'DNP', imageId: '10808'),
    ],
    'australia': [
      PlayerInfo(name: 'Travis Head', role: 'Batter', number: '62', nationality: 'Australia', stats: 'Strike Rate: 147.8', imageId: '8709'),
      PlayerInfo(name: 'David Warner', role: 'Batter', number: '31', nationality: 'Australia', stats: 'T20I Runs: 3277', imageId: '311'),
      PlayerInfo(name: 'Mitchell Marsh', role: 'All-Rounder', number: '8', nationality: 'Australia', stats: 'Captain, SR: 135.4', imageId: '8172'),
      PlayerInfo(name: 'Glenn Maxwell', role: 'All-Rounder', number: '32', nationality: 'Australia', stats: 'T20I Hundreds: 5', imageId: '1844'),
      PlayerInfo(name: 'Marcus Stoinis', role: 'All-Rounder', number: '17', nationality: 'Australia', stats: 'Strike Rate: 145.0', imageId: '7974'),
      PlayerInfo(name: 'Tim David', role: 'Batter', number: '85', nationality: 'Australia', stats: 'Strike Rate: 162.5', imageId: '11532'),
      PlayerInfo(name: 'Matthew Wade', role: 'Wicketkeeper', number: '13', nationality: 'Australia', stats: 'Catches: 58', imageId: '7923'),
      PlayerInfo(name: 'Pat Cummins', role: 'Bowler', number: '30', nationality: 'Australia', stats: 'Wickets: 62, Econ: 7.8', imageId: '8095'),
      PlayerInfo(name: 'Mitchell Starc', role: 'Bowler', number: '56', nationality: 'Australia', stats: 'Wickets: 76, Speed: 148kph', imageId: '7725'),
      PlayerInfo(name: 'Adam Zampa', role: 'Bowler', number: '88', nationality: 'Australia', stats: 'Wickets: 98, Econ: 7.20', imageId: '9585'),
      PlayerInfo(name: 'Josh Hazlewood', role: 'Bowler', number: '38', nationality: 'Australia', stats: 'Wickets: 61, Econ: 7.68', imageId: '8607'),
      PlayerInfo(name: 'Cameron Green', role: 'All-Rounder', number: '4', nationality: 'Australia', stats: 'DNP', imageId: '11782'),
      PlayerInfo(name: 'Josh Inglis', role: 'Wicketkeeper', number: '50', nationality: 'Australia', stats: 'DNP', imageId: '14041'),
      PlayerInfo(name: 'Nathan Ellis', role: 'Bowler', number: '12', nationality: 'Australia', stats: 'DNP', imageId: '14042'),
      PlayerInfo(name: 'Ashton Agar', role: 'All-Rounder', number: '18', nationality: 'Australia', stats: 'DNP', imageId: '14043'),
    ],
    'pakistan': [
      PlayerInfo(name: 'Babar Azam', role: 'Batter', number: '56', nationality: 'Pakistan', stats: 'T20I Runs: 4145, Avg: 41.0', imageId: '8097'),
      PlayerInfo(name: 'Mohammad Rizwan', role: 'Wicketkeeper', number: '16', nationality: 'Pakistan', stats: 'T20I Runs: 3313, Avg: 48.7', imageId: '8179'),
      PlayerInfo(name: 'Saim Ayub', role: 'Batter', number: '63', nationality: 'Pakistan', stats: 'T20I Strike Rate: 138.2', imageId: '16281'),
      PlayerInfo(name: 'Fakhar Zaman', role: 'Batter', number: '39', nationality: 'Pakistan', stats: 'T20I Strike Rate: 132.9', imageId: '10747'),
      PlayerInfo(name: 'Usman Khan', role: 'Batter', number: '72', nationality: 'Pakistan', stats: 'Runs: 120, SR: 135.0', imageId: '18534'),
      PlayerInfo(name: 'Iftikhar Ahmed', role: 'All-Rounder', number: '95', nationality: 'Pakistan', stats: 'Wickets: 7, Runs: 915', imageId: '8093'),
      PlayerInfo(name: 'Imad Wasim', role: 'All-Rounder', number: '9', nationality: 'Pakistan', stats: 'Wickets: 65, Econ: 6.26', imageId: '8095'),
      PlayerInfo(name: 'Shadab Khan', role: 'All-Rounder', number: '7', nationality: 'Pakistan', stats: 'Wickets: 104, Runs: 304', imageId: '10749'),
      PlayerInfo(name: 'Shaheen Afridi', role: 'Bowler', number: '10', nationality: 'Pakistan', stats: 'Wickets: 91, Econ: 7.67', imageId: '10751'),
      PlayerInfo(name: 'Naseem Shah', role: 'Bowler', number: '71', nationality: 'Pakistan', stats: 'Wickets: 24, Econ: 7.30', imageId: '13617'),
      PlayerInfo(name: 'Haris Rauf', role: 'Bowler', number: '97', nationality: 'Pakistan', stats: 'Wickets: 98, Econ: 8.02', imageId: '13619'),
      PlayerInfo(name: 'Azam Khan', role: 'Wicketkeeper', number: '77', nationality: 'Pakistan', stats: 'DNP', imageId: '16283'),
      PlayerInfo(name: 'Abbas Afridi', role: 'Bowler', number: '40', nationality: 'Pakistan', stats: 'DNP', imageId: '16285'),
      PlayerInfo(name: 'Abrar Ahmed', role: 'Bowler', number: '82', nationality: 'Pakistan', stats: 'DNP', imageId: '16287'),
      PlayerInfo(name: 'Mohammad Amir', role: 'Bowler', number: '5', nationality: 'Pakistan', stats: 'DNP', imageId: '8091'),
    ]
  };

  @override
  void initState() {
    super.initState();
    _fetchScorecardIfNeeded();
  }

  Future<void> _fetchScorecardIfNeeded() async {
    if (widget.matchId == null) return;
    
    setState(() => _isLoadingScorecard = true);
    try {
      final path = widget.isCricket
          ? '/api/cricket/match/${widget.matchId}/scorecard'
          : widget.isKabaddi
              ? '/api/kabaddi/match/${widget.matchId}/scorecard'
              : '/api/football/match/${widget.matchId}/scorecard';
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final Map<String, dynamic>? teamsData = data['teams'];
          final Map<String, dynamic>? liveStateData = data['liveState'];
          
          final Map<String, List<PlayerInfo>> loadedSquads = {};
          final Map<String, List<PlayerInfo>> loadedPlayingXIs = {};
          final Map<String, List<PlayerInfo>> loadedBenches = {};

          if (teamsData != null) {
            teamsData.forEach((teamName, details) {
              final String cleanedName = teamName.toLowerCase().trim();
              
              // Load players
              final List<dynamic> playersList = details['players'] ?? [];
              loadedSquads[cleanedName] = playersList.map((p) {
                return PlayerInfo(
                  name: p['name'] ?? 'Unknown',
                  role: p['role'] ?? 'Player',
                  number: p['number']?.toString() ?? '0',
                  nationality: p['nationality'] ?? 'International',
                  stats: p['stats'] ?? '',
                  imageId: p['imageId']?.toString(),
                );
              }).toList();

              // Load playingXI
              final List<dynamic> playingXIList = details['playingXI'] ?? [];
              loadedPlayingXIs[cleanedName] = playingXIList.map((p) {
                return PlayerInfo(
                  name: p['name'] ?? 'Unknown',
                  role: p['role'] ?? 'Player',
                  number: p['number']?.toString() ?? '0',
                  nationality: p['nationality'] ?? 'International',
                  stats: p['stats'] ?? '',
                  imageId: p['imageId']?.toString(),
                );
              }).toList();

              // Load bench
              final List<dynamic> benchList = details['bench'] ?? [];
              loadedBenches[cleanedName] = benchList.map((p) {
                return PlayerInfo(
                  name: p['name'] ?? 'Unknown',
                  role: p['role'] ?? 'Player',
                  number: p['number']?.toString() ?? '0',
                  nationality: p['nationality'] ?? 'International',
                  stats: p['stats'] ?? '',
                  imageId: p['imageId']?.toString(),
                );
              }).toList();
            });
          }

          if (mounted) {
            setState(() {
              _apiSquads = loadedSquads;
              _apiPlayingXIs = loadedPlayingXIs;
              _apiBenches = loadedBenches;
              _liveState = liveStateData;
              _isLoadingScorecard = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching live scorecard: $e');
    }
    if (mounted) {
      setState(() => _isLoadingScorecard = false);
    }
  }

  bool _teamNamesMatch(String nameA, String nameB) {
    final a = nameA.toLowerCase().trim();
    final b = nameB.toLowerCase().trim();
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;

    const abbreviations = {
      'csk': ['chennai', 'chennai super kings', 'csk'],
      'mi': ['mumbai', 'mumbai indians', 'mi'],
      'rcb': ['royal challengers bengaluru', 'royal challengers bangalore', 'rcb', 'bengaluru', 'bangalore'],
      'kkr': ['kolkata knight riders', 'kkr', 'kolkata'],
      'rr': ['rajasthan royals', 'rr', 'rajasthan'],
      'dc': ['delhi capitals', 'dc', 'delhi'],
      'pbks': ['punjab kings', 'pbks', 'punjab'],
      'srh': ['sunrisers hyderabad', 'srh', 'hyderabad'],
      'gt': ['gujarat titans', 'gt', 'gujarat'],
      'lsg': ['lucknow super giants', 'lsg', 'lucknow'],
      'ind': ['india', 'ind'],
      'aus': ['australia', 'aus'],
      'pak': ['pakistan', 'pak'],
    };

    for (var entry in abbreviations.entries) {
      final abbr = entry.key;
      final synonyms = entry.value;
      final aMatch = synonyms.any((s) => a.contains(s) || s.contains(a) || a == abbr);
      final bMatch = synonyms.any((s) => b.contains(s) || s.contains(b) || b == abbr);
      if (aMatch && bMatch) return true;
    }

    return false;
  }

  List<PlayerInfo> _getPlayingXIForTeam(String name) {
    // Check if playingXI got fetched from Cricbuzz API live scorecard first
    for (var key in _apiPlayingXIs.keys) {
      if (_teamNamesMatch(key, name) && _apiPlayingXIs[key]!.isNotEmpty) {
        return _apiPlayingXIs[key]!;
      }
    }
    
    // Default to first 11 players of squad (or 7 for Kabaddi)
    final squad = _getSquadForTeam(name);
    final cleaned = name.toLowerCase().trim();
    final isKabaddi = widget.isKabaddi || cleaned == 'pat' || cleaned == 'mum' || cleaned == 'jai' || cleaned == 'blr' || cleaned == 'del' || cleaned == 'pun' ||
                      cleaned.contains('pirates') || cleaned.contains('mumba') || cleaned.contains('panthers') || cleaned.contains('bulls') || cleaned.contains('paltan');
    final cutoff = isKabaddi ? 7 : 11;
    if (squad.length > cutoff) {
      return squad.sublist(0, cutoff);
    }
    return squad;
  }

  List<PlayerInfo> _getBenchForTeam(String name) {
    // Check if bench got fetched from Cricbuzz API live scorecard first
    for (var key in _apiBenches.keys) {
      if (_teamNamesMatch(key, name) && _apiBenches[key]!.isNotEmpty) {
        return _apiBenches[key]!;
      }
    }
    
    // Default to remaining players of squad
    final squad = _getSquadForTeam(name);
    final cleaned = name.toLowerCase().trim();
    final isKabaddi = widget.isKabaddi || cleaned == 'pat' || cleaned == 'mum' || cleaned == 'jai' || cleaned == 'blr' || cleaned == 'del' || cleaned == 'pun' ||
                      cleaned.contains('pirates') || cleaned.contains('mumba') || cleaned.contains('panthers') || cleaned.contains('bulls') || cleaned.contains('paltan');
    final cutoff = isKabaddi ? 7 : 11;
    if (squad.length > cutoff) {
      return squad.sublist(cutoff);
    }
    
    // Fallback: generate some mock bench players
    if (isKabaddi) {
      return [
        PlayerInfo(name: 'Bench Player 1', role: 'Raider', number: '8', nationality: 'Indian', stats: 'DNP'),
        PlayerInfo(name: 'Bench Player 2', role: 'Defender', number: '9', nationality: 'Indian', stats: 'DNP'),
        PlayerInfo(name: 'Bench Player 3', role: 'Defender', number: '10', nationality: 'Indian', stats: 'DNP'),
        PlayerInfo(name: 'Bench Player 4', role: 'Raider', number: '11', nationality: 'Indian', stats: 'DNP'),
        PlayerInfo(name: 'Bench Player 5', role: 'Defender', number: '12', nationality: 'Indian', stats: 'DNP'),
      ];
    }
    return [
      PlayerInfo(name: 'Bench Player 1', role: 'Batter', number: '1', nationality: 'Indian', stats: 'DNP'),
      PlayerInfo(name: 'Bench Player 2', role: 'Bowler', number: '2', nationality: 'Indian', stats: 'DNP'),
      PlayerInfo(name: 'Bench Player 3', role: 'Batter', number: '3', nationality: 'Indian', stats: 'DNP'),
      PlayerInfo(name: 'Bench Player 4', role: 'All-Rounder', number: '4', nationality: 'Indian', stats: 'DNP'),
    ];
  }

  List<PlayerInfo> _getSquadForTeam(String name) {
    final cleaned = name.toLowerCase().trim();
    // Check if squad got fetched from Cricbuzz API live scorecard first
    for (var key in _apiSquads.keys) {
      if (_teamNamesMatch(key, name) && _apiSquads[key]!.isNotEmpty) {
        return _apiSquads[key]!;
      }
    }

    // Hardcoded fallback list
    if (cleaned == 'mi' || cleaned.contains('mumbai')) return _teamSquads['mumbai indians']!;
    if (cleaned == 'csk' || cleaned.contains('chennai')) return _teamSquads['chennai super kings']!;
    if (cleaned == 'rcb' || cleaned.contains('bengaluru') || cleaned.contains('bangalore')) return _teamSquads['royal challengers bengaluru']!;
    if (cleaned == 'dc' || cleaned.contains('delhi')) return _teamSquads['delhi capitals']!;
    if (cleaned == 'kkr' || cleaned.contains('kolkata')) return _teamSquads['kolkata knight riders']!;
    if (cleaned == 'rr' || cleaned.contains('rajasthan')) return _teamSquads['rajasthan royals']!;
    if (cleaned == 'srh' || cleaned.contains('hyderabad')) return _teamSquads['sunrisers hyderabad']!;
    if (cleaned == 'gt' || cleaned.contains('gujarat')) return _teamSquads['gujarat titans']!;
    if (cleaned == 'lsg' || cleaned.contains('lucknow')) return _teamSquads['lucknow super giants']!;
    if (cleaned == 'pbks' || cleaned == 'pk' || cleaned.contains('punjab')) return _teamSquads['punjab kings']!;
    if (cleaned == 'ind' || cleaned == 'india') return _teamSquads['india']!;
    if (cleaned == 'aus' || cleaned == 'australia') return _teamSquads['australia']!;
    if (cleaned == 'pak' || cleaned == 'pakistan') return _teamSquads['pakistan']!;

    if (cleaned.contains('real') || (cleaned.contains('madrid') && !cleaned.contains('atletico'))) return _teamSquads['real madrid']!;
    if (cleaned.contains('atletico')) return _teamSquads['atletico madrid']!;
    if (cleaned.contains('arsenal')) return _teamSquads['arsenal']!;
    if (cleaned.contains('bayern') || cleaned.contains('münchen') || cleaned.contains('munchen')) return _teamSquads['bayern münchen']!;
    if (cleaned.contains('psg') || cleaned.contains('paris') || cleaned.contains('germain')) return _teamSquads['psg']!;
    if (cleaned.contains('athletic') || cleaned.contains('bilbao')) return _teamSquads['athletic club']!;

    // Fallback generated squad
    final isCricket = widget.isCricket || cleaned == 'mi' || cleaned == 'csk' || cleaned == 'rcb' || cleaned == 'dc' ||
                      cleaned.contains('indians') || cleaned.contains('kings') || cleaned.contains('challengers') || cleaned.contains('capitals') ||
                      (widget.venue.toLowerCase().contains('stadium') && widget.scoreText.contains('/'));
                      
    final isKabaddi = widget.isKabaddi || cleaned == 'pat' || cleaned == 'mum' || cleaned == 'jai' || cleaned == 'blr' || cleaned == 'del' || cleaned == 'pun' ||
                      cleaned.contains('pirates') || cleaned.contains('mumba') || cleaned.contains('panthers') || cleaned.contains('bulls') || cleaned.contains('paltan');

    final size = isKabaddi ? 12 : 15;
    return List.generate(size, (index) {
      if (isCricket) {
        String role = 'Batter';
        if (index == 0) {
          role = 'Wicketkeeper';
        } else if (index > 3 && index < 7) {
          role = 'All-Rounder';
        } else if (index >= 7 && index < 11) {
          role = 'Bowler';
        } else {
          if (index == 11) {
            role = 'Wicketkeeper';
          } else if (index == 12) {
            role = 'Batter';
          } else if (index == 13) {
            role = 'All-Rounder';
          } else {
            role = 'Bowler';
          }
        }
        return PlayerInfo(
          name: 'Player ${index + 1}',
          role: role,
          number: '${index + 10}',
          nationality: 'International',
          stats: index >= 11 ? 'DNP' : 'Matches: 12, Impact Rating: 8.5',
        );
      } else if (isKabaddi) {
        String role = 'Raider';
        if (index == 3) {
          role = 'Defender - Left Corner';
        } else if (index == 4) {
          role = 'Defender - Right Corner';
        } else if (index == 5) {
          role = 'Defender - Left Cover';
        } else if (index == 6) {
          role = 'Defender - Right Cover';
        } else {
          if (index == 7) {
            role = 'Raider';
          } else {
            role = 'Defender';
          }
        }
        return PlayerInfo(
          name: 'Player ${index + 1}',
          role: role,
          number: '${index + 1}',
          nationality: 'Indian',
          stats: index >= 7 ? 'DNP' : 'Raid Points: ${10 - index}, Tackle Points: ${index % 3}',
        );
      } else {
        String role = 'MF';
        if (index == 0) {
          role = 'GK';
        } else if (index > 0 && index < 5) {
          role = 'DF';
        } else if (index >= 8 && index < 11) {
          role = 'FW';
        } else {
          if (index == 11) {
            role = 'GK';
          } else if (index == 12) {
            role = 'DF';
          } else if (index == 13) {
            role = 'MF';
          } else {
            role = 'FW';
          }
        }
        return PlayerInfo(
          name: 'Player ${index + 1}',
          role: role,
          number: '${index + 1}',
          nationality: 'International',
          stats: index >= 11 ? 'DNP' : 'Form Rank: #${index + 1}',
        );
      }
    });
  }

  Widget _buildLiveTrackerCard() {
    if (_liveState == null) return const SizedBox.shrink();
    
    final target = _liveState!['target'] ?? 183;
    final runsNeeded = _liveState!['runsNeeded'] ?? 12;
    final ballsRemaining = _liveState!['ballsRemaining'] ?? 6;
    final requiredRunRate = _liveState!['requiredRunRate'] ?? 12.0;
    final currentRunRate = _liveState!['currentRunRate'] ?? 9.0;
    
    final activeBatsmen = _liveState!['activeBatsmen'] as List<dynamic>? ?? [];
    final activeBowler = _liveState!['activeBowler'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$runsNeeded Runs Needed',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'off $ballsRemaining balls remaining',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'RRR: ${requiredRunRate.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CRR', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      currentRunRate.toStringAsFixed(2),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TARGET', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      target.toString(),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey, height: 24, thickness: 0.5),
          Text(
            'BATSMEN',
            style: GoogleFonts.inter(color: const Color(0xFF00FF7F), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          ...activeBatsmen.map((b) {
            final isStriker = b['isStriker'] ?? false;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        b['name'] ?? 'Batsman',
                        style: GoogleFonts.inter(
                          color: isStriker ? Colors.white : Colors.grey[400],
                          fontWeight: isStriker ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (isStriker) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Color(0xFF00FF7F), size: 12),
                      ],
                    ],
                  ),
                  Text(
                    '${b['runs']} (${b['ballsFaced']})',
                    style: GoogleFonts.inter(
                      color: isStriker ? Colors.white : Colors.grey[400],
                      fontWeight: isStriker ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: Colors.grey, height: 24, thickness: 0.5),
          Text(
            'BOWLER',
            style: GoogleFonts.inter(color: const Color(0xFF00FF7F), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activeBowler['name'] ?? 'Bowler',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              ),
              Text(
                '${activeBowler['overs']} - ${activeBowler['maidens']} - ${activeBowler['runsConceded']} - ${activeBowler['wickets']}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (activeBowler['currentOverStats'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'This Over: ',
                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                ),
                const SizedBox(width: 6),
                ...(activeBowler['currentOverStats'] as List<dynamic>).map((ball) {
                  final ballStr = ball.toString();
                  final isWicket = ballStr.toUpperCase() == 'W';
                  final isBoundary = ballStr == '4' || ballStr == '6';
                  Color bgColor = Colors.grey[850]!;
                  Color textColor = Colors.white;
                  
                  if (isWicket) {
                    bgColor = Colors.redAccent;
                    textColor = Colors.white;
                  } else if (isBoundary) {
                    bgColor = const Color(0xFF00FF7F).withValues(alpha: 0.15);
                    textColor = const Color(0xFF00FF7F);
                  }
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: isBoundary ? Border.all(color: const Color(0xFF00FF7F), width: 0.5) : null,
                    ),
                    child: Center(
                      child: Text(
                        ballStr,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKabaddiLiveTrackerCard() {
    if (_liveState == null) return const SizedBox.shrink();
    
    final timeRemaining = _liveState!['timeRemaining'] ?? '00:00';
    final activeRaid = _liveState!['activeRaid'] as Map<String, dynamic>? ?? {};
    
    final homeRaid = _liveState!['raidPoints']?['home'] ?? 0;
    final awayRaid = _liveState!['raidPoints']?['away'] ?? 0;
    
    final homeTackle = _liveState!['tacklePoints']?['home'] ?? 0;
    final awayTackle = _liveState!['tacklePoints']?['away'] ?? 0;

    final homeAllOut = _liveState!['allOutPoints']?['home'] ?? 0;
    final awayAllOut = _liveState!['allOutPoints']?['away'] ?? 0;

    final homeExtra = _liveState!['extraPoints']?['home'] ?? 0;
    final awayExtra = _liveState!['extraPoints']?['away'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF7F).withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE TRACKER',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF00FF7F),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'Time Remaining: $timeRemaining',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF7F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'KABADDI',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00FF7F),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Active Raid Info
          if (activeRaid.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.run_circle_outlined, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE RAID',
                          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${activeRaid['raider']}',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Defenders Active: ${activeRaid['defendersActive']}',
                      style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Points Breakdown
          Text(
            'POINTS BREAKDOWN',
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          _buildStatRow('Raid Points', homeRaid.toDouble(), awayRaid.toDouble(), homeRaid.toString(), awayRaid.toString()),
          _buildStatRow('Tackle Points', homeTackle.toDouble(), awayTackle.toDouble(), homeTackle.toString(), awayTackle.toString()),
          _buildStatRow('All Out Points', homeAllOut.toDouble(), awayAllOut.toDouble(), homeAllOut.toString(), awayAllOut.toString()),
          _buildStatRow('Extra Points', homeExtra.toDouble(), awayExtra.toDouble(), homeExtra.toString(), awayExtra.toString()),
        ],
      ),
    );
  }

  Widget _buildFootballLiveTrackerCard() {
    if (_liveState == null) return const SizedBox.shrink();
    
    final possessionHome = _liveState!['possession']?['home'] ?? 50;
    final possessionAway = _liveState!['possession']?['away'] ?? 50;
    
    final events = _liveState!['events'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF7F).withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE MATCH TRACKER',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF00FF7F),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LIVE',
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Possession Section
          Text(
            'Ball Possession',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$possessionHome%',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '$possessionAway%',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Custom split bar for possession
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: possessionHome,
                    child: Container(
                      color: const Color(0xFF00FF7F),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: possessionAway,
                    child: Container(
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Events Timeline
          if (events.isNotEmpty) ...[
            Text(
              'Key Events',
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final time = event['time'] ?? '';
                final type = event['type'] ?? '';
                final player = event['player'] ?? '';
                final detail = event['detail'] ?? '';
                final isHome = event['team'] == 'home';

                IconData iconData = Icons.info;
                Color iconColor = Colors.grey;

                if (type == 'goal') {
                  iconData = Icons.sports_soccer;
                  iconColor = const Color(0xFF00FF7F);
                } else if (type == 'yellow') {
                  iconData = Icons.square;
                  iconColor = Colors.yellow;
                } else if (type == 'red') {
                  iconData = Icons.square;
                  iconColor = Colors.red;
                } else if (type == 'sub') {
                  iconData = Icons.swap_horiz;
                  iconColor = Colors.orange;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          time,
                          style: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(iconData, size: 16, color: iconColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (detail.isNotEmpty)
                              Text(
                                detail,
                                style: GoogleFonts.inter(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        isHome ? 'Home' : 'Away',
                        style: GoogleFonts.inter(
                          color: isHome ? const Color(0xFF00FF7F) : Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isLive ? 'LIVE MATCH' : 'UPCOMING MATCH',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: widget.isLive ? Colors.redAccent : const Color(0xFF00FF7F),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScoreboard(),
            if (widget.isLive && widget.isCricket) _buildLiveTrackerCard(),
            if (widget.isLive && widget.isKabaddi) _buildKabaddiLiveTrackerCard(),
            if (widget.isLive && !widget.isCricket && !widget.isKabaddi) _buildFootballLiveTrackerCard(),
            const SizedBox(height: 24),
            _buildTabBarLayout(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreboard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: widget.isLive ? Colors.redAccent.withValues(alpha: 0.1) : const Color(0xFF00FF7F).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isLive 
                  ? Colors.redAccent.withValues(alpha: 0.2) 
                  : const Color(0xFF00FF7F).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.statusText,
              style: GoogleFonts.inter(
                color: widget.isLive ? Colors.redAccent : const Color(0xFF00FF7F), 
                fontWeight: FontWeight.bold, 
                fontSize: 12
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTeamLogo(widget.homeTeam, widget.homeTeam.isNotEmpty ? widget.homeTeam[0] : '?', widget.homeLogoUrl),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.scoreText,
                      style: GoogleFonts.outfit(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.venue,
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              _buildTeamLogo(widget.awayTeam, widget.awayTeam.isNotEmpty ? widget.awayTeam[0] : '?', widget.awayLogoUrl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String name, String shortName, String? logoUrl) {
    final iplAsset = getIplLogoAsset(name);
    final kabaddiAsset = getKabaddiLogoAsset(name);
    final logoAsset = iplAsset ?? kabaddiAsset;
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.grey[800],
          child: logoAsset != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: Image.asset(
                    logoAsset,
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      shortName.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                )
              : (logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.network(
                        logoUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          shortName.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      shortName.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarLayout(BuildContext context) {
    return Column(
      children: [
        _buildCustomTabBar(),
        const SizedBox(height: 16),
        _activeTab == 0
            ? _buildLineupsTab(context)
            : (_activeTab == 1 ? _buildStatsTab() : _buildAnalysisTab()),
      ],
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'LINEUPS'),
          _buildTabItem(1, 'STATS'),
          _buildTabItem(2, 'ANALYSIS'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00FF7F).withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive ? Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3)) : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: isActive ? const Color(0xFF00FF7F) : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineupsTab(BuildContext context) {
    if (_isLoadingScorecard) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF7F)),
        ),
      );
    }

    final homePlaying = _getPlayingXIForTeam(widget.homeTeam);
    final homeBench = _getBenchForTeam(widget.homeTeam);
    
    final awayPlaying = _getPlayingXIForTeam(widget.awayTeam);
    final awayBench = _getBenchForTeam(widget.awayTeam);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLineupTeamIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedLineupTeamIndex == 0 
                              ? const Color(0xFF00FF7F).withValues(alpha: 0.15) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: _selectedLineupTeamIndex == 0 
                              ? Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3)) 
                              : null,
                        ),
                        child: Text(
                          widget.homeTeam.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: _selectedLineupTeamIndex == 0 ? const Color(0xFF00FF7F) : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLineupTeamIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedLineupTeamIndex == 1 
                              ? const Color(0xFF00FF7F).withValues(alpha: 0.15) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: _selectedLineupTeamIndex == 1 
                              ? Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3)) 
                              : null,
                        ),
                        child: Text(
                          widget.awayTeam.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: _selectedLineupTeamIndex == 1 ? const Color(0xFF00FF7F) : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _selectedLineupTeamIndex == 0
              ? _buildTeamList(context, 'PLAYING XI', homePlaying, homeBench)
              : _buildTeamList(context, 'PLAYING XI', awayPlaying, awayBench),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: _buildTeamList(context, 'PLAYING XI', homePlaying, homeBench),
          ),
        ),
        Expanded(
          child: _buildTeamList(context, 'PLAYING XI', awayPlaying, awayBench),
        ),
      ],
    );
  }

  Widget _buildTeamList(BuildContext context, String title, List<PlayerInfo> playingXI, List<PlayerInfo> bench) {
    final totalCount = playingXI.length + (bench.isNotEmpty ? bench.length + 1 : 0);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < playingXI.length) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00FF7F),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _buildPlayerRow(context, playingXI[index]),
              ],
            );
          }
          return _buildPlayerRow(context, playingXI[index]);
        } else {
          final benchIndex = index - playingXI.length;
          if (benchIndex == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.grey, height: 24, thickness: 0.5),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                  child: Text(
                    'BENCH',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            );
          }
          final actualBenchIndex = benchIndex - 1;
          if (actualBenchIndex < bench.length) {
            return _buildPlayerRow(context, bench[actualBenchIndex]);
          }
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildPlayerRow(BuildContext context, PlayerInfo player) {
    return InkWell(
      onTap: () => _showPlayerDetails(context, player),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[850],
              child: Text(
                player.name.isNotEmpty ? player.name[0] : '?',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF00FF7F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    player.role,
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final cleaned = widget.homeTeam.toLowerCase();
    final isCricket = widget.isCricket || cleaned == 'mi' || cleaned == 'csk' || cleaned == 'rcb' || cleaned == 'dc' ||
                      cleaned.contains('indians') || cleaned.contains('kings') || cleaned.contains('challengers') || cleaned.contains('capitals') ||
                      (widget.venue.toLowerCase().contains('stadium') && widget.scoreText.contains('/'));

    final isKabaddi = widget.isKabaddi || cleaned == 'pat' || cleaned == 'mum' || cleaned == 'jai' || cleaned == 'blr' || cleaned == 'del' || cleaned == 'pun' ||
                      cleaned.contains('pirates') || cleaned.contains('mumba') || cleaned.contains('panthers') || cleaned.contains('bulls') || cleaned.contains('paltan');

    // Create a deterministic seed based on home and away team names
    final seed = (widget.homeTeam.codeUnits.fold(0, (a, b) => a + b) * 17 +
                  widget.awayTeam.codeUnits.fold(0, (a, b) => a + b) * 31).abs();

    if (isCricket) {
      // Generate deterministic cricket stats
      final homeRR = 6.0 + ((seed % 35) / 10.0); // 6.0 - 9.4
      final awayRR = 6.0 + (((seed ~/ 7) % 35) / 10.0); // 6.0 - 9.4
      
      final homeSixes = 4 + (seed % 12); // 4 - 15
      final awaySixes = 4 + ((seed ~/ 3) % 12); // 4 - 15
      
      final homeFours = 10 + (seed % 15); // 10 - 24
      final awayFours = 10 + ((seed ~/ 2) % 15); // 10 - 24
      
      final homeExtras = 4 + (seed % 9); // 4 - 12
      final awayExtras = 4 + ((seed ~/ 4) % 9); // 4 - 12
      
      final homeProj = 140 + (seed % 71); // 140 - 210
      final awayProj = 140 + ((seed ~/ 5) % 71); // 140 - 210

      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatRow('Run Rate', homeRR, awayRR, homeRR.toStringAsFixed(1), awayRR.toStringAsFixed(1)),
          _buildStatRow('Sixes', homeSixes.toDouble(), awaySixes.toDouble(), homeSixes.toString(), awaySixes.toString()),
          _buildStatRow('Fours', homeFours.toDouble(), awayFours.toDouble(), homeFours.toString(), awayFours.toString()),
          _buildStatRow('Extras', homeExtras.toDouble(), awayExtras.toDouble(), homeExtras.toString(), awayExtras.toString()),
          _buildStatRow('Projected Score', homeProj.toDouble(), awayProj.toDouble(), homeProj.toString(), awayProj.toString()),
        ],
      );
    } else if (isKabaddi) {
      final homeRaid = 15 + (seed % 10);
      final awayRaid = 15 + ((seed ~/ 3) % 10);
      
      final homeTackle = 6 + (seed % 6);
      final awayTackle = 6 + ((seed ~/ 2) % 6);

      final homeSuperRaid = 1 + (seed % 3);
      final awaySuperRaid = 1 + ((seed ~/ 4) % 3);

      final homeSuperTackle = seed % 3;
      final awaySuperTackle = (seed ~/ 5) % 3;

      final homeAllOut = 1 + (seed % 2);
      final awayAllOut = 1 + ((seed ~/ 6) % 2);

      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatRow('Raid Points', homeRaid.toDouble(), awayRaid.toDouble(), homeRaid.toString(), awayRaid.toString()),
          _buildStatRow('Tackle Points', homeTackle.toDouble(), awayTackle.toDouble(), homeTackle.toString(), awayTackle.toString()),
          _buildStatRow('Super Raids', homeSuperRaid.toDouble(), awaySuperRaid.toDouble(), homeSuperRaid.toString(), awaySuperRaid.toString()),
          _buildStatRow('Super Tackles', homeSuperTackle.toDouble(), awaySuperTackle.toDouble(), homeSuperTackle.toString(), awaySuperTackle.toString()),
          _buildStatRow('All Outs Inflicted', homeAllOut.toDouble(), awayAllOut.toDouble(), homeAllOut.toString(), awayAllOut.toString()),
        ],
      );
    } else {
      // Generate deterministic or dynamic football stats
      final possessionHome = _liveState?['possession']?['home'] ?? (40 + (seed % 21)); // 40% - 60%
      final awayPossession = 100 - possessionHome;
      
      final homeShotsTarget = _liveState?['shotsOnTarget']?['home'] ?? (2 + (seed % 8)); // 2 - 9
      final awayShotsTarget = _liveState?['shotsOnTarget']?['away'] ?? (2 + ((seed ~/ 3) % 8)); // 2 - 9
      
      final homeTotalShots = _liveState?['shots']?['home'] ?? (homeShotsTarget + 2 + (seed % 10)); // always >= shots on target
      final awayTotalShots = _liveState?['shots']?['away'] ?? (awayShotsTarget + 2 + ((seed ~/ 2) % 10));
      
      final homeCorners = _liveState?['corners']?['home'] ?? (2 + (seed % 8)); // 2 - 9
      final awayCorners = _liveState?['corners']?['away'] ?? (2 + ((seed ~/ 4) % 8));
      
      final homeFouls = _liveState?['fouls']?['home'] ?? (6 + (seed % 10)); // 6 - 15
      final awayFouls = _liveState?['fouls']?['away'] ?? (6 + ((seed ~/ 5) % 10));

      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatRow('Possession', possessionHome.toDouble(), awayPossession.toDouble(), '$possessionHome%', '$awayPossession%'),
          _buildStatRow('Shots on Target', homeShotsTarget.toDouble(), awayShotsTarget.toDouble(), homeShotsTarget.toString(), awayShotsTarget.toString()),
          _buildStatRow('Total Shots', homeTotalShots.toDouble(), awayTotalShots.toDouble(), homeTotalShots.toString(), awayTotalShots.toString()),
          _buildStatRow('Corners', homeCorners.toDouble(), awayCorners.toDouble(), homeCorners.toString(), awayCorners.toString()),
          _buildStatRow('Fouls', homeFouls.toDouble(), awayFouls.toDouble(), homeFouls.toString(), awayFouls.toString()),
        ],
      );
    }
  }

  Widget _buildStatRow(String label, double homeVal, double awayVal, String homeText, String awayText) {
    final total = homeVal + awayVal;
    final homePct = total > 0 ? homeVal / total : 0.5;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(homeText, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(label.toUpperCase(), style: GoogleFonts.inter(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
              Text(awayText, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (homePct * 100).round(),
                    child: Container(color: const Color(0xFF00FF7F)),
                  ),
                  Container(width: 2, color: Colors.grey[900]),
                  Expanded(
                    flex: ((1 - homePct) * 100).round(),
                    child: Container(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormBadge(String result) {
    Color color = Colors.grey;
    if (result == 'W') {
      color = const Color(0xFF00FF7F);
    } else if (result == 'L') {
      color = Colors.redAccent;
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
      child: Center(
        child: Text(
          result,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    // Generate deterministic past 5 matches form based on team names (strictly W and L, no D)
    final homeSeed = widget.homeTeam.codeUnits.fold(0, (a, b) => a + b);
    final awaySeed = widget.awayTeam.codeUnits.fold(0, (a, b) => a + b);
    
    final homeForm = List.generate(5, (index) {
      final val = (homeSeed + index * 17) % 2;
      return val == 0 ? 'W' : 'L';
    });
    
    final awayForm = List.generate(5, (index) {
      final val = (awaySeed + index * 31) % 2;
      return val == 0 ? 'W' : 'L';
    });

    final homeWins = homeForm.where((x) => x == 'W').length;
    final awayWins = awayForm.where((x) => x == 'W').length;
    
    // Construct dynamic insights focusing strictly on T20 cricket/kabaddi metrics
    String insightsText = "";
    final cleaned = widget.homeTeam.toLowerCase();
    final isCricket = widget.isCricket || cleaned == 'mi' || cleaned == 'csk' || cleaned == 'rcb' || cleaned == 'dc' ||
                      cleaned.contains('indians') || cleaned.contains('kings') || cleaned.contains('challengers') || cleaned.contains('capitals') ||
                      (widget.venue.toLowerCase().contains('stadium') && widget.scoreText.contains('/'));

    final isKabaddi = widget.isKabaddi || cleaned == 'pat' || cleaned == 'mum' || cleaned == 'jai' || cleaned == 'blr' || cleaned == 'del' || cleaned == 'pun' ||
                      cleaned.contains('pirates') || cleaned.contains('mumba') || cleaned.contains('panthers') || cleaned.contains('bulls') || cleaned.contains('paltan');

    if (isCricket) {
      final homeSR = 135 + (homeSeed % 25);
      insightsText = "T20 Analysis: ${widget.homeTeam} enters with $homeWins wins in their last 5 matches (${homeForm.join(' ')}) and a team batting strike rate of $homeSR in recent powerplays, suggesting a clear early powerplay advantage. "
                     "${widget.awayTeam} with $awayWins wins (${awayForm.join(' ')}) counters with a death-overs economy rate of under 8.2. "
                     "The key tactical battle revolves around the middle-overs spin vs pace matchups: ${widget.homeTeam}'s wrist-spinners are predicted to challenge ${widget.awayTeam}'s aggressive hitters on this surface.";
    } else if (isKabaddi) {
      insightsText = "Kabaddi Analysis: ${widget.homeTeam} enters with $homeWins wins in their last 5 outings (${homeForm.join(' ')}), showcasing high raid-point efficiency of over 42%. "
                     "Meanwhile, ${widget.awayTeam} with $awayWins wins (${awayForm.join(' ')}) counters with a solid defensive corner combination, setting up an intense battle of speed raids vs ankle holds.";
    } else {
      insightsText = "Analyzing the last 5 outings, ${widget.homeTeam} shows high momentum with $homeWins wins (${homeForm.join(' ')}), averaging 1.8 goals per match. "
                     "Meanwhile, ${widget.awayTeam} with $awayWins wins (${awayForm.join(' ')}) is playing with a low defensive block, conceding only 0.9 goals per game, setting up an intense battle of attack vs. defense.";
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI WIN PREDICTION',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(widget.homeTeam, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    Flexible(child: Text(widget.awayTeam, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
                  ],
                ),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  // Deterministic per-match probability (40–72%) based on team names
                  final seed = (widget.homeTeam.codeUnits.fold(0, (a, b) => a + b) * 13 +
                                widget.awayTeam.codeUnits.fold(0, (a, b) => a + b) * 7).abs();
                  final homePct = 40 + (seed % 33); // 40–72
                  final awayPct = 100 - homePct;
                  
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 12,
                          child: Row(
                            children: [
                              Expanded(
                                flex: homePct,
                                child: Container(
                                  color: homePct >= awayPct ? const Color(0xFF00FF7F) : Colors.grey[800],
                                ),
                              ),
                              Container(width: 2, color: Colors.grey[900]),
                              Expanded(
                                flex: awayPct,
                                child: Container(
                                  color: awayPct > homePct ? const Color(0xFF00FF7F) : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$homePct% Win Chance', style: GoogleFonts.inter(color: homePct >= awayPct ? const Color(0xFF00FF7F) : Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('$awayPct% Win Chance', style: GoogleFonts.inter(color: awayPct > homePct ? const Color(0xFF00FF7F) : Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'MOMENTUM & INSIGHTS',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Form:', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    ...homeForm.map((result) => _buildFormBadge(result)),
                    const Spacer(),
                    Text('Form:', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    ...awayForm.map((result) => _buildFormBadge(result)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey[800]),
                const SizedBox(height: 12),
                Text(
                  insightsText,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerDetails(BuildContext context, PlayerInfo player) {
    // Generate dynamic performance trend based on player stats and name
    final hash = player.name.hashCode.abs();
    double baseRating = 7.5;
    
    // Attempt to extract impact rating or score from stats
    if (player.stats.contains('Impact Rating:')) {
      final parts = player.stats.split('Impact Rating:');
      if (parts.length > 1) {
        final score = double.tryParse(parts[1].trim().split(',')[0]);
        if (score != null) baseRating = score;
      }
    } else if (player.stats.contains('Econ:')) {
      // Bowler stats, lower economy is better
      final parts = player.stats.split('Econ:');
      if (parts.length > 1) {
        final econ = double.tryParse(parts[1].trim());
        if (econ != null) {
          baseRating = (12.0 - econ).clamp(6.0, 9.8);
        }
      }
    } else if (player.stats.contains('SR:')) {
      // Batter stats, higher strike rate is better
      final parts = player.stats.split('SR:');
      if (parts.length > 1) {
        final sr = double.tryParse(parts[1].trim());
        if (sr != null) {
          baseRating = (6.0 + (sr / 50.0)).clamp(6.0, 9.8);
        }
      }
    }

    final randomTrend = List.generate(5, (index) {
      final variance = ((hash * (index + 3)) % 15 - 7) / 10.0; // -0.7 to +0.7
      return double.parse((baseRating + variance).clamp(5.0, 10.0).toStringAsFixed(1));
    });
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large player avatar using initials
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey[850],
                    child: Text(
                      player.name.isNotEmpty ? player.name[0] : '?',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF00FF7F),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${player.role} • #${player.number.length > 3 ? "IPL" : player.number}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00FF7F),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flag, color: Colors.white70, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                player.nationality,
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.grey, height: 32, thickness: 0.5),
              Text(
                'SEASON STATISTICS',
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Text(
                  player.stats.isEmpty ? 'Matches: 14, Strike Rate: 135.2, Impact Rating: 8.2' : player.stats,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AI PERFORMANCE TREND (LAST 5 MATCHES)',
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  height: 60,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomPaint(
                    painter: SparklinePainter(randomTrend),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  SparklinePainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF7F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = const Color(0xFF00FF7F).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final path = Path();
    final stepX = size.width / (dataPoints.length - 1);
    
    double minVal = dataPoints[0];
    double maxVal = dataPoints[0];
    for (var val in dataPoints) {
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }
    double range = maxVal - minVal;
    if (range == 0) range = 1.0;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = size.height - ((dataPoints[i] - minVal) / range * (size.height - 20) + 10);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
