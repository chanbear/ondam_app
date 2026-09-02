import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/l10n/failure_l10n.dart';
import '../../../../core/voice_guide/voice_guide_scaffold.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/schedule_notifier.dart';

/// 새 일정 추가 화면 — 제목 + 날짜/시간 + 매일 반복 여부만 입력받는다(범용
/// 일정 + 복약처럼 단순한 매일 반복만 지원, RRULE 같은 복잡한 반복 규칙은
/// 없음). 날짜/시간 선택은 플랫폼 기본 `showDatePicker`/`showTimePicker`를
/// 그대로 쓴다 — 디자인 시스템에 커스텀 피커가 없고, 새로 만들 이유도 없다.
/// 반복을 켜도 시각을 다시 묻지 않는다 — 이미 고른 시간이 매일 반복될
/// 시각이 된다(`Schedule.recurrenceHour`/`recurrenceMinute` 문서 참고).
class ScheduleFormPage extends ConsumerStatefulWidget {
  const ScheduleFormPage({super.key});

  @override
  ConsumerState<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends ConsumerState<ScheduleFormPage> {
  final _titleController = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _isRecurring = false;

  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() => _time = picked);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });

    final scheduledAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final result = await ref
        .read(scheduleListProvider.notifier)
        .create(
          title: _titleController.text,
          scheduledAt: scheduledAt,
          isRecurring: _isRecurring,
          recurrenceHour: _isRecurring ? _time.hour : null,
          recurrenceMinute: _isRecurring ? _time.minute : null,
        );
    if (!mounted) return;

    switch (result) {
      case Ok():
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() {
          _saving = false;
          _saveError = localizeFailureMessage(context, failure.message);
        });
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return VoiceGuideScaffold(
      title: l10n.scheduleAddTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: l10n.scheduleTitleFieldLabel,
            controller: _titleController,
            hintText: l10n.scheduleTitleHint,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppSectionHeader(title: l10n.dateLabel),
          AppCard(
            onTap: _pickDate,
            child: AppInfoRow(
              label: l10n.selectedDateLabel,
              value: _formatDate(_date),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionHeader(title: l10n.timeLabel),
          AppCard(
            onTap: _pickTime,
            child: AppInfoRow(
              label: l10n.selectedTimeLabel,
              value: _formatTime(_time),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.scheduleRecurringLabel,
              style: AppTextStyles.bodyLarge,
            ),
            subtitle: Text(
              l10n.scheduleRecurringDesc,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            value: _isRecurring,
            onChanged: (value) => setState(() => _isRecurring = value),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: l10n.saveButton,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
          if (_saveError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _saveError!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
