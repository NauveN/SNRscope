import 'dart:math';

class RuidoTermico {
  final double temperaturaK;
  final double anchoDeBandaHz;
  final double? ruidoSistemaDb;

  static const double k = 1.38e-23; // Constante de Boltzmann

  RuidoTermico({
    required this.temperaturaK,
    required this.anchoDeBandaHz,
    this.ruidoSistemaDb,
  });

  double calcularRuidoPromedioDbm() {
    double pn = k * temperaturaK * anchoDeBandaHz; // en Watts
    double pnDbm = 10 * log(pn / 1e-3) / ln10; // conversión a dBm
    return ruidoSistemaDb != null ? pnDbm + ruidoSistemaDb! : pnDbm;
  }

  List<double> generarRuidoAleatorio(int puntos) {
    final promedio = calcularRuidoPromedioDbm();
    final random = Random();
    return List.generate(puntos, (i) => promedio + random.nextDouble() * 2 - 1); // +/- 1 dB
  }
}