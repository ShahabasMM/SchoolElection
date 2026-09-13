class Student {
  String id;
  String name;
  String className;
  String division;
  String? imagePath;

  Student({
    required this.id,
    required this.name,
    required this.className,
    required this.division,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'className': className,
        'division': division,
        'imagePath': imagePath,
      };

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        className: j['className']?.toString() ?? '',
        division: j['division']?.toString() ?? '',
        imagePath: j['imagePath']?.toString(),
      );
}

class Division {
  String id;
  String section;
  String className;

  Division({
    required this.id,
    required this.section,
    required this.className,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'section': section,
        'className': className,
      };

  factory Division.fromJson(Map<String, dynamic> j) => Division(
        id: j['id']?.toString() ?? '',
        section: j['section']?.toString() ?? '',
        className: j['className']?.toString() ?? '',
      );
}

class Candidate {
  String id;
  String studentId;
  String divisionId;
  int votes;

  Candidate({
    required this.id,
    required this.studentId,
    required this.divisionId,
    this.votes = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'divisionId': divisionId,
        'votes': votes,
      };

  factory Candidate.fromJson(Map<String, dynamic> j) => Candidate(
        id: j['id']?.toString() ?? '',
        studentId: j['studentId']?.toString() ?? '',
        divisionId: j['divisionId']?.toString() ?? '',
        votes: j['votes'] is num ? (j['votes'] as num).toInt() : 0,
      );
}

/// An HSS stream belongs to +1 or +2.
/// If [batches] is empty, voting goes directly to that stream.
/// If batches are present, the user first chooses a batch.
class HssStream {
  String id;
  String className; // +1 or +2
  String stream;
  List<String> batches;

  HssStream({
    required this.id,
    required this.className,
    required this.stream,
    List<String>? batches,
  }) : batches = List<String>.from(batches ?? const []);

  bool get hasBatches => batches.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'className': className,
        'stream': stream,
        'batches': batches,
      };

  factory HssStream.fromJson(Map<String, dynamic> j) => HssStream(
        id: j['id']?.toString() ?? '',
        className: j['className']?.toString() ?? '',
        stream: j['stream']?.toString() ?? '',
        batches: (j['batches'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
