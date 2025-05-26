
import 'package:flutter/material.dart';
import 'modelos/Senal.dart';
import 'modelos/RuidoTermico.dart';
import 'widgets/FormularioSenales.dart';
import 'widgets/GraficoEspectro.dart';
import 'utils/Calculos.dart';

void main() => runApp(const MaterialApp(home: PantallaEspectro()));

class PantallaEspectro extends StatefulWidget {
  const PantallaEspectro({super.key});

  @override
  State<PantallaEspectro> createState() => _PantallaEspectroState();
}

class _PantallaEspectroState extends State<PantallaEspectro> {
  final List<Senal> senales = [];
  List<double> ruido = [];
  List<String> resultados = [];

  double temperatura = 290.0;
  double bwTotalHz = 10e6; // 10 MHz
  double frecuenciaMin = 90.0;
  double frecuenciaMax = 110.0;
  double? pisoRuidoDbm; // <-- NUEVO

  void calcularEspectro() {
    final ruidoTermico = RuidoTermico(
      temperaturaK: temperatura,
      anchoDeBandaHz: bwTotalHz,
      ruidoSistemaDb: pisoRuidoDbm, // pasa el valor si existe
    );
    // Si el usuario ingresó el piso de ruido, úsalo directamente, si no, calcula
    final promedio = pisoRuidoDbm ?? ruidoTermico.calcularRuidoPromedioDbm();
    final ruidoGenerado = ruidoTermico.generarRuidoAleatorio(100, promedio);

    final mediciones = Calculos.calcularComparaciones(senales, promedio);

    setState(() {
      ruido = ruidoGenerado;
      resultados = mediciones;
    });
  }

  void eliminarSenal(int index) {
    setState(() {
      senales.removeAt(index);
    });
  }

  void editarSenal(int index) {
    final senal = senales[index];
    showDialog(
      context: context,
      builder: (context) {
        final potCtrl = TextEditingController(text: senal.potenciaDbm.toString());
        final fcCtrl = TextEditingController(text: senal.frecuenciaCentralMHz.toString());
        final bwCtrl = TextEditingController(text: senal.anchoDeBandaMHz.toString());

        return AlertDialog(
          title: const Text('Editar Señal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: potCtrl, decoration: const InputDecoration(labelText: 'Potencia')), 
              TextField(controller: fcCtrl, decoration: const InputDecoration(labelText: 'Frecuencia central')),
              TextField(controller: bwCtrl, decoration: const InputDecoration(labelText: 'Ancho de banda')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  senales[index] = Senal(
                    potenciaDbm: double.parse(potCtrl.text),
                    frecuenciaCentralMHz: double.parse(fcCtrl.text),
                    anchoDeBandaMHz: double.parse(bwCtrl.text),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            )
          ],
        );
      },
    );
  }

  Widget construirListaSenales() {
    return Column(
      children: senales.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return ListTile(
          title: Text('Señal ${i + 1}: ${s.potenciaDbm} dBm @ ${s.frecuenciaCentralMHz} MHz'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: () => editarSenal(i), icon: const Icon(Icons.edit)),
              IconButton(onPressed: () => eliminarSenal(i), icon: const Icon(Icons.delete)),
            ],
          ),
        );
      }).toList(),
    );
  }

  void actualizarRangoFrecuencia() {
    if (senales.isEmpty) {
      frecuenciaMin = 90.0;
      frecuenciaMax = 110.0;
      return;
    }
    double minSignalFreq = senales
        .map((s) => s.frecuenciaCentralMHz - s.anchoDeBandaMHz / 2)
        .reduce((a, b) => a < b ? a : b);
    double maxSignalFreq = senales
        .map((s) => s.frecuenciaCentralMHz + s.anchoDeBandaMHz / 2)
        .reduce((a, b) => a > b ? a : b);
    final double margen = ((maxSignalFreq - minSignalFreq) * 0.1).abs();
    frecuenciaMin = (minSignalFreq - margen).clamp(0, double.infinity);
    frecuenciaMax = (maxSignalFreq + margen).clamp(0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espectro de Frecuencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Formulario para el piso de ruido
            FormularioRuidoTermico(
              onSubmit: (temp, bw, pisoDbm) {
                setState(() {
                  temperatura = temp;
                  bwTotalHz = bw;
                  pisoRuidoDbm = pisoDbm; // guarda el valor
                });
              },
            ),
            const SizedBox(height: 10),
            // Mostrar el valor actual del piso de ruido
            Row(
              children: [
                const Text('Piso de ruido actual: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  pisoRuidoDbm != null
                      ? '${pisoRuidoDbm!.toStringAsFixed(2)} dBm'
                      : '${RuidoTermico(temperaturaK: temperatura, anchoDeBandaHz: bwTotalHz).calcularRuidoPromedioDbm().toStringAsFixed(2)} dBm',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FormularioSenales(
              onAgregar: (s) {
                setState(() {
                  senales.add(s);
                  actualizarRangoFrecuencia();
                });
              },
            ),
            const SizedBox(height: 10),
            construirListaSenales(),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                actualizarRangoFrecuencia();
                calcularEspectro();
              },
              child: const Text('Calcular y Graficar'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 420, // Más espacio para tooltips
              child: GraficoEspectro(
                senales: senales,
                ruido: ruido,
                frecuenciaMin: frecuenciaMin,
                frecuenciaMax: frecuenciaMax,
              ),
            ),
            const SizedBox(height: 10),
            ...resultados.map((r) => Text(r)),
          ],
        ),
      ),
    );
  }
}
