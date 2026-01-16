import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import '../models/timetable_entry.dart';
import '../services/storage_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<TimetableEntry> _entries = [];
  int _selectedDay = DateTime.now().weekday;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await StorageService.loadTimetable();
    setState(() {
      _entries = raw
          .map((e) => TimetableEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  Future<void> _persist() async {
    await StorageService.saveTimetable(
        _entries.map((e) => e.toJson()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todays = _entries.where((e) => e.weekday == _selectedDay).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "Timetable",
          style: TextStyle(
              color: isDark ? AppColors.textDarkMode : Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          _dayChips(isDark),

          // Add button moved below the days bar
          _addButton(isDark),

          Expanded(
            child: todays.isEmpty
                ? Center(
                    child: Text(
                      "No classes added for this day.",
                      style: TextStyle(
                        color:
                            isDark ? AppColors.textLightDark : Colors.black54,
                      ),
                    ),
                  )
                : _list(todays, isDark),
          ),
        ],
      ),
    );
  }

  //------------------- DAY CHIPS ---------------------
  Widget _dayChips(bool isDark) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final day = i + 1;
          final sel = _selectedDay == day;

          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                // Selected: filled with pastel lavender, Unselected: outlined
                color: sel
                    ? (isDark
                        ? AppColors.mauveDark
                        : const Color(0xFFE8D4F0)) // pastel lavender
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel
                      ? (isDark
                          ? AppColors.mauveDark
                          : const Color(0xFFD4A5E0)) // lavender border
                      : (isDark
                          ? AppColors.textLightDark.withAlpha(102)
                          : AppColors.salmon.withAlpha(128)),
                  width: sel ? 2 : 1.5,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: (isDark
                                  ? AppColors.mauveDark
                                  : const Color(0xFFE8D4F0))
                              .withAlpha(102),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _dayName(day),
                  style: TextStyle(
                    color: sel
                        ? (isDark
                            ? Colors.white
                            : const Color(
                                0xFF6B3A7D)) // dark purple text when selected
                        : (isDark ? AppColors.textLightDark : Colors.black54),
                    fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: 7,
      ),
    );
  }

  //------------------- CLASS LIST ---------------------
  Widget _list(List<TimetableEntry> list, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final e = list[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.salmon).withAlpha(51),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: (isDark ? Colors.black : Colors.black).withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            color: isDark
                ? AppColors.cardDark.withAlpha(230)
                : Colors.white.withAlpha(230),
            elevation: 0,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(
                e.subject,
                style: TextStyle(
                  color: isDark ? AppColors.textDarkMode : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "${e.startTime} - ${e.endTime}"
                " • ${e.teacher.isEmpty ? 'Teacher' : e.teacher}"
                "${e.room.isEmpty ? '' : ' • Room ${e.room}'}",
                style: TextStyle(
                  color: isDark ? AppColors.textLightDark : Colors.black54,
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _edit(e);
                  if (v == 'delete') _delete(e);
                },
                color: isDark ? AppColors.cardDark : Colors.white,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      "Edit",
                      style: TextStyle(
                          color:
                              isDark ? AppColors.textDarkMode : Colors.black87),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      "Delete",
                      style: TextStyle(
                          color:
                              isDark ? AppColors.textDarkMode : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //------------------- ADD BUTTON ---------------------
  Widget _addButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.salmonDark : AppColors.salmon)
                  .withAlpha(102),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 20),
            label: const Text("Add Class"),
            onPressed: () => _edit(),
          ),
        ),
      ),
    );
  }

  //------------------- ADD / EDIT POPUP ---------------------
  void _edit([TimetableEntry? entry]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subject = TextEditingController(text: entry?.subject ?? "");
    final teacher = TextEditingController(text: entry?.teacher ?? "");
    final room = TextEditingController(text: entry?.room ?? "");
    final start = TextEditingController(text: entry?.startTime ?? "");
    final end = TextEditingController(text: entry?.endTime ?? "");
    int day = entry?.weekday ?? _selectedDay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 18,
          right: 18,
          top: 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              initialValue: day,
              decoration: InputDecoration(
                labelText: "Day",
                labelStyle: TextStyle(
                    color: isDark ? AppColors.textLightDark : Colors.black54),
              ),
              dropdownColor: isDark ? AppColors.cardDark : Colors.white,
              style: TextStyle(
                  color: isDark ? AppColors.textDarkMode : Colors.black87),
              items: List.generate(7, (i) {
                final d = i + 1;
                return DropdownMenuItem(
                  value: d,
                  child: Text(_dayName(d)),
                );
              }),
              onChanged: (v) => day = v!,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: "Subject",
                labelStyle: TextStyle(
                    color: isDark ? AppColors.textLightDark : Colors.black54),
              ),
              style: TextStyle(
                  color: isDark ? AppColors.textDarkMode : Colors.black87),
              controller: subject,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: "Teacher",
                labelStyle: TextStyle(
                    color: isDark ? AppColors.textLightDark : Colors.black54),
              ),
              style: TextStyle(
                  color: isDark ? AppColors.textDarkMode : Colors.black87),
              controller: teacher,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: "Room",
                labelStyle: TextStyle(
                    color: isDark ? AppColors.textLightDark : Colors.black54),
              ),
              style: TextStyle(
                  color: isDark ? AppColors.textDarkMode : Colors.black87),
              controller: room,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Start",
                      labelStyle: TextStyle(
                          color: isDark
                              ? AppColors.textLightDark
                              : Colors.black54),
                    ),
                    style: TextStyle(
                        color:
                            isDark ? AppColors.textDarkMode : Colors.black87),
                    controller: start,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "End",
                      labelStyle: TextStyle(
                          color: isDark
                              ? AppColors.textLightDark
                              : Colors.black54),
                    ),
                    style: TextStyle(
                        color:
                            isDark ? AppColors.textDarkMode : Colors.black87),
                    controller: end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text(entry == null ? "Add" : "Save"),
                onPressed: () {
                  final newEntry = TimetableEntry(
                    id: entry?.id ?? const Uuid().v4(),
                    subject: subject.text.trim(),
                    teacher: teacher.text.trim(),
                    room: room.text.trim(),
                    weekday: day,
                    startTime: start.text.trim(),
                    endTime: end.text.trim(),
                  );

                  setState(() {
                    if (entry == null) {
                      _entries.add(newEntry);
                    } else {
                      final i = _entries.indexWhere((x) => x.id == entry.id);
                      _entries[i] = newEntry;
                    }
                  });

                  _persist();
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  //------------------- DELETE ---------------------
  void _delete(TimetableEntry e) {
    setState(() => _entries.removeWhere((x) => x.id == e.id));
    _persist();
  }

  String _dayName(int d) =>
      const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][d - 1];
}
