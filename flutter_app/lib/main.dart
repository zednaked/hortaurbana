import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

void main() {
  runApp(const HortaUrbanaApp());
}

class HortaUrbanaApp extends StatelessWidget {
  const HortaUrbanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horta Urbana',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HortaHomePage(title: 'Minha Horta Urbana'),
    );
  }
}

class HortaHomePage extends StatefulWidget {
  const HortaHomePage({super.key, required this.title});

  final String title;

  @override
  State<HortaHomePage> createState() => _HortaHomePageState();
}

class _HortaHomePageState extends State<HortaHomePage> {
  List<Plant> _plants = [];
  final String _filePath = 'db.json';

  @override
  void initState() {
    super.initState();
    _loadPlantsFromJson();
  }

  Future<void> _loadPlantsFromJson() async {
    try {
      final String response = await rootBundle.loadString(_filePath);
      final data = await json.decode(response);
      setState(() {
        _plants = (data['plantas'] as List)
            .map((plantData) => Plant.fromJson(plantData))
            .toList();
      });
    } catch (e) {
      print('Error loading plants: $e');
      // You might want to show an error message to the user here
    }
  }

  Future<void> _savePlantsToJson() async {
    try {
      final Map<String, dynamic> data = {
        'plantas': _plants.map((plant) => plant.toJson()).toList(),
      };
      final String jsonString = json.encode(data);
      await File(_filePath).writeAsString(jsonString);
    } catch (e) {
      print('Error saving plants: $e');
      // You might want to show an error message to the user here
    }
  }

  void _addPlant() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newPlantName = '';
        return AlertDialog(
          title: Text('Adicionar Nova Planta'),
          content: TextField(
            onChanged: (value) {
              newPlantName = value;
            },
            decoration: InputDecoration(hintText: "Nome da planta"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Adicionar'),
              onPressed: () {
                setState(() {
                  _plants.add(Plant(
                    name:
                        newPlantName.isNotEmpty ? newPlantName : 'Nova Planta',
                    quantity: 1,
                    phase: 'Semeadura',
                    isProducing: false,
                    hasSeedsOrSeedlings: false,
                  ));
                });
                _savePlantsToJson();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _editPlant(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Plant plant = _plants[index];
        String newName = plant.name;
        int newQuantity = plant.quantity;
        String newPhase = plant.phase;
        bool newIsProducing = plant.isProducing;
        bool newHasSeedsOrSeedlings = plant.hasSeedsOrSeedlings;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Editar Planta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        newName = value;
                        this.setState(() {
                          _plants[index].name = newName;
                        });
                        _savePlantsToJson();
                      },
                      decoration: InputDecoration(labelText: "Nome da planta"),
                      controller: TextEditingController(text: plant.name),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      onChanged: (value) {
                        newQuantity = int.tryParse(value) ?? plant.quantity;
                        this.setState(() {
                          _plants[index].quantity = newQuantity;
                        });
                        _savePlantsToJson();
                      },
                      decoration: InputDecoration(labelText: "Quantidade"),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: plant.quantity.toString()),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: newPhase,
                      decoration: InputDecoration(labelText: "Fase"),
                      items: <String>[
                        'semeadura',
                        'crescimento',
                        'floração',
                        'frutificação',
                        'colheita'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            newPhase = newValue;
                          });
                          this.setState(() {
                            _plants[index].phase = newPhase;
                          });
                          _savePlantsToJson();
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    SwitchListTile(
                      title: Text('Produzindo'),
                      value: newIsProducing,
                      onChanged: (bool value) {
                        setState(() {
                          newIsProducing = value;
                        });
                        this.setState(() {
                          _plants[index].isProducing = newIsProducing;
                        });
                        _savePlantsToJson();
                      },
                    ),
                    SwitchListTile(
                      title: Text('Tem sementes/mudas'),
                      value: newHasSeedsOrSeedlings,
                      onChanged: (bool value) {
                        setState(() {
                          newHasSeedsOrSeedlings = value;
                        });
                        this.setState(() {
                          _plants[index].hasSeedsOrSeedlings =
                              newHasSeedsOrSeedlings;
                        });
                        _savePlantsToJson();
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Fechar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _plants.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _plants.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(_plants[index].name,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Quantidade: ${_plants[index].quantity}\nFase: ${_plants[index].phase}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _plants[index].isProducing
                              ? Icons.eco
                              : Icons.eco_outlined,
                          color: _plants[index].isProducing
                              ? Colors.green
                              : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Icon(
                          _plants[index].hasSeedsOrSeedlings
                              ? Icons.local_florist
                              : Icons.local_florist_outlined,
                          color: _plants[index].hasSeedsOrSeedlings
                              ? Colors.orange
                              : Colors.grey,
                        ),
                      ],
                    ),
                    onTap: () => _editPlant(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlant,
        tooltip: 'Adicionar Planta',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Plant {
  String name;
  int quantity;
  String phase;
  bool isProducing;
  bool hasSeedsOrSeedlings;

  Plant({
    required this.name,
    required this.quantity,
    required this.phase,
    required this.isProducing,
    required this.hasSeedsOrSeedlings,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      name: json['nome'],
      quantity: json['quantidade'],
      phase: json['fase'],
      isProducing: json['produzindo'],
      hasSeedsOrSeedlings: json['temSementesOuMudas'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': name,
      'quantidade': quantity,
      'fase': phase,
      'produzindo': isProducing,
      'temSementesOuMudas': hasSeedsOrSeedlings,
    };
  }
}
