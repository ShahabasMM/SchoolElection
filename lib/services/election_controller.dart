import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/election_models.dart';

/// Single source of truth for the election.
///
/// Supabase is the primary store and realtime transport. SharedPreferences is
/// kept as a small offline cache so the app can still open when the network is
/// temporarily unavailable.
class ElectionController extends ChangeNotifier {
  static const _studentsKey = 'ghss_students_v2';
  static const _divisionsKey = 'ghss_divisions_v2';
  static const _candidatesKey = 'ghss_candidates_v2';
  static const _hssStreamsKey = 'ghss_hss_streams_v2';

  final students = <Student>[];
  final divisions = <Division>[];
  final candidates = <Candidate>[];
  final hssStreams = <HssStream>[];

  final AudioPlayer player = AudioPlayer();
  SharedPreferences? _prefs;
  RealtimeChannel? _realtime;

  bool _soundReady = false;
  bool _isVoting = false;
  bool _loadingRemote = false;
  bool _remoteReady = false;

  bool get isVoting => _isVoting;
  bool get isRealtimeConnected => _remoteReady;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCache();

    try {
      await _loadRemote();
      _remoteReady = true;
      _subscribeRealtime();
    } catch (e) {
      _remoteReady = false;
      debugPrint('Supabase load failed; using cached data: $e');
    }

    try {
      await player.setReleaseMode(ReleaseMode.release);
      await player.setSource(AssetSource('sounds/vote_beep.wav'));
      _soundReady = true;
    } catch (e) {
      debugPrint('Vote sound preload error: $e');
    }

    notifyListeners();
  }

  Future<void> _loadCache() async {
    final studentsRaw = _prefs?.getString(_studentsKey);
    final divisionsRaw = _prefs?.getString(_divisionsKey);
    final candidatesRaw = _prefs?.getString(_candidatesKey);
    final hssRaw = _prefs?.getString(_hssStreamsKey);

    students
      ..clear()
      ..addAll(_decodeList<Student>(studentsRaw, Student.fromJson));
    divisions
      ..clear()
      ..addAll(_decodeList<Division>(divisionsRaw, Division.fromJson));
    candidates
      ..clear()
      ..addAll(_decodeList<Candidate>(candidatesRaw, Candidate.fromJson));
    hssStreams
      ..clear()
      ..addAll(_decodeList<HssStream>(hssRaw, HssStream.fromJson));
    _rebuildHssDivisions();
  }

  Future<void> _loadRemote() async {
    final studentRows = await _supabase.from('students').select();
    final divisionRows = await _supabase.from('divisions').select();
    final candidateRows = await _supabase.from('candidates').select();
    final hssStreamRows = await _supabase.from('hss_streams').select();
    final hssBatchRows = await _supabase.from('hss_batches').select();
    students
      ..clear()
      ..addAll(studentRows.map((row) => Student(
            id: row['id'].toString(),
            name: row['name'].toString(),
            className: row['class_name'].toString(),
            division: row['division'].toString(),
          )));

    divisions
      ..clear()
      ..addAll(divisionRows.map((row) => Division(
            id: row['id'].toString(),
            className: row['class_name'].toString(),
            section: row['section'].toString(),
          )));

    candidates
      ..clear()
      ..addAll(candidateRows.map((row) => Candidate(
            id: row['id'].toString(),
            studentId: row['student_id'].toString(),
            divisionId: row['division_id'].toString(),
            votes: (row['votes'] as num?)?.toInt() ?? 0,
          )));

    // HSS structure is stored in its own Supabase tables. Divisions are
    // generated locally from that structure because the voting table still
    // uses the common candidates/divisions schema.
    final remoteStreams = hssStreamRows.map((row) => HssStream(
          id: row['id'].toString(),
          className: row['class_name'].toString(),
          stream: row['stream'].toString(),
          batches: hssBatchRows
              .where((b) => b['stream_id'].toString() == row['id'].toString())
              .map((b) => b['name'].toString())
              .toList(),
        )).toList();
    hssStreams
      ..clear()
      ..addAll(remoteStreams);
    _rebuildHssDivisions();
    await _saveCache();
  }

  void _rebuildHssStreamsFromDivisions() {
    final map = <String, HssStream>{};
    for (final d in divisions.where((d) => d.className == '+1' || d.className == '+2')) {
      if (!d.id.startsWith('hss_')) continue;
      final parts = d.id.split('_');
      if (parts.length < 3) continue;
      final streamId = parts[1];
      final existing = map[streamId];
      if (existing == null) {
        final isDirect = parts.sublist(2).join('_') == 'direct';
        map[streamId] = HssStream(
          id: streamId,
          className: d.className,
          stream: isDirect ? d.section : d.section.split(' • ').first,
          batches: isDirect ? <String>[] : [d.section.split(' • ').skip(1).join(' • ')],
        );
      } else if (d.section.contains(' • ')) {
        final batch = d.section.split(' • ').skip(1).join(' • ');
        if (!existing.batches.contains(batch)) existing.batches.add(batch);
      }
    }
    hssStreams
      ..clear()
      ..addAll(map.values);
  }

  void _subscribeRealtime() {
    _realtime?.unsubscribe();
    final channel = _supabase.channel('ghss-evm-realtime');

    for (final table in const [
      'students',
      'divisions',
      'candidates',
      'hss_streams',
      'hss_batches',
    ]) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) {
          unawaited(_refreshFromRealtime());
        },
      );
    }

    channel.subscribe((status, _) {
      _remoteReady = status == RealtimeSubscribeStatus.subscribed;
      notifyListeners();
    });
    _realtime = channel;
  }

  Future<void> _refreshFromRealtime() async {
    if (_loadingRemote) return;
    _loadingRemote = true;
    try {
      await _loadRemote();
      _remoteReady = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Realtime refresh failed: $e');
    } finally {
      _loadingRemote = false;
    }
  }

  List<T> _decodeList<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null || raw.trim().isEmpty) return <T>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <T>[];
      return decoded.whereType<Map>().map((item) => fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _saveCache() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await Future.wait([
      prefs.setString(_studentsKey, jsonEncode(students.map((e) => e.toJson()).toList())),
      prefs.setString(_divisionsKey, jsonEncode(divisions.map((e) => e.toJson()).toList())),
      prefs.setString(_candidatesKey, jsonEncode(candidates.map((e) => e.toJson()).toList())),
      prefs.setString(_hssStreamsKey, jsonEncode(hssStreams.map((e) => e.toJson()).toList())),
    ]);
  }

  List<int> classesFor(String section) => section.toUpperCase() == 'HS' ? [8, 9, 10] : section.toUpperCase() == 'UP' ? [5, 6, 7] : [];
  List<String> hssClasses() => const ['+1', '+2'];
  List<HssStream> hssStreamsFor(String className) => hssStreams.where((s) => s.className == className).toList();

  List<Division> hssDivisionsForStream(HssStream stream) {
    if (stream.batches.isEmpty) {
      final d = division('hss_${stream.id}_direct');
      return d == null ? [] : [d];
    }
    return stream.batches.map((b) => division(_hssDivisionId(stream, b))).whereType<Division>().toList();
  }

  Division? hssDirectDivision(HssStream stream) => stream.hasBatches ? null : division('hss_${stream.id}_direct');
  Division? hssBatchDivision(HssStream stream, String batch) => !stream.hasBatches ? null : division(_hssDivisionId(stream, batch));
  String _hssDivisionId(HssStream stream, String batch) => 'hss_${stream.id}_${_slug(batch)}';
  String _slug(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '').ifEmpty('batch');

  List<Division> divisionsFor(int cls) => divisions.where((d) => d.className == '$cls').toList();
  Student? student(String id) => students.cast<Student?>().firstWhere((s) => s?.id == id, orElse: () => null);
  Division? division(String id) => divisions.cast<Division?>().firstWhere((d) => d?.id == id, orElse: () => null);
  List<Candidate> candidatesFor(String id) => candidates.where((c) => c.divisionId == id).toList();
  int get totalVotes => candidates.fold(0, (sum, c) => sum + c.votes);

  Future<void> addDivision(String cls, String section) async {
    final sec = section.trim().toUpperCase();
    if (sec.isEmpty) return;
    final id = '${cls}_$sec';
    if (division(id) != null) return;
    final item = Division(id: id, className: cls, section: sec);
    try {
      await _supabase.from('divisions').insert({'id': id, 'class_name': cls, 'section': sec});
      divisions.add(item);
      await _saveCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Add division failed: $e');
      rethrow;
    }
  }

  Future<void> removeDivision(String id) async {
    final target = division(id);
    if (target == null) return;
    try {
      await _supabase.from('candidates').delete().eq('division_id', id);
      await _supabase.from('divisions').delete().eq('id', id);
      candidates.removeWhere((c) => c.divisionId == id);
      final used = candidates.map((c) => c.studentId).toSet();
      students.removeWhere((s) => s.className == target.className && s.division.toUpperCase() == target.section.toUpperCase() && !used.contains(s.id));
      divisions.removeWhere((d) => d.id == id);
      await _saveCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Remove division failed: $e');
      rethrow;
    }
  }

  Future<bool> addHssStream({required String className, required String stream}) async {
    final cls = className.trim();
    final name = stream.trim();
    if ((cls != '+1' && cls != '+2') || name.isEmpty) return false;
    if (hssStreams.any((s) => s.className == cls && s.stream.toLowerCase() == name.toLowerCase())) return false;
    final id = _newId('hss');
    try {
      final model = HssStream(id: id, className: cls, stream: name);
      await _supabase.from('hss_streams').insert({
        'id': id,
        'class_name': cls,
        'stream': name,
      });
      hssStreams.add(model);
      _rebuildHssDivisions();
      await _syncGeneratedHssDivisions();
      await _saveCache();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add HSS stream failed: $e');
      rethrow;
    }
  }

  Future<bool> removeHssStream(String streamId) async {
    final target = hssStreams.cast<HssStream?>().firstWhere((s) => s?.id == streamId, orElse: () => null);
    if (target == null) return false;
    final ids = _generatedDivisionIds(target!);
    try {
      final removedStudentIds = candidates
          .where((c) => ids.contains(c.divisionId))
          .map((c) => c.studentId)
          .toSet();
      await _supabase.from('candidates').delete().inFilter('division_id', ids);
      await _supabase.from('divisions').delete().inFilter('id', ids);
      await _supabase.from('hss_batches').delete().eq('stream_id', target!.id);
      await _supabase.from('hss_streams').delete().eq('id', target!.id);
      candidates.removeWhere((c) => ids.contains(c.divisionId));
      divisions.removeWhere((d) => ids.contains(d.id));
      final stillUsed = candidates.map((c) => c.studentId).toSet();
      final studentsToDelete = removedStudentIds.where((id) => !stillUsed.contains(id)).toList();
      if (studentsToDelete.isNotEmpty) {
        await _supabase.from('students').delete().inFilter('id', studentsToDelete);
        students.removeWhere((s) => studentsToDelete.contains(s.id));
      }
      hssStreams.removeWhere((s) => s.id == streamId);
      await _saveCache();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Remove HSS stream failed: $e');
      rethrow;
    }
  }

  Future<bool> addHssBatch({required String streamId, required String batch}) async {
    final target = hssStreams.cast<HssStream?>().firstWhere((s) => s?.id == streamId, orElse: () => null);
    final name = batch.trim();
    if (target == null || name.isEmpty) return false;
    if (target!.batches.any((b) => b.toLowerCase() == name.toLowerCase())) return false;
    if (target.batches.isEmpty && candidatesFor('hss_${target.id}_direct').isNotEmpty) return false;
    try {
      if (target.batches.isEmpty) {
        await _supabase.from('divisions').delete().eq('id', 'hss_${target.id}_direct');
      }
      final batchId = _newId('hss_batch');
      await _supabase.from('hss_batches').insert({
        'id': batchId,
        'stream_id': target.id,
        'name': name,
      });
      target.batches.add(name);
      _rebuildHssDivisions();
      await _syncGeneratedHssDivisions();
      await _saveCache();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add HSS batch failed: $e');
      rethrow;
    }
  }

  Future<bool> removeHssBatch({required String streamId, required String batch}) async {
    final target = hssStreams.cast<HssStream?>().firstWhere((s) => s?.id == streamId, orElse: () => null);
    if (target == null) return false;
    final index = target!.batches.indexWhere((b) => b.toLowerCase() == batch.trim().toLowerCase());
    if (index < 0) return false;
    final actual = target.batches[index];
    final divisionId = _hssDivisionId(target, actual);
    try {
      await _supabase.from('candidates').delete().eq('division_id', divisionId);
      await _supabase.from('divisions').delete().eq('id', divisionId);
      await _supabase
          .from('hss_batches')
          .delete()
          .eq('stream_id', target.id)
          .eq('name', actual);
      candidates.removeWhere((c) => c.divisionId == divisionId);
      divisions.removeWhere((d) => d.id == divisionId);
      target.batches.removeAt(index);
      _rebuildHssDivisions();
      await _syncGeneratedHssDivisions();
      await _saveCache();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Remove HSS batch failed: $e');
      rethrow;
    }
  }

  List<String> _generatedDivisionIds(HssStream stream) => stream.batches.isEmpty ? ['hss_${stream.id}_direct'] : stream.batches.map((b) => _hssDivisionId(stream, b)).toList();

  Future<void> _syncGeneratedHssDivisions() async {
    for (final stream in hssStreams) {
      final desired = hssDivisionsForStream(stream);
      for (final d in desired) {
        await _supabase.from('divisions').upsert({'id': d.id, 'class_name': d.className, 'section': d.section});
      }
    }
  }

  void _rebuildHssDivisions() {
    divisions.removeWhere((d) => d.id.startsWith('hss_'));
    for (final stream in hssStreams) {
      if (stream.batches.isEmpty) {
        divisions.add(Division(id: 'hss_${stream.id}_direct', className: stream.className, section: stream.stream));
      } else {
        for (final batch in stream.batches) {
          divisions.add(Division(id: _hssDivisionId(stream, batch), className: stream.className, section: '${stream.stream} • $batch'));
        }
      }
    }
    divisions.sort((a, b) {
      final ah = a.className.startsWith('+');
      final bh = b.className.startsWith('+');
      if (ah != bh) return ah ? 1 : -1;
      return a.id.compareTo(b.id);
    });
  }

  Future<bool> addCandidateByName({required String name, required String className, required String divisionId, required String section}) async {
    final n = name.trim();
    final sec = section.trim().toUpperCase();
    if (n.isEmpty || division(divisionId) == null) return false;
    final existing = students.cast<Student?>().firstWhere((s) => s?.className == className && s?.division.toUpperCase() == sec && s?.name.trim().toLowerCase() == n.toLowerCase(), orElse: () => null);
    final studentId = existing?.id ?? _newId('student');
    if (candidates.any((c) => c.studentId == studentId && c.divisionId == divisionId)) return false;
    try {
      if (existing == null) {
        await _supabase.from('students').insert({'id': studentId, 'name': n, 'class_name': className, 'division': sec});
        students.add(Student(id: studentId, name: n, className: className, division: sec));
      }
      final candidateId = _newId('candidate');
      await _supabase.from('candidates').insert({'id': candidateId, 'student_id': studentId, 'division_id': divisionId, 'votes': 0});
      candidates.add(Candidate(id: candidateId, studentId: studentId, divisionId: divisionId, votes: 0));
      await _saveCache();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add candidate failed: $e');
      rethrow;
    }
  }

  Future<void> removeCandidate(String id) async {
    final candidate = candidates.cast<Candidate?>().firstWhere((c) => c?.id == id, orElse: () => null);
    if (candidate == null) return;
    try {
      await _supabase.from('candidates').delete().eq('id', id);
      final studentId = candidate!.studentId;
      candidates.removeWhere((c) => c.id == id);
      if (!candidates.any((c) => c.studentId == studentId)) {
        await _supabase.from('students').delete().eq('id', studentId);
        students.removeWhere((s) => s.id == studentId);
      }
      await _saveCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Remove candidate failed: $e');
      rethrow;
    }
  }

  Future<void> vote(String candidateId, String divisionId) async {
    // IMPORTANT: this is a GLOBAL lock. It must stay true until the vote
    // sound has completely finished, not merely until Supabase responds.
    if (_isVoting) return;

    final candidate = candidates.cast<Candidate?>().firstWhere(
      (c) =>
          c?.id == candidateId &&
          c?.divisionId == divisionId,
      orElse: () => null,
    );

    if (candidate == null) return;

    _isVoting = true;
    notifyListeners();

    // Start the sound immediately and KEEP its Future alive. The global
    // voting lock is released only after this Future completes.
    final soundFuture = _playVoteSound();

    Object? voteError;
    StackTrace? voteStack;

    try {
      try {
        final result = await _supabase.rpc(
          'cast_vote',
          params: {
            'p_candidate_id': candidateId,
            'p_division_id': divisionId,
          },
        );

        final updatedVotes =
            result is Map
                ? (result['votes'] as num?)?.toInt()
                : null;

        candidate.votes =
            updatedVotes ?? candidate.votes + 1;
      } catch (rpcError) {
        // Keep voting usable if the existing RPC grant is temporarily
        // unavailable. Realtime will reconcile the row when available.
        final nextVotes = candidate.votes + 1;

        await _supabase
            .from('candidates')
            .update({'votes': nextVotes})
            .eq('id', candidateId)
            .eq('division_id', divisionId);

        candidate.votes = nextVotes;
        debugPrint(
          'cast_vote RPC failed; direct update used: $rpcError',
        );
      }

      await _saveCache();
      notifyListeners();
    } catch (e, st) {
      voteError = e;
      voteStack = st;
      debugPrint('Supabase vote failed: $e');
    }

    // Never re-enable another Vote button before the sound has actually
    // completed. This is the critical part of the fix.
    await soundFuture;

    // Unlock ONLY after the sound Future has completed.
    _isVoting = false;
    notifyListeners();

    if (voteError != null) {
      Error.throwWithStackTrace(
        voteError!,
        voteStack ?? StackTrace.current,
      );
    }
  }

  Future<void> _playVoteSound() async {
    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.release);
      await player.setVolume(1.0);

      // Subscribe BEFORE play() so even a very short beep cannot finish
      // before we start waiting for its completion event.
      final completion = player.onPlayerComplete.first;

      await player.play(
        AssetSource('sounds/vote_beep.wav'),
      );

      await completion;
    } catch (e) {
      debugPrint('Vote sound error: $e');
    } finally {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  /// Reset votes only for one selected election division.
  ///
  /// The control screen resolves the correct division id for HS/UP and HSS
  /// (including configured HSS streams/batches) and passes it here.
  Future<void> resetVotesForDivision(String divisionId) async {
    if (division(divisionId) == null) {
      throw Exception('Selected division was not found.');
    }

    try {
      await _supabase
          .from('candidates')
          .update({'votes': 0})
          .eq('division_id', divisionId);

      for (final candidate in candidates) {
        if (candidate.divisionId == divisionId) {
          candidate.votes = 0;
        }
      }

      await _saveCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Reset votes for division failed: $e');
      rethrow;
    }
  }

  /// Kept for backwards compatibility with older screens.
  /// New control UI should use [resetVotesForDivision].
  Future<void> resetVotes() async {
    try {
      await _supabase.from('candidates').update({'votes': 0}).neq('id', '');
      for (final candidate in candidates) {
        candidate.votes = 0;
      }
      await _saveCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Reset votes failed: $e');
      rethrow;
    }
  }

  String _newId(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  @override
  void dispose() {
    _realtime?.unsubscribe();
    unawaited(player.dispose());
    super.dispose();
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
