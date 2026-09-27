import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/weather_service.dart';
import '../widgets/app_ui.dart';
import '../widgets/premium_loading.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  final WeatherService _ws = WeatherService();
  late TabController _tabController;
  WeatherData? _current;
  List<DailyForecast> _forecast = [];
  Map<String, List<DailyForecast>> _multiModel = {};
  bool _isLoading = true;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final loc = await _ws.getSavedLocation();
    _locationName = loc['name'] as String;
    final results = await Future.wait([
      _ws.getCurrentWeather(),
      _ws.getDailyForecast(days: 16),
      _ws.getMultiModelForecast(),
    ]);
    if (mounted) {
      setState(() {
        _current = results[0] as WeatherData?;
        _forecast = results[1] as List<DailyForecast>;
        _multiModel = results[2] as Map<String, List<DailyForecast>>;
        _isLoading = false;
      });
    }
  }

  static const Color _maxColor = AppConstants.dangerColor;
  static const Color _minColor = AppConstants.infoColor;
  static const List<Color> _modelColors = [AppConstants.primaryColor, Color(0xFFB45309), Color(0xFF1D4ED8), Color(0xFF64748B)];

  Widget _axisLabel(String text) => Text(text, style: TextStyle(fontSize: 9, color: context.mutedText));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather & heat stress'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: context.mutedText,
          indicatorColor: AppConstants.primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: '16 days'),
            Tab(text: 'Compare'),
          ],
        ),
      ),
      body: _isLoading
          ? const PremiumLoading(message: 'Loading weather…')
          : TabBarView(
              controller: _tabController,
              children: [_buildTodayTab(), _buildForecastTab(), _buildCompareTab()],
            ),
    );
  }

  // ── TODAY TAB ──
  Widget _buildTodayTab() {
    if (_current == null) return const EmptyState(icon: Icons.cloud_off_outlined, title: 'Weather data unavailable', message: 'Check your connection or location in Settings.');
    final w = _current!;
    final heatColor = w.temperature >= 35 ? AppConstants.dangerColor : AppConstants.warningColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Current conditions card
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.location_on_outlined, size: 16, color: context.mutedText),
              const SizedBox(width: 4),
              Expanded(child: Text(_locationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.mutedText))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              IconTile(weatherIcon(w.weatherCode), size: 52),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${w.temperature.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.1)),
                  Text(w.condition, style: TextStyle(fontSize: 15, color: context.mutedText)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(children: [
              _miniStat(Icons.air, 'Wind', '${w.windSpeed.toStringAsFixed(0)} km/h'),
              _miniStat(Icons.water_drop_outlined, 'Humidity', '${w.humidity}%'),
              _miniStat(Icons.thermostat_outlined, 'Heat stress', w.heatStressLevel),
            ]),
          ]),
        ),
        if (w.isHeatStress) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: heatColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(color: heatColor.withOpacity(0.3)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.warning_amber_rounded, color: heatColor, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Heat stress ${w.heatStressLevel.toLowerCase()}. Ensure shade, water and ventilation for cattle.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, height: 1.4))),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        // Hourly chart
        if (w.hourlyTemperatures.isNotEmpty) _buildHourlyChart(w),
      ]),
    );
  }

  Widget _miniStat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: context.mutedText),
          const SizedBox(width: 4),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.mutedText, fontSize: 12))),
        ]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  Widget _buildHourlyChart(WeatherData w) {
    final currentHour = DateTime.now().hour;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Next 24 hours', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text('Min ${w.hourlyTemperatures.reduce((a, b) => a < b ? a : b).toStringAsFixed(0)}° · Max ${w.hourlyTemperatures.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}°', style: TextStyle(fontSize: 12, color: context.mutedText)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: LineChart(LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5, getDrawingHorizontalLine: (_) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1)),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 5, getTitlesWidget: (v, _) => _axisLabel('${v.toInt()}°'))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 4, getTitlesWidget: (v, _) {
                final h = v.toInt();
                if (h >= 0 && h <= 23 && h % 4 == 0) return _axisLabel('${h.toString().padLeft(2, '0')}h');
                return const Text('');
              })),
            ),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(verticalLines: [
              VerticalLine(x: currentHour.toDouble(), color: AppConstants.primaryColor.withOpacity(0.5), strokeWidth: 1.5, dashArray: [4, 4],
                label: VerticalLineLabel(show: true, labelResolver: (_) => 'Now', style: const TextStyle(fontSize: 9, color: AppConstants.primaryColor, fontWeight: FontWeight.w600))),
            ], horizontalLines: [
              if (w.hourlyTemperatures.any((t) => t >= 30))
                HorizontalLine(y: 30, color: AppConstants.dangerColor.withOpacity(0.35), strokeWidth: 1, dashArray: [6, 4],
                  label: HorizontalLineLabel(show: true, labelResolver: (_) => '30°C heat', style: const TextStyle(fontSize: 9, color: AppConstants.dangerColor), alignment: Alignment.topRight)),
            ]),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(currentHour + 1, (i) => FlSpot(i.toDouble(), w.hourlyTemperatures[i])),
                isCurved: true, color: AppConstants.primaryColor, barWidth: 2, dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppConstants.primaryColor.withOpacity(0.06)),
              ),
              if (currentHour < 23)
                LineChartBarData(
                  spots: List.generate(24 - currentHour, (i) { final h = currentHour + i; return FlSpot(h.toDouble(), w.hourlyTemperatures[h]); }),
                  isCurved: true, color: context.subtleText, barWidth: 2, dotData: FlDotData(show: false), dashArray: [6, 4],
                ),
            ],
          )),
        ),
      ]),
    );
  }

  Widget _legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: context.mutedText)),
      ]);

  // ── 16-DAY FORECAST TAB ──
  Widget _buildForecastTab() {
    if (_forecast.isEmpty) return const EmptyState(icon: Icons.cloud_off_outlined, title: 'Forecast unavailable');
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      itemCount: _forecast.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          // Temperature range chart
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Temperature range · 16 days', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: LineChart(LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 5, getTitlesWidget: (v, _) => _axisLabel('${v.toInt()}°'))),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 3, getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= 0 && idx < _forecast.length && idx % 3 == 0) return _axisLabel(DateFormat('d/M').format(_forecast[idx].date));
                        return const Text('');
                      })),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(spots: _forecast.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.maxTemp)).toList(), isCurved: true, color: _maxColor, barWidth: 2, dotData: FlDotData(show: false)),
                      LineChartBarData(spots: _forecast.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.minTemp)).toList(), isCurved: true, color: _minColor, barWidth: 2, dotData: FlDotData(show: false)),
                    ],
                  )),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _legend(_maxColor, 'Max'),
                  const SizedBox(width: 16),
                  _legend(_minColor, 'Min'),
                ]),
              ]),
            ),
          );
        }
        return _buildDayCard(_forecast[i - 1], i == 1);
      },
    );
  }

  Widget _buildDayCard(DailyForecast d, bool isToday) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderColor: isToday ? AppConstants.primaryColor.withOpacity(0.4) : null,
        child: Row(children: [
          SizedBox(width: 56, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isToday ? 'Today' : DateFormat('EEE').format(d.date), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isToday ? AppConstants.primaryColor : Theme.of(context).colorScheme.onSurface)),
            Text(DateFormat('d MMM').format(d.date), style: TextStyle(fontSize: 11, color: context.mutedText)),
          ])),
          const SizedBox(width: 8),
          Icon(weatherIcon(d.weatherCode), size: 24, color: context.mutedText),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.condition, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            if (d.precipProbability > 0) Text('${d.precipProbability}% chance of rain', style: TextStyle(fontSize: 11, color: context.mutedText)),
          ])),
          if (d.isHeatStress) ...[
            const Icon(Icons.warning_amber_rounded, color: AppConstants.warningColor, size: 16),
            const SizedBox(width: 8),
          ],
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${d.maxTemp.toStringAsFixed(0)}°', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: d.isHeatStress ? AppConstants.dangerColor : Theme.of(context).colorScheme.onSurface)),
            Text('${d.minTemp.toStringAsFixed(0)}°', style: TextStyle(fontSize: 13, color: context.mutedText)),
          ]),
        ]),
      ),
    );
  }

  // ── COMPARE TAB (Multi-Model) ──
  Widget _buildCompareTab() {
    if (_multiModel.isEmpty) return const PremiumLoading(message: 'Loading models…');

    final models = _multiModel.entries.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.infoColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppConstants.infoColor.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppConstants.infoColor, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Comparing weather models. When forecasts agree, confidence is high.', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)))),
          ]),
        ),
        const SizedBox(height: 12),
        // Max temp comparison chart
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Max temperature by model', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 5, getTitlesWidget: (v, _) => _axisLabel('${v.toInt()}°'))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 3, getTitlesWidget: (v, _) {
                    final bestMatch = _multiModel['Best Match'] ?? [];
                    final idx = v.toInt();
                    if (idx >= 0 && idx < bestMatch.length && idx % 3 == 0) return _axisLabel(DateFormat('d/M').format(bestMatch[idx].date));
                    return const Text('');
                  })),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: List.generate(models.length, (mi) {
                  final data = models[mi].value;
                  return LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.maxTemp)).toList(),
                    isCurved: true, color: _modelColors[mi % _modelColors.length], barWidth: 2, dotData: FlDotData(show: false),
                  );
                }),
              )),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 8, children: List.generate(models.length, (i) => _legend(_modelColors[i % _modelColors.length], models[i].key))),
          ]),
        ),
        const SizedBox(height: AppConstants.sectionGap),
        // Day-by-day comparison table
        const SectionHeader('Day by day'),
        ..._buildComparisonCards(),
      ]),
    );
  }

  List<Widget> _buildComparisonCards() {
    final bestMatch = _multiModel['Best Match'] ?? [];
    final gfs = _multiModel['GFS (US/NOAA)'] ?? [];
    final ecmwf = _multiModel['ECMWF (Europe)'] ?? [];
    final owm = _multiModel['OpenWeather'] ?? [];
    final maxDays = bestMatch.length;

    return List.generate(maxDays > 10 ? 10 : maxDays, (i) {
      final bm = bestMatch[i];
      final g = i < gfs.length ? gfs[i] : null;
      final e = i < ecmwf.length ? ecmwf[i] : null;
      final o = i < owm.length ? owm[i] : null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(weatherIcon(bm.weatherCode), size: 16, color: context.mutedText),
              const SizedBox(width: 6),
              Text(DateFormat('EEE, MMM d').format(bm.date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _modelChip('Best', bm.maxTemp, bm.minTemp),
              if (g != null) const SizedBox(width: 6),
              if (g != null) _modelChip('GFS', g.maxTemp, g.minTemp),
              if (e != null) const SizedBox(width: 6),
              if (e != null) _modelChip('ECMWF', e.maxTemp, e.minTemp),
              if (o != null) const SizedBox(width: 6),
              if (o != null) _modelChip('OWM', o.maxTemp, o.minTemp),
            ]),
          ]),
        ),
      );
    });
  }

  Widget _modelChip(String model, double max, double min) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(children: [
          Text(model, style: TextStyle(fontSize: 10, color: context.mutedText)),
          const SizedBox(height: 2),
          Text('${max.toStringAsFixed(0)}° / ${min.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

