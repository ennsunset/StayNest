import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/features/booking/data/bookings_repository.dart';
import 'package:staynest_mobile/features/booking/data/bookings_provider.dart';
import 'package:staynest_mobile/app/router.dart';

final moveInTasksProvider = FutureProvider.family<List<MoveInTask>, String>((ref, bookingId) {
  return ref.read(bookingsRepositoryProvider).getMoveInTasks(bookingId);
});

class MoveInScheduleScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final DateTime? moveInDate;
  final String? hostelName;

  const MoveInScheduleScreen({
    super.key,
    required this.bookingId,
    this.moveInDate,
    this.hostelName,
  });

  @override
  ConsumerState<MoveInScheduleScreen> createState() => _MoveInScheduleScreenState();
}

class _MoveInScheduleScreenState extends ConsumerState<MoveInScheduleScreen> {
  late DateTime _displayMonth;
  late DateTime _moveIn;
  bool _dateEditable = true;

  @override
  void initState() {
    super.initState();
    _moveIn = widget.moveInDate ?? DateTime.now().add(const Duration(days: 7));
    _displayMonth = DateTime(_moveIn.year, _moveIn.month);
    // Check if booking is CHECKED_IN (date locked)
    ref.read(bookingDetailProvider(widget.bookingId)).whenData((b) {
      if (b.status == 'CHECKED_IN' || b.status == 'COMPLETED') {
        _dateEditable = false;
      }
    });
  }

  Future<void> _pickDate() async {
    if (!_dateEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Move-in date is locked after check-in')),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveIn,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _moveIn) {
      setState(() {
        _moveIn = picked;
        _displayMonth = DateTime(picked.year, picked.month);
      });
      try {
        final repo = ref.read(bookingsRepositoryProvider);
        await repo.updateCheckInDate(
          widget.bookingId,
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Move-in date updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save date: $e')),
          );
        }
      }
    }
  }

  Future<void> _addTask() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Task name')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ADD')),
        ],
      ),
    );
    if (result == true && titleCtrl.text.trim().isNotEmpty) {
      try {
        final repo = ref.read(bookingsRepositoryProvider);
        await repo.addCustomTask(
          widget.bookingId,
          titleCtrl.text.trim(),
          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
        );
        ref.invalidate(moveInTasksProvider(widget.bookingId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final tasksAsync = ref.watch(moveInTasksProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: c.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: c.card,
                border: Border(bottom: BorderSide(color: c.border, width: 1)),
              ),
              child: Row(
                children: [
                  SNCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.canPop() ? context.pop() : context.go('/'),
                  ),
                  const SizedBox(width: 16),
                  Text('ARRIVAL PLAN', style: SNText.headingMd),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // ── Calendar card ──
                  GestureDetector(
                    onTap: _dateEditable ? _pickDate : null,
                    child: _CalendarCard(
                      displayMonth: _displayMonth,
                      moveInDate: _moveIn,
                      editable: _dateEditable,
                      onPrevMonth: () => setState(() {
                        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
                      }),
                      onNextMonth: () => setState(() {
                        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
                      }),
                    ),
                  ),
                  if (_dateEditable)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          'TAP CALENDAR TO CHANGE DATE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.mutedForeground, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                  if (!_dateEditable)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, size: 12, color: c.mutedForeground),
                            const SizedBox(width: 4),
                            Text(
                              'DATE LOCKED AFTER CHECK-IN',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.mutedForeground, letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('YOUR CHECKLIST', style: SNText.sectionLabel),
                  ),
                  const SizedBox(height: 24),

                  tasksAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Failed to load tasks: $e'),
                    data: (tasks) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _ChecklistTimeline(
                        tasks: tasks,
                        bookingId: widget.bookingId,
                        onAction: (route) => context.push(route),
                        onTaskDone: (taskId) async {
                          final repo = ref.read(bookingsRepositoryProvider);
                          await repo.updateMoveInTask(taskId, 'DONE');
                          ref.invalidate(moveInTasksProvider(widget.bookingId));
                        },
                        onDeleteTask: (taskId) async {
                          final repo = ref.read(bookingsRepositoryProvider);
                          await repo.deleteCustomTask(taskId);
                          ref.invalidate(moveInTasksProvider(widget.bookingId));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Calendar Card ───────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime moveInDate;
  final bool editable;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _CalendarCard({
    required this.displayMonth,
    required this.moveInDate,
    required this.editable,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  static const _monthNames = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
  ];
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final year = displayMonth.year;
    final month = displayMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final prevMonthDays = DateTime(year, month, 0).day;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navBtn(c, Icons.arrow_back_rounded, onPrevMonth),
              Text('${_monthNames[month - 1]} $year', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: c.foreground, letterSpacing: 1.5)),
              _navBtn(c, Icons.arrow_forward_rounded, onNextMonth),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayLabels.map((d) => SizedBox(width: 32, child: Center(child: Text(d, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: c.mutedForeground, letterSpacing: -0.5))))).toList(),
          ),
          const SizedBox(height: 16),
          ..._buildWeeks(c, startWeekday, daysInMonth, prevMonthDays, year, month),
        ],
      ),
    );
  }

  Widget _navBtn(dynamic c, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: c.foreground),
      ),
    );
  }

  List<Widget> _buildWeeks(dynamic c, int startWeekday, int daysInMonth, int prevDays, int year, int month) {
    final List<Widget> weeks = [];
    int dayCounter = 1;
    bool done = false;
    for (int week = 0; week < 6 && !done; week++) {
      final List<Widget> cells = [];
      for (int dow = 0; dow < 7; dow++) {
        if (week == 0 && dow < startWeekday) {
          cells.add(_dayCell(c, prevDays - startWeekday + dow + 1, isOverflow: true));
        } else if (dayCounter > daysInMonth) {
          done = true; break;
        } else {
          final isSelected = moveInDate.year == year && moveInDate.month == month && moveInDate.day == dayCounter;
          cells.add(_dayCell(c, dayCounter, isSelected: isSelected));
          dayCounter++;
        }
      }
      if (cells.isNotEmpty) {
        while (cells.length < 7) cells.add(const SizedBox(width: 32, height: 40));
        weeks.add(Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: cells)));
      }
    }
    return weeks;
  }

  Widget _dayCell(dynamic c, int day, {bool isOverflow = false, bool isSelected = false}) {
    return SizedBox(
      width: 32, height: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32, height: 32,
            decoration: isSelected ? BoxDecoration(color: c.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: (c.primary as Color).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]) : null,
            child: Center(child: Text('$day', style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, color: isSelected ? Colors.white : isOverflow ? c.mutedForeground.withOpacity(0.3) : c.foreground))),
          ),
          if (isSelected) Container(width: 4, height: 4, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}

// ─── Checklist Timeline ──────────────────────────────────

class _ChecklistTimeline extends StatelessWidget {
  final List<MoveInTask> tasks;
  final String bookingId;
  final void Function(String route) onAction;
  final void Function(String taskId) onTaskDone;
  final void Function(String taskId) onDeleteTask;

  const _ChecklistTimeline({
    required this.tasks,
    required this.bookingId,
    required this.onAction,
    required this.onTaskDone,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Stack(
      children: [
        Positioned(left: 3, top: 8, bottom: 8, child: Container(width: 1, color: c.border)),
        Column(
          children: tasks.map((task) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dot(c, task.status),
                  const SizedBox(width: 16),
                  Expanded(child: _card(context, c, task)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dot(dynamic c, String status) {
    Color color;
    switch (status) {
      case 'DONE': color = const Color(0xFF22C55E); break;
      case 'CURRENT': color = c.primary; break;
      default: color = c.muted;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
          border: Border.all(color: c.background, width: 2),
          boxShadow: status == 'CURRENT' ? [BoxShadow(color: (c.primary as Color).withOpacity(0.2), blurRadius: 8, spreadRadius: 4)] : null,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, dynamic c, MoveInTask task) {
    final isDone = task.status == 'DONE';
    final isCurrent = task.status == 'CURRENT';
    final opacity = (isDone || task.status == 'PENDING') ? 0.6 : 1.0;

    String fmtDate(DateTime? dt) {
      if (dt == null) return '';
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return 'Completed ${months[dt.month - 1]} ${dt.day}';
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: EdgeInsets.all(isCurrent ? 20 : 16),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: isCurrent ? c.primary : c.border, width: isCurrent ? 2 : 1),
          borderRadius: BorderRadius.circular(isCurrent ? 24 : 16),
          boxShadow: isCurrent ? [BoxShadow(color: (c.primary as Color).withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(task.title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: c.foreground, letterSpacing: 1.2, decoration: isDone ? TextDecoration.lineThrough : null))),
                if (isCurrent) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(4)),
                  child: const Text('CURRENT TASK', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                ),
                if (task.custom && !isDone)
                  GestureDetector(
                    onTap: () => onDeleteTask(task.id),
                    child: Icon(Icons.close_rounded, size: 16, color: c.mutedForeground),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (isDone)
              Text(fmtDate(task.completedAt).toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.mutedForeground, letterSpacing: 1.5)),
            if (!isDone && task.description != null)
              Text(task.description!.toUpperCase(), style: TextStyle(fontSize: isCurrent ? 10 : 9, fontWeight: FontWeight.w700, color: c.mutedForeground, letterSpacing: 1.5, height: 1.5)),
            // Assignee badge
            if (!isDone)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: task.assignee == 'STUDENT' ? c.primary.withOpacity(0.1) : c.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.assignee == 'STUDENT' ? 'YOUR TASK' : 'OWNER CLEARS',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: task.assignee == 'STUDENT' ? c.primary : c.mutedForeground, letterSpacing: 1),
                  ),
                ),
              ),
            // Action button for student-clearable current tasks
            if (isCurrent && task.assignee == 'STUDENT') ...[
              const SizedBox(height: 16),
              if (task.title.contains('Key'))
                GestureDetector(
                  onTap: () => onAction('/qr-checkin'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: const Color(0xFF1C2B41), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('GET QR PASS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5))),
                  ),
                ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => onTaskDone(task.id),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('MARK COMPLETE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
