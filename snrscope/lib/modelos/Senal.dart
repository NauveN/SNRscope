class Senal {
  final double potenciaDbm;
  final double frecuenciaCentralMHz;
  final double anchoDeBandaMHz;

  Senal({
    required this.potenciaDbm,
    required this.frecuenciaCentralMHz,
    required this.anchoDeBandaMHz,
  });
  // Método para calcular la potencia en miliwatios (mW)
  double calcularPotenciaMw() => potenciaDbm * 0.001;

  @override
  String toString() {
    return 'Potencia: $potenciaDbm dBm, Frecuencia Central: $frecuenciaCentralMHz MHz, Ancho de Banda: $anchoDeBandaMHz MHz';
  }
}