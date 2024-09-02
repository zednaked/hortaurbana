import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.dark(
          onPrimary: Colors.green[900]!,
          onSecondary: Colors.greenAccent,
          surface: Colors.green[900]!,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[900],
        ),
        cardTheme: CardTheme(
          color: Colors.grey[900],
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.grey[900],
          titleTextStyle: TextStyle(color: Colors.greenAccent),
          contentTextStyle: TextStyle(color: Colors.greenAccent),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.green,
          filled: true,
          hintStyle: TextStyle(color: Colors.green),
          labelStyle: TextStyle(color: Colors.grey[900]),
        ),
      ),
      home: const HortaHomePage(title: 'Horta Urbana'),
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
  List<Plant> _filteredPlants = [];
  Map<Color, List<Plant>> _sharedPlants = {};
  final String _filePath = 'db.json';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlants();
    _searchController.addListener(_filterPlants);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPlants() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredPlants = List.from(_plants);
        _filteredPlants
            .addAll(_sharedPlants.values.expand((element) => element));
      } else {
        _filteredPlants = _plants
            .where((plant) => plant.name.toLowerCase().contains(searchTerm))
            .toList();
        _filteredPlants.addAll(_sharedPlants.values
            .expand((element) => element)
            .where((plant) => plant.name.toLowerCase().contains(searchTerm)));
      }
    });
  }

  Future<void> _loadPlants() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? plantsJson = prefs.getString('plants');

    if (plantsJson != null) {
      _loadPlantsFromJson(plantsJson);
    } else {
      await _loadInitialJson();
    }
  }

  Future<void> _loadInitialJson() async {
    try {
      final String response = await rootBundle.loadString(_filePath);
      _loadPlantsFromJson(response);
      await _savePlantsToPrefs();
    } catch (e) {
      print('Error loading initial JSON: $e');
    }
  }

  void _loadPlantsFromJson(String jsonString) {
    final data = json.decode(jsonString);
    setState(() {
      _plants = (data['plantas'] as List)
          .map((plantData) => Plant.fromJson(plantData))
          .toList();
      _filteredPlants = List.from(_plants);
    });
  }

  Future<void> _savePlantsToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {
      'plantas': _plants.map((plant) => plant.toJson()).toList(),
    };
    final String jsonString = json.encode(data);
    await prefs.setString('plants', jsonString);
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
                  Plant newPlant = Plant(
                    name:
                        newPlantName.isNotEmpty ? newPlantName : 'Nova Planta',
                    quantity: 1,
                    phase: 'crescimento',
                    isProducing: false,
                    hasSeedsOrSeedlings: false,
                  );
                  _plants.add(newPlant);
                  _filterPlants();
                });
                _savePlantsToPrefs();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _editPlant(int index) {
    Plant plant = _filteredPlants[index];
    if (_plants.contains(plant)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
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
                            plant.name = newName;
                          });
                          _savePlantsToPrefs();
                          _filterPlants();
                        },
                        decoration:
                            InputDecoration(labelText: "Nome da planta"),
                        controller: TextEditingController(text: plant.name),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        onChanged: (value) {
                          newQuantity = int.tryParse(value) ?? plant.quantity;
                          this.setState(() {
                            plant.quantity = newQuantity;
                          });
                          _savePlantsToPrefs();
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
                              plant.phase = newPhase;
                            });
                            _savePlantsToPrefs();
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
                            plant.isProducing = newIsProducing;
                          });
                          _savePlantsToPrefs();
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
                            plant.hasSeedsOrSeedlings = newHasSeedsOrSeedlings;
                          });
                          _savePlantsToPrefs();
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
                  TextButton(
                    child: Text('Excluir'),
                    onPressed: () {
                      _deletePlant(index);
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
  }

  void _deletePlant(int index) {
    Plant plant = _filteredPlants[index];
    if (_plants.contains(plant)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirmar exclusão'),
            content: Text('Tem certeza que deseja excluir esta planta?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Excluir'),
                onPressed: () {
                  setState(() {
                    _plants.remove(plant);
                    _filterPlants();
                  });
                  _savePlantsToPrefs();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _generateQRCode() {
    final plantsData = json.encode(_plants.map((p) => p.toJson()).toList());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('QR Code da Lista de Plantas'),
          content: Container(
            width: 300,
            height: 300,
            child: QrImageView(
              data: plantsData,
              version: QrVersions.auto,
              size: 280,
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
  }

  void _scanQRCode() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => QRViewExample(
        onScanResult: (result) {
          if (result != null) {
            try {
              final data = json.decode(result);
              final newPlants =
                  (data as List).map((p) => Plant.fromJson(p)).toList();
              setState(() {
                final color = Colors
                    .accents[_sharedPlants.length % Colors.accents.length];
                _sharedPlants[color] = newPlants;
                _filterPlants();
              });
            } catch (e) {
              print('Error decoding QR code: $e');
            }
          }
        },
      ),
    ));
  }

  void _showImportedLists() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Listas Importadas'),
          content: SingleChildScrollView(
            child: Column(
              children: _sharedPlants.entries.map((entry) {
                return ListTile(
                  title: Text(
                      'Lista ${_sharedPlants.keys.toList().indexOf(entry.key) + 1}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _sharedPlants.remove(entry.key);
                        _filterPlants();
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }).toList(),
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
  }

  void _showDeveloperInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Informações do Desenvolvedor'),
          content: Text(
              'Desenvolvedor: Thiago Goncalves\nEmail: zednaked@gmail.com'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: _generateQRCode,
            tooltip: 'Gerar QR Code',
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: _scanQRCode,
            tooltip: 'Escanear QR Code',
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: _showImportedLists,
            tooltip: 'Listas Importadas',
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showDeveloperInfo,
            tooltip: 'Informações do Desenvolvedor',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar plantas',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredPlants.isEmpty
                ? Center(child: Text('Nenhuma planta encontrada'))
                : ListView.builder(
                    itemCount: _filteredPlants.length,
                    itemBuilder: (context, index) {
                      final plant = _filteredPlants[index];
                      final isSharedPlant = !_plants.contains(plant);
                      final color = isSharedPlant
                          ? _sharedPlants.entries
                              .firstWhere(
                                  (entry) => entry.value.contains(plant))
                              .key
                          : null;
                      return Card(
                        elevation: 2,
                        margin:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: color,
                        child: ListTile(
                          title: Text(plant.name,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Quantidade: ${plant.quantity}\nFase: ${plant.phase}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                plant.isProducing
                                    ? Icons.eco
                                    : Icons.eco_outlined,
                                color: plant.isProducing
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Icon(
                                plant.hasSeedsOrSeedlings
                                    ? Icons.local_florist
                                    : Icons.local_florist_outlined,
                                color: plant.hasSeedsOrSeedlings
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                              if (!isSharedPlant)
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deletePlant(index),
                                ),
                            ],
                          ),
                          onTap: isSharedPlant ? null : () => _editPlant(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlant,
        tooltip: 'Adicionar Planta',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  final Function(String?) onScanResult;

  const QRViewExample({Key? key, required this.onScanResult}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text('Escaneie um QR code'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      widget.onScanResult(scanData.code);
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
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
