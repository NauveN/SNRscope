import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../modelos/Senal.dart';

class GraficoEspectro extends StatelessWidget {
  final List<Senal> senales;
  final List<double> ruido;
  final double frecuenciaMin;
  final double frecuenciaMax;

  const GraficoEspectro({
    super.key,
    required this.senales,
    required this.ruido,
    required this.frecuenciaMin,
    required this.frecuenciaMax,
  });

  @override
  Widget build(BuildContext context) {
    final int ruidoLen = ruido.length;
    if (ruidoLen < 2) {
      return const Center(child: Text('No hay datos de ruido suficientes'));
    }

    // --- Rango extendido para mostrar todo ---
    double rangoExtendido = (frecuenciaMax - frecuenciaMin) * 2.5;
    double xStart = frecuenciaMin - rangoExtendido / 2;
    double xEnd = frecuenciaMax + rangoExtendido / 2;

    int totalPoints = 2000;

    // --- Generar piso de ruido extendido (aleatorio en todo el rango) ---
    double promedio = ruido.reduce((a, b) => a + b) / ruido.length;
    double desv = sqrt(ruido.map((v) => pow(v - promedio, 2)).reduce((a, b) => a + b) / ruido.length);
    final random = Random();
    List<FlSpot> ruidoExtendido = [];
    for (int i = 0; i <= totalPoints; i++) {
      double x = xStart + (xEnd - xStart) * i / totalPoints;
      // Ruido aleatorio en todo el rango, con la misma estadística que el ruido original
      double y = promedio + (random.nextDouble() - 0.5) * 2 * max(desv, 1.0);
      ruidoExtendido.add(FlSpot(x, y));
    }

    // --- Generar todas las parábolas extendidas ---
    List<List<FlSpot>> todasLasParabolas = [];
    for (final senal in senales) {
      final double fc = senal.frecuenciaCentralMHz;
      final double bw = senal.anchoDeBandaMHz;
      final double pot = senal.potenciaDbm;
      final double f1 = fc - bw / 2;
      final double yLateral = pot - 3;
      double a = (yLateral - pot) / ((f1 - fc) * (f1 - fc));
      List<FlSpot> parabolaSpots = [];
      for (int i = 0; i <= totalPoints; i++) {
        double x = xStart + (xEnd - xStart) * i / totalPoints;
        double y = a * (x - fc) * (x - fc) + pot;
        parabolaSpots.add(FlSpot(x, y));
      }
      todasLasParabolas.add(parabolaSpots);
    }

    // --- Generar la línea resaltada (envolvente) ---
    List<FlSpot> envolvente = [];
    for (int i = 0; i <= totalPoints; i++) {
      double x = xStart + (xEnd - xStart) * i / totalPoints;
      double yRuido = ruidoExtendido[i].y;
      double? yMax;
      for (final parabola in todasLasParabolas) {
        double yParabola = parabola[i].y;
        if (yMax == null || yParabola > yMax) {
          yMax = yParabola;
        }
      }
      // La envolvente es el máximo entre el piso de ruido y todas las señales en ese punto
      double yEnv = yMax != null && yMax > yRuido ? yMax : yRuido;
      envolvente.add(FlSpot(x, yEnv));
    }

    // --- Puntos destacados (opcional, para tooltips) ---
    List<FlSpot> puntosSenales = [];
    List<FlSpot> puntosLaterales = [];
    for (final senal in senales) {
      final double fc = senal.frecuenciaCentralMHz;
      final double bw = senal.anchoDeBandaMHz;
      final double pot = senal.potenciaDbm;
      final double f1 = fc - bw / 2;
      final double f2 = fc + bw / 2;
      final double yLateral = pot - 3;
      puntosLaterales.add(FlSpot(f1, yLateral));
      puntosLaterales.add(FlSpot(f2, yLateral));
      puntosSenales.add(FlSpot(fc, pot));
    }

    // --- Calcular área visible para mostrar todos los puntos relevantes ---
    final List<double> allX = [
      ...ruidoExtendido.map((p) => p.x),
      ...envolvente.map((p) => p.x),
      ...puntosSenales.map((p) => p.x),
      ...puntosLaterales.map((p) => p.x),
    ];
    final List<double> allY = [
      ...ruidoExtendido.map((p) => p.y),
      ...envolvente.map((p) => p.y),
      ...puntosSenales.map((p) => p.y),
      ...puntosLaterales.map((p) => p.y),
    ];

    double minX = allX.reduce((a, b) => a < b ? a : b);
    double maxX = allX.reduce((a, b) => a > b ? a : b);
    double minY = allY.reduce((a, b) => a < b ? a : b);
    double maxY = allY.reduce((a, b) => a > b ? a : b);

    final double margenX = ((maxX - minX) * 0.15).abs();
    final double margenY = ((maxY - minY) * 0.15).abs();
    minX = minX - margenX;
    maxX = maxX + margenX;
    minY = minY - margenY;
    maxY = maxY + margenY;

    // --- LÍNEAS PARA EL GRÁFICO ---
    final List<LineChartBarData> lineBars = [
      // Piso de ruido extendido (gris)
      LineChartBarData(
        spots: ruidoExtendido,
        isCurved: true,
        color: Colors.grey,
        barWidth: 2,
        dotData: FlDotData(show: false),
      ),
      // Todas las señales (gris claro, fondo)
      ...todasLasParabolas.map((parabolaSpots) => LineChartBarData(
            spots: parabolaSpots,
            isCurved: true,
            color: Colors.grey.withOpacity(0.5), // Gris claro, sin resaltar
            barWidth: 2,
            dotData: FlDotData(show: false),
          )),
      // Línea resaltada (envolvente, azul fuerte)
      LineChartBarData(
        spots: envolvente,
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        dotData: FlDotData(show: false),
      ),
    ];

    // Puntos centrales y laterales (opcional)
    if (puntosSenales.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: puntosSenales,
          isCurved: false,
          color: Colors.red,
          barWidth: 0,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 5,
              color: Colors.red,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
        ),
      );
    }
    if (puntosLaterales.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: puntosLaterales,
          isCurved: false,
          color: Colors.green,
          barWidth: 0,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4,
              color: Colors.green,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
        ),
      );
    }

    // Widget interactivo con zoom y desplazamiento
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.5,
        maxScale: 5,
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 22),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 32),
              ),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
            lineBarsData: lineBars,
            showingTooltipIndicators: [],
            lineTouchData: LineTouchData(
              enabled: true,
              getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes.map((i) {
                return TouchedSpotIndicatorData(
                  FlLine(color: Colors.yellow, strokeWidth: 1),
                  FlDotData(show: true),
                );
              }).toList(),
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.black87,
                fitInsideHorizontally: false,
                fitInsideVertically: false,
                getTooltipItems: (touchedSpots) {
                  return List.generate(
                    touchedSpots.length,
                    (i) {
                      if (i == 0) {
                        final spot = touchedSpots[i];
                        final x = spot.x.toStringAsFixed(2);
                        final y = spot.y.toStringAsFixed(2);
                        return LineTooltipItem(
                          '($x, $y)',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }
                      return null;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Nuevo formulario para el piso de ruido (temperatura y ancho de banda)
class FormularioRuidoTermico extends StatefulWidget {
  final void Function(double temperatura, double bwHz) onSubmit;

  const FormularioRuidoTermico({super.key, required this.onSubmit});

  @override
  State<FormularioRuidoTermico> createState() => _FormularioRuidoTermicoState();
}

class _FormularioRuidoTermicoState extends State<FormularioRuidoTermico> {
  final _formKey = GlobalKey<FormState>();
  final _tempCtrl = TextEditingController(text: '');
  final _bwCtrl = TextEditingController(text: '');

  @override
  void dispose() {
    _tempCtrl.dispose();
    _bwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _tempCtrl,
            decoration: const InputDecoration(labelText: 'Temperatura (K)'),
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
          ),
          TextFormField(
            controller: _bwCtrl,
            decoration: const InputDecoration(labelText: 'Ancho de banda (Hz)'),
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final temp = double.tryParse(_tempCtrl.text.trim()) ?? 290.0;
                final bw = double.tryParse(_bwCtrl.text.trim()) ?? 1e6;
                widget.onSubmit(temp, bw);
              }
            },
            child: const Text('Generar Ruido'),
          ),
        ],
      ),
    );
  }
}
