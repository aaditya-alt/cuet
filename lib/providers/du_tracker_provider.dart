import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class CsasTimelineEvent {
  final int id;
  final String title;
  final String eventDate; // Display text: "28 May 2026"
  final String? eventTime; // Display text: "11:00 PM"
  final String? description;
  final bool isCompleted;
  final int sortOrder;
  final String category;
  final String iconName;
  final bool isImportant;
  final String? linkUrl;
  final String? linkLabel;
  final bool isActive;
  final DateTime? deadline; // ← NEW: machine-readable countdown target from DB

  CsasTimelineEvent({
    required this.id,
    required this.title,
    required this.eventDate,
    this.eventTime,
    this.description,
    required this.isCompleted,
    required this.sortOrder,
    required this.category,
    required this.iconName,
    required this.isImportant,
    this.linkUrl,
    this.linkLabel,
    required this.isActive,
    this.deadline,
  });

  DateTime get dateTime {
    try {
      final datePart = eventDate.trim();
      final timePart = (eventTime?.trim().isNotEmpty == true)
          ? eventTime!.trim()
          : '23:59:59';
      return DateTime.parse('$datePart $timePart');
    } catch (_) {
      return DateTime(2099); // push unknown dates to the end
    }
  }

  factory CsasTimelineEvent.fromJson(Map<String, dynamic> j) {
    // Parse deadline from DB (stored as ISO 8601 UTC string by Supabase)
    DateTime? deadline;
    final raw = j['deadline'];
    if (raw != null && raw.toString().isNotEmpty) {
      try {
        deadline = DateTime.parse(raw.toString()).toLocal();
      } catch (_) {}
    }

    return CsasTimelineEvent(
      id: j['id'] as int,
      title: j['title'] as String? ?? '',
      eventDate: j['event_date'] as String? ?? '',
      eventTime: j['event_time'] as String?,
      description: j['description'] as String?,
      isCompleted: j['is_completed'] as bool? ?? false,
      sortOrder: j['sort_order'] as int? ?? 0,
      category: j['category'] as String? ?? 'General',
      iconName: j['icon_name'] as String? ?? 'calendar',
      isImportant: j['is_important'] as bool? ?? false,
      linkUrl: j['link_url'] as String?,
      linkLabel: j['link_label'] as String?,
      isActive: j['is_active'] as bool? ?? true,
      deadline: deadline,
    );
  }

  /// Whether this event has a live countdown available.
  bool get hasDeadline => deadline != null;

  /// Whether this event's deadline is in the past.
  bool get isPast => deadline != null && deadline!.isBefore(DateTime.now());

  /// Whether this event is upcoming and has an active countdown.
  bool get isUpcoming => deadline != null && deadline!.isAfter(DateTime.now());

  /// Duration remaining until the deadline. Null if no deadline or already past.
  Duration? get timeRemaining {
    if (deadline == null) return null;
    final diff = deadline!.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
class DuTrackerProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final SupabaseClient _client = Supabase.instance.client;

  Timer? _countdownTimer;

  List<CsasTimelineEvent> _events = [];
  bool isLoading = true;
  String? loadError;

  final Map<String, bool> _taskStates = {};

  DuTrackerProvider(this._prefs) {
    _loadLocalTaskStates();
    fetchTimeline();
    _startCountdownTicker();
  }

  // ── Public getters ─────────────────────────────────────────────────────────

  List<CsasTimelineEvent> get allEvents => _events;
  Map<String, bool> get taskStates => _taskStates;

  /// All active events grouped by category, sorted by sort_order.
  Map<String, List<CsasTimelineEvent>> get eventsByCategory {
    final Map<String, List<CsasTimelineEvent>> map = {};
    for (final e in _events.where((e) => e.isActive)) {
      map.putIfAbsent(e.category, () => []).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return map;
  }

  /// Ordered list of unique active categories.
  List<String> get categories {
    final seen = <String>{};
    return _events
        .where((e) => e.isActive)
        .map((e) => e.category)
        .where(seen.add)
        .toList();
  }

  // ── Per-event deadline helpers ─────────────────────────────────────────────

  /// The NEXT upcoming event that has a deadline (first to expire).
  CsasTimelineEvent? get nextDeadlineEvent {
    final upcoming = _events.where((e) => e.isActive && e.isUpcoming).toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// All events with deadlines, sorted soonest first.
  List<CsasTimelineEvent> get eventsWithDeadlines {
    return _events.where((e) => e.isActive && e.hasDeadline).toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
  }

  /// Upcoming events with deadlines only.
  List<CsasTimelineEvent> get upcomingDeadlines {
    return eventsWithDeadlines.where((e) => e.isUpcoming).toList();
  }

  /// Most urgent deadline per category (used for phase summary cards).
  DateTime? deadlineForCategory(String category) {
    final evs = (eventsByCategory[category] ?? [])
        .where((e) => e.isUpcoming)
        .toList();
    if (evs.isEmpty) return null;
    evs.sort((a, b) => a.deadline!.compareTo(b.deadline!));
    return evs.first.deadline;
  }

  // ── Checklist helpers ──────────────────────────────────────────────────────

  String _taskKey(int eventId) => 'csas_task_event_$eventId';

  void _loadLocalTaskStates() {
    for (final k in _prefs.getKeys()) {
      if (k.startsWith('csas_task_event_')) {
        _taskStates[k] = _prefs.getBool(k) ?? false;
      }
    }
  }

  Future<void> toggleTask(int eventId) async {
    final key = _taskKey(eventId);
    final current = _taskStates[key] ?? false;
    _taskStates[key] = !current;
    await _prefs.setBool(key, !current);
    notifyListeners();
  }

  bool isTaskChecked(int eventId) => _taskStates[_taskKey(eventId)] ?? false;

  double getPhaseProgress(String category) {
    final evs = eventsByCategory[category] ?? [];
    if (evs.isEmpty) return 0.0;
    final checked = evs.where((e) => isTaskChecked(e.id)).length;
    return checked / evs.length;
  }

  // ── Data fetch ─────────────────────────────────────────────────────────────

  Future<void> fetchTimeline() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final res = await _client
          .from('csas_timeline')
          .select()
          .eq('is_active', true)
          .order('sort_order')
          .order('event_date');

      _events = (res as List)
          .map((r) => CsasTimelineEvent.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      loadError = 'Could not load timeline: $e';
      debugPrint('fetchTimeline error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Countdown formatting ───────────────────────────────────────────────────

  /// Human-readable countdown string for any DateTime.
  String countdownString(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Closed';
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (d > 30) return '${d}d left';
    if (d > 0) return '${d}d ${h}h left';
    if (h > 0) return '${h}h ${m}m left';
    if (m > 0) return '${m}m ${s}s left';
    return '${s}s left';
  }

  /// Countdown for a specific event. Returns null if no deadline or closed.
  String? eventCountdownString(CsasTimelineEvent event) {
    if (!event.hasDeadline) return null;
    if (event.isPast) return event.isCompleted ? 'Completed' : 'Closed';
    return countdownString(event.deadline!);
  }

  /// Urgency level for color coding:
  /// 0 = no deadline / closed, 1 = >7 days (green), 2 = 1-7 days (amber), 3 = <24h (red)
  int eventUrgency(CsasTimelineEvent event) {
    if (!event.hasDeadline || event.isPast) return 0;
    final diff = event.deadline!.difference(DateTime.now());
    if (diff.inDays > 7) return 1;
    if (diff.inDays >= 1) return 2;
    return 3;
  }

  // ── Admin: update deadlines ────────────────────────────────────────────────
  // Called from admin panel when saving a timeline event with a deadline.

  Future<bool> updateEventDeadline(int eventId, DateTime deadline) async {
    try {
      await _client
          .from('csas_timeline')
          .update({'deadline': deadline.toUtc().toIso8601String()})
          .eq('id', eventId);
      await fetchTimeline();
      return true;
    } catch (e) {
      debugPrint('updateEventDeadline error: $e');
      return false;
    }
  }

  // ── Countdown ticker ───────────────────────────────────────────────────────

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
