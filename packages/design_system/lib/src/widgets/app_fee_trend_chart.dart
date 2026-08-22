import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';
import '../utils/krw_formatter.dart';

/// 요금 추이 그래프 한 칸 — [amountKrw]가 null이면 "데이터 없음"으로,
/// 시간축에는 그대로 남지만 선은 이 지점에서 끊긴다(PHASE 37 §2/§10:
/// "데이터가 없는 월은 0으로 억지 계산하지 말고... 시간축 자체는 정상적으로
/// 유지").
class FeeChartPoint {
  const FeeChartPoint({
    required this.label,
    required this.amountKrw,
    this.detail,
  });

  /// x축 라벨 (예: "1월", "2024").
  final String label;

  final int? amountKrw;

  /// 이 칸을 선택했을 때 보여줄 부가 설명 (건수 등). 그래프 자체에는
  /// 렌더링하지 않고, [AppFeeTrendChart.onSelect]로 화면에 전달만 한다.
  final String? detail;

  bool get hasData => amountKrw != null;
}

/// 요금 월별/연별 추이 선 그래프 (PHASE 37 §10). 접근성 원칙을 그대로
/// 반영한다:
/// - 그래프만으로 정보를 전달하지 않도록 [Semantics]에 전체 요약 문장을 담고,
///   호출자가 숫자 요약(카드/리스트)을 별도로 함께 제공하는 것을 전제한다.
/// - 데이터 1건만 있어도, 전부 없어도 깨지지 않는다.
/// - 매우 큰 금액도 [formatKrwCompact]로 축 라벨 overflow를 막는다.
/// - 특정 지점 탭 시 [onSelect]로 색상 변화 없이(선택 마커로) 알린다 — 정보
///   전달을 색상에만 의존하지 않는다.
class AppFeeTrendChart extends StatelessWidget {
  const AppFeeTrendChart({
    super.key,
    required this.points,
    this.selectedIndex,
    this.onSelect,
    this.height = 220,
  });

  final List<FeeChartPoint> points;
  final int? selectedIndex;
  final ValueChanged<int>? onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasAnyData = points.any((p) => p.hasData);

    final semanticLabel = hasAnyData
        ? '요금 추이 그래프. ${points.where((p) => p.hasData).map((p) => '${p.label} ${formatKrw(p.amountKrw!)}').join(', ')}'
        : '요금 추이 그래프. 아직 데이터가 없습니다.';

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: hasAnyData ? _buildChart(context) : _buildEmpty(context),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Text(
        '아직 요금 통계가 없습니다.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final dataAmounts = points
        .where((p) => p.hasData)
        .map((p) => p.amountKrw!)
        .toList();
    final maxY = dataAmounts.reduce((a, b) => a > b ? a : b).toDouble();
    final minY = dataAmounts.reduce((a, b) => a < b ? a : b).toDouble();
    // 데이터가 1건뿐이거나 전부 동일 금액이면 minY==maxY가 되어 fl_chart가
    // 축을 그리지 못한다 — 위아래 여백을 인위적으로 벌려 항상 그릴 수 있게
    // 한다(PHASE 37 §10 "단일 데이터만 있는 경우에도 정상 표시").
    final padding = (maxY - minY) == 0
        ? (maxY == 0 ? 1.0 : maxY * 0.2)
        : (maxY - minY) * 0.15;
    final chartMinY = (minY - padding).clamp(0, double.infinity).toDouble();
    final chartMaxY = maxY + padding;
    // fl_chart는 interval을 지정하지 않으면 자동 간격 눈금과는 별개로
    // 축의 min/max 경계에도 항상 라벨을 강제로 그린다 — 경계값이 자동
    // 간격의 배수와 어긋나면(흔한 경우) 두 라벨이 겹쳐 실기기에서 텍스트가
    // 뭉개진다(PHASE 38 실기기 검증에서 발견). interval을 명시하면
    // fl_chart가 그 간격의 배수로만 라벨을 생성해 경계 중복을 피한다.
    final yInterval = (chartMaxY - chartMinY) / 4;

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        if (points[i].hasData)
          FlSpot(i.toDouble(), points[i].amountKrw!.toDouble()),
    ];

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.sm),
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          minX: 0,
          maxX: (points.length - 1).clamp(0, double.infinity).toDouble(),
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: yInterval,
                getTitlesWidget: (value, meta) => Text(
                  formatKrwCompact(value.round()),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      points[index].label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: onSelect != null,
            touchCallback: onSelect == null
                ? null
                : (event, response) {
                    if (event is! FlTapUpEvent) return;
                    final spots = response?.lineBarSpots;
                    if (spots == null || spots.isEmpty) return;
                    onSelect!(spots.first.x.round());
                  },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (spot, percent, bar, index) {
                  final isSelected = selectedIndex == spot.x.round();
                  return FlDotCirclePainter(
                    radius: isSelected ? 6 : 4,
                    color: AppColors.primary,
                    strokeWidth: isSelected ? 2 : 0,
                    strokeColor: AppColors.textPrimary,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
