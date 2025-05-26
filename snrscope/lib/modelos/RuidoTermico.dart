import 'dart:math';

class RuidoTermico {
  final double temperaturaK;
  final double anchoDeBandaHz;
  final double? ruidoSistemaDb;

  static const double k = 1.38e-23; 

  RuidoTermico({
    required this.temperaturaK,
    required this.anchoDeBandaHz,
    this.ruidoSistemaDb,
  });

  double calcularRuidoPromedioDbm() {
    double pn = k * temperaturaK * anchoDeBandaHz; 
    double pnDbm = 10 * log(pn / 1e-3) / ln10; 
    return ruidoSistemaDb != null ? pnDbm + ruidoSistemaDb! : pnDbm;
  }

  List<double> generarRuidoAleatorio(int puntos, [double? baseDbm]) {
    final promedio = baseDbm ?? calcularRuidoPromedioDbm();
    final random = Random();
    return List.generate(puntos, (i) => promedio + random.nextDouble() * 2 - 1); // +/- 1 dB
  }
}