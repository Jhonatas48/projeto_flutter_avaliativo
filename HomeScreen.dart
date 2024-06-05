import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import './AddPedidoScreen.dart';
import './UpdatePedidoScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final databaseRef = FirebaseDatabase.instance.ref('pedidos');
  List<Map> pedidos = [];

  @override
  void initState() {
    super.initState();
    _fetchPedidos();
  }

  _fetchPedidos() {
    databaseRef.onValue.listen((event) {
      var snapshot = event.snapshot;
      if (snapshot.exists) {
        Map data = snapshot.value as Map;
        pedidos.clear();
        data.forEach((key, value) {
          pedidos.add({"key": key, ...value});
        });
        setState(() {});
      }
    });
  }

  _deletePedido(String key) {
    DatabaseReference pedidoRef = FirebaseDatabase.instance.ref('pedidos/$key');
    pedidoRef.remove().then((_) {
      _fetchPedidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pedidos"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: pedidos.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                title: Text(
                  pedidos[index]['cliente'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Produto: ${pedidos[index]['produto']}'),
                    Text('Status: ${pedidos[index]['statusEntrega']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdatePedidoScreen(pedido: pedidos[index]),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deletePedido(pedidos[index]['key']);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPedidoScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
