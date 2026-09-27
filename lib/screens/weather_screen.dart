import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/weather_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Weather & Heat Stress'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: '16-Day'),
            Tab(text: 'Compare'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildTodayTab(), _buildForecastTab(), _buildCompareTab()],
            ),
    );
  }

  // ── TODAY TAB ──
  Widget _buildTodayTab() {
    if (_current == null) return const Center(child: Text('Weather data unavailable'));
    final w = _current!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Current conditions card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: w.isHeatStress
                  ? [Colors.orange.shade600, Colors.red.shade400]
                  : [Colors.blue.shade500, Colors.cyan.shade300],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            Text(w.icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text('${w.temperature.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(w.condition, style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.location_on, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(_locationName, style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _miniStat('💨 Wind', '${w.windSpeed.toStringAsFixed(0)} km/h'),
              _miniStat('💧 Humidity', '${w.humidity}%'),
              _miniStat('🔥 Heat', w.heatStressLevel),
            ]),
            if (w.isHeatStress) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('⚠️ Heat Stress ${w.heatStressLevel}! Ensure shade, water & ventilation for cattle.', style: TextStyle(color: Theme.of(context).cardColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        // Hourly chart
        if (w.hourlyTemperatures.isNotEmpty) _buildHourlyChart(w),
      ]),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }

  Widget _buildHourlyChart(WeatherData w) {
    final currentHour = DateTime.now().hour;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('24-Hour Temperature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('Min ${w.hourlyTemperatures.reduce((a, b) => a < b ? a : b).toStringAsFixed(0)}° / Max ${w.hourlyTemperatures.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}°', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: LineChart(LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5, getDrawingHorizontalLine: (_) => FlLine(color: Theme.of(context).cardColor, strokeWidth: 1)),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 5, getTitlesWidget: (v, _) => Text('${v.toInt()}°', style: TextStyle(fontSize: 10, color: Theme.of(context).cardColor)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 4, getTitlesWidget: (v, _) {
                final h = v.toInt();
                if (h >= 0 && h <= 23 && h % 4 == 0) return Text('${h.toString().padLeft(2, '0')}h', style: TextStyle(fontSize: 9, color: Theme.of(context).cardColor));
                return const Text('');
              })),
            ),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(verticalLines: [
              VerticalLine(x: currentHour.toDouble(), color: AppConstants.primaryColor.withOpacity(0.5), strokeWidth: 2, dashArray: [4, 4],
                label: VerticalLineLabel(show: true, labelResolver: (_) => 'Now', style: TextStyle(fontSize: 9, color: AppConstants.primaryColor, fontWeight: FontWeight.bold))),
            ], horizontalLines: [
              if (w.hourlyTemperatures.any((t) => t >= 30))
                HorizontalLine(y: 30, color: Colors.red.withOpacity(0.3), strokeWidth: 1, dashArray: [6, 4],
                  label: HorizontalLineLabel(show: true, labelResolver: (_) => '30°C Heat', style: const TextStyle(fontSize: 8, color: Colors.red), alignment: Alignment.topRight)),
            ]),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(currentHour + 1, (i) => FlSpot(i.toDouble(), w.hourlyTemperatures[i])),
                isCurved: true, color: AppConstants.primaryColor, barWidth: 3, dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppConstants.primaryColor.withOpacity(0.08)),
              ),
              if (currentHour < 23)
                LineChartBarData(
                  spots: List.generate(24 - currentHour, (i) { final h = currentHour + i; return FlSpot(h.toDouble(), w.hourlyTemperatures[h]); }),
                  isCurved: true, color: Colors.grey.shade400, barWidth: 2, dotData: FlDotData(show: false), dashArray: [6, 4],
                ),
            ],
          )),
        ),
      ]),
    );
  }

  // ── 16-DAY FORECAST TAB ──
  Widget _buildForecastTab() {
    if (_forecast.isEmpty) return const Center(child: Text('Forecast unavailable'));
    return Column(children: [
      // Temperature range chart
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('16-Day Temperature Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 5, getTitlesWidget: (v, _) => Text('${v.toInt()}°', style: TextStyle(fontSize: 9, color: Theme.of(context).cardColor)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 3, getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= 0 && idx < _forecast.length && idx % 3 == 0) return Text(DateFormat('d/M').format(_forecast[idx].date), style: TextStyle(fontSize: 8, color: Theme.of(context).cardColor));
                  return const Text('');
                })),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(spots: _forecast.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.maxTemp)).toList(), isCurved: true, color: Colors.red.shade400, barWidth: 2, dotData: FlDotData(show: false)),
                LineChartBarData(spots: _forecast.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.minTemp)).toList(), isCurved: true, color: Colors.blue.shade400, barWidth: 2, dotData: FlDotData(show: false)),
              ],
            )),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 10, height: 3, color: Colors.red.shade400), const SizedBox(width: 4), Text('Max', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(width: 16),
            Container(width: 10, height: 3, color: Colors.blue.shade400), const SizedBox(width: 4), Text('Min', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ]),
        ]),
      ),
      // Daily forecast list
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _forecast.length,
          itemBuilder: (ctx, i) => _buildDayCard(_forecast[i], i == 0),
        ),
      ),
    ]);
  }

  Widget _buildDayCard(DailyForecast d, bool isToday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isToday ? AppConstants.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isToday ? AppConstants.primaryColor.withOpacity(0.3) : Colors.grey.shade100),
      ),
      child: Row(children: [
        SizedBox(width: 50, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isToday ? 'Today' : DateFormat('EEE').format(d.date), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isToday ? AppConstants.primaryColor : Colors.black87)),
          Text(DateFormat('d MMM').format(d.date), style: TextStyle(fontSize: 10, color: Theme.of(context).cardColor)),
        ])),
        const SizedBox(width: 8),
        Text(d.icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.condition, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          if (d.precipProbability > 0) Text('🌧 ${d.precipProbability}% rain', style: TextStyle(fontSize: 10, color: Colors.blue.shade600)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${d.maxTemp.toStringAsFixed(0)}°', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: d.isHeatStress ? Colors.red : Colors.black87)),
          Text('${d.minTemp.toStringAsFixed(0)}°', style: TextStyle(fontSize: 13, color: Colors.blue.shade400)),
        ]),
        if (d.isHeatStress) ...[
          const SizedBox(width: 8),
          const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
        ],
      ]),
    );
  }

  // ── COMPARE TAB (Multi-Model) ──
  Widget _buildCompareTab() {
    if (_multiModel.isEmpty) return const Center(child: Text('Loading models...'));

    final models = _multiModel.entries.toList();
    final colors = [Colors.teal, Colors.orange, Colors.purple, Colors.indigo];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Comparing 3 weather models to verify accuracy. If forecasts agree, confidence is high.', style: TextStyle(fontSize: 11, color: Colors.blue.shade800))),
          ]),
        ),
        const SizedBox(height: 16),
        // Max temp comparison chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Max Temperature Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 5, getTitlesWidget: (v, _) => Text('${v.toInt()}°', style: TextStyle(fontSize: 9, color: Theme.of(context).cardColor)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 3, getTitlesWidget: (v, _) {
                    final bestMatch = _multiModel['Best Match'] ?? [];
                    final idx = v.toInt();
                    if (idx >= 0 && idx < bestMatch.length && idx % 3 == 0) return Text(DateFormat('d/M').format(bestMatch[idx].date), style: TextStyle(fontSize: 8, color: Theme.of(context).cardColor));
                    return const Text('');
                  })),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: List.generate(models.length, (mi) {
                  final data = models[mi].value;
                  return LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.maxTemp)).toList(),
                    isCurved: true, color: colors[mi], barWidth: 2, dotData: FlDotData(show: false),
                  );
                }),
              )),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 16, children: List.generate(models.length, (i) => Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 3, color: colors[i]), const SizedBox(width: 4),
              Text(models[i].key, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            ]))),
          ]),
        ),
        const SizedBox(height: 16),
        // Day-by-day comparison table
        const Text('Day-by-Day Model Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
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
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${DateFormat('EEE, MMM d').format(bm.date)} ${bm.icon}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            _modelChip('Best', bm.maxTemp, bm.minTemp, Colors.teal),
            if (g != null) const SizedBox(width: 4),
            if (g != null) _modelChip('GFS', g.maxTemp, g.minTemp, Colors.orange),
            if (e != null) const SizedBox(width: 4),
            if (e != null) _modelChip('ECMWF', e.maxTemp, e.minTemp, Colors.purple),
            if (o != null) const SizedBox(width: 4),
            if (o != null) _modelChip('OWM', o.maxTemp, o.minTemp, Colors.indigo),
          ]),
        ]),
      );
    });
  }

  Widget _modelChip(String model, double max, double min, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text(model, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
          Text('${max.toStringAsFixed(0)}°/${min.toStringAsFixed(0)}°', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
