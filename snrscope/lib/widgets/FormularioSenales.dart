import 'package:flutter/material.dart';
import '../modelos/Senal.dart';

class FormularioSenales extends StatefulWidget {
  final Function(Senal) onAgregar;

  const FormularioSenales({super.key, required this.onAgregar});

  @override
  State<FormularioSenales> createState() => _FormularioSenalesState();
}

class _FormularioSenalesState extends State<FormularioSenales> {
  final _formKey = GlobalKey<FormState>();
  final _potenciaCtrl = TextEditingController();
  final _fcCtrl = TextEditingController();
  final _bwCtrl = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final senal = Senal(
        potenciaDbm: double.parse(_potenciaCtrl.text),
        frecuenciaCentralMHz: double.parse(_fcCtrl.text),
        anchoDeBandaMHz: double.parse(_bwCtrl.text),
      );
      widget.onAgregar(senal);
      _potenciaCtrl.clear();
      _fcCtrl.clear();
      _bwCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _potenciaCtrl,
            decoration: const InputDecoration(labelText: 'Potencia (dBm)'),
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
          ),
          TextFormField(
            controller: _fcCtrl,
            decoration: const InputDecoration(labelText: 'Frecuencia Central (MHz)'),
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
          ),
          TextFormField(
            controller: _bwCtrl,
            decoration: const InputDecoration(labelText: 'Ancho de Banda (MHz)'),
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
          ),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Agregar Señal'),
          )
        ],
      ),
    );
  }
}
