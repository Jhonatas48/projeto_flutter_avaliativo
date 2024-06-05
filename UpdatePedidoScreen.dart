import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdatePedidoScreen extends StatefulWidget {
  final Map pedido;

  const UpdatePedidoScreen({required this.pedido});

  @override
  _UpdatePedidoScreenState createState() => _UpdatePedidoScreenState();
}

class _UpdatePedidoScreenState extends State<UpdatePedidoScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _cliente;
  late String _enderecoDestino;
  late String _produto;
  late String _dataEntregaPrevista;
  late String _localizacaoAtual;
  late String _statusEntrega;
  late String _cidade;

  _updatePedido() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      DatabaseReference pedidoRef = FirebaseDatabase.instance.ref('pedidos/${widget.pedido['key']}');
      pedidoRef.set({
        "cliente": _cliente,
        "enderecoDestino": _enderecoDestino,
        "produto": _produto,
        "dataEntregaPrevista": _dataEntregaPrevista,
        "localizacaoAtual": _localizacaoAtual,
        "statusEntrega": _statusEntrega,
        "cidade": _cidade,
      }).then((_) {
        Navigator.pop(context);
      });
    }
  }

  Future<String> getCityFromCoordinates(double latitude, double longitude) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('address')) {
        final address = data['address'];
        if (address.containsKey('city')) {
          return address['city'];
        } else if (address.containsKey('town')) {
          return address['town'];
        } else if (address.containsKey('village')) {
          return address['village'];
        } else {
          return 'Cidade não encontrada';
        }
      } else {
        return 'Erro na geocodificação reversa';
      }
    } else {
      return 'Erro ao conectar à API Nominatim';
    }
  }

  _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Serviço de localização desativado.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permissão de localização permanentemente negada.');
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _localizacaoAtual = '${position.latitude}, ${position.longitude}';
    });
    _cidade = await getCityFromCoordinates(position.latitude, position.longitude);
  }

  @override
  void initState() {
    super.initState();
    _cliente = widget.pedido['cliente'];
    _enderecoDestino = widget.pedido['enderecoDestino'];
    _produto = widget.pedido['produto'];
    _dataEntregaPrevista = widget.pedido['dataEntregaPrevista'];
    _localizacaoAtual = widget.pedido['localizacaoAtual'];
    _statusEntrega = widget.pedido['statusEntrega'];
    _cidade = widget.pedido['cidade'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Atualizar Pedido"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Cliente",
                  border: OutlineInputBorder(),
                ),
                initialValue: _cliente,
                onSaved: (val) => _cliente = val!,
                validator: (val) => val!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Endereço de Destino",
                  border: OutlineInputBorder(),
                ),
                initialValue: _enderecoDestino,
                onSaved: (val) => _enderecoDestino = val!,
                validator: (val) => val!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Produto",
                  border: OutlineInputBorder(),
                ),
                initialValue: _produto,
                onSaved: (val) => _produto = val!,
                validator: (val) => val!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Data de Entrega Prevista",
                  border: OutlineInputBorder(),
                ),
                initialValue: _dataEntregaPrevista,
                onSaved: (val) => _dataEntregaPrevista = val!,
                validator: (val) => val!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Localização Atual",
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _localizacaoAtual),
                      readOnly: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: _getCurrentLocation,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Cidade",
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: _cidade),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Status da Entrega",
                  border: OutlineInputBorder(),
                ),
                value: _statusEntrega,
                items: <String>['a caminho', 'atrasada', 'entregue']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _statusEntrega = newValue!;
                  });
                },
                onSaved: (val) => _statusEntrega = val!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updatePedido,
                child: Text("Atualizar"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
