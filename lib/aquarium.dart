import 'package:flutter/material.dart';
import 'dart:math';
import 'fish.dart';
import 'database_helper.dart';

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with SingleTickerProviderStateMixin {
  List<Fish> fishList = [];
  Color selectedColor = Colors.red; // Default fish color (red)
  double selectedSpeed = 1.0;
  bool collisionEffectEnabled = true;

  late AnimationController _controller;

  // Available color options and their names
  final Map<Color, String> colorOptions = {
    Colors.red: "Red",
    Colors.green: "Green",
    Colors.yellow: "Yellow",
    Colors.orange: "Orange",
    Colors.purple: "Purple"
  };

  @override
  void initState() {
    super.initState();
    _loadSavedSettings(); // Load settings from the database on startup
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _controller.addListener(_updateFishPositions);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Function to load saved settings from the database
  Future<void> _loadSavedSettings() async {
    final settings = await DatabaseHelper.loadSettings();
    setState(() {
      selectedSpeed = settings['speed'];
      selectedColor = Color(settings['color']); // Load saved color
      // If the saved color is not in the dropdown options, fallback to red
      if (!_colorInDropdown(selectedColor)) {
        selectedColor = Colors.red;
      }
      int fishCount = settings['fishCount'];
      for (int i = 0; i < fishCount; i++) {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      }
    });
  }

  // Save current settings to the database
  Future<void> _saveSettings() async {
    await DatabaseHelper.saveSettings(
        fishList.length, selectedSpeed, selectedColor.value);
  }

  // Add fish to the aquarium
  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
        _saveSettings(); // Save settings when adding a fish
      });
    }
  }

  // Update the positions of fish and check for collisions
  void _updateFishPositions() {
    setState(() {
      for (var fish in fishList) {
        fish.moveFish();
      }
      if (collisionEffectEnabled) {
        _checkAllCollisions();
      }
    });
  }

  // Check if two fish collide and apply behavior
  void _checkForCollision(Fish fish1, Fish fish2) {
    if ((fish1.position.dx - fish2.position.dx).abs() < 20 &&
        (fish1.position.dy - fish2.position.dy).abs() < 20) {
      fish1.changeDirection();
      fish2.changeDirection();
      setState(() {
        fish1.color = Random().nextBool() ? Colors.red : Colors.green;
      });
    }
  }

  // Check all fish for potential collisions
  void _checkAllCollisions() {
    for (int i = 0; i < fishList.length; i++) {
      for (int j = i + 1; j < fishList.length; j++) {
        _checkForCollision(fishList[i], fishList[j]);
      }
    }
  }

  // Helper function to check if the color exists in the dropdown options
  bool _colorInDropdown(Color color) {
    return colorOptions.keys.contains(color);
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsiveness
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white, // Overall white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text('Virtual Aquarium',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Aquarium Container
            Container(
              width: screenWidth * 0.9,
              height: screenHeight * 0.4,
              decoration: BoxDecoration(
                color: Colors.blue[300], // Aquarium background remains blue
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: fishList.map((fish) => fish.buildFish()).toList(),
              ),
            ),
            SizedBox(height: 20),
            
            // Settings and Buttons Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: _addFish,
                          child: Text('Add Fish'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: _saveSettings,
                          child: Text('Save Settings'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Slider for Fish Speed
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Fish Speed",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Slider(
                          value: selectedSpeed,
                          onChanged: (newSpeed) {
                            setState(() {
                              selectedSpeed = newSpeed;
                            });
                            _saveSettings();
                          },
                          min: 0.5,
                          max: 3.0,
                          divisions: 5,
                          label: '$selectedSpeed',
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Dropdown for Fish Color
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Fish Color",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        DropdownButton<Color>(
                          value: selectedColor,
                          items: colorOptions.keys.map((Color color) {
                            return DropdownMenuItem<Color>(
                              value: color,
                              child: Text(
                                colorOptions[color] ?? 'Unknown',
                                style: TextStyle(color: color),
                              ),
                            );
                          }).toList(),
                          onChanged: (color) {
                            setState(() {
                              selectedColor = color ?? Colors.red;
                            });
                            _saveSettings();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Toggle switch for Collision Effect
                    SwitchListTile(
                      title: Text('Enable Collision Effect'),
                      value: collisionEffectEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          collisionEffectEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            // Footer Card with Name and Panther ID
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              color: Colors.grey[100],
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Text(
                    'CW05 Mahendra Krishna',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
