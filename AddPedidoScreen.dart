import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPedidoScreen extends StatefulWidget {
  @override
  _AddPedidoScreenState createState() => _AddPedidoScreenState();
}

class _AddPedidoScreenState extends State<AddPedidoScreen> {
  final databaseRef = FirebaseDatabase.instance.ref('pedidos');
  final _formKey = GlobalKey<FormState>();
  String _cliente = '';
  String _enderecoDestino = '';
  String _produto = '';
  String _dataEntregaPrevista = '';
  String _localizacaoAtual = '';
  String _statusEntrega = 'a caminho';
  String _cidade = '';

  _savePedido() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      databaseRef.push().set({
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar Pedido"),
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
                onSaved: (val) => _cliente = val!,
                validator: (val) => val!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Endereço de Destino",
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => _enderecoDestino = val!,
                validator: (val) => val!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Produto",
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => _produto = val!,
                validator: (val) => val!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Data de Entrega Prevista",
                  border: OutlineInputBorder(),
                ),
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
                onPressed: _savePedido,
                child: Text("Salvar"),
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
