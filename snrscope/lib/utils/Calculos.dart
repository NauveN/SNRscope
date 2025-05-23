import '../modelos/Senal.dart';

class Calculos {
  static double calcularSNR(Senal senal, double nivelRuidoDbm) {
    return senal.potenciaDbm - nivelRuidoDbm;
  }

  static double diferenciaDePotencia(Senal a, Senal b) {
    return (a.potenciaDbm - b.potenciaDbm).abs();
  }

  static double diferenciaDeFrecuencia(Senal a, Senal b) {
    return (a.frecuenciaCentralMHz - b.frecuenciaCentralMHz).abs();
  }

  static List<String> calcularComparaciones(List<Senal> senales, double nivelRuido) {
    List<String> resultados = [];
    for (int i = 0; i < senales.length; i++) {
      final snr = calcularSNR(senales[i], nivelRuido);
      resultados.add("SNR de Señal ${i + 1}: ${snr.toStringAsFixed(2)} dB");
      for (int j = i + 1; j < senales.length; j++) {
        final dp = diferenciaDePotencia(senales[i], senales[j]);
        final df = diferenciaDeFrecuencia(senales[i], senales[j]);
        resultados.add("ΔP Señal ${i + 1} - ${j + 1}: ${dp.toStringAsFixed(2)} dB");
        resultados.add("Δf Señal ${i + 1} - ${j + 1}: ${df.toStringAsFixed(2)} MHz");
      }
    }
    return resultados;
  }
}