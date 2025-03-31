import 'package:flutter/material.dart';
import 'dart:math';
import 'fish.dart';
import 'database_helper.dart'; // Import the database helper

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

      // Add fish based on the saved count
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
        fish.moveFish(); // Move fish
      }
      if (collisionEffectEnabled) {
        _checkAllCollisions(); // Check for collisions if enabled
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
        fish1.color = Random().nextBool()
            ? Colors.red
            : Colors.green; // Random color change
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
      appBar: AppBar(
        title: Center(
          child: Text('Virtual Aquarium'),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                  height: screenHeight * 0.02), // Responsive space at the top

              // Container that represents the aquarium
              Center(
                child: Container(
                  width: screenWidth * 0.8, // 80% of the screen width
                  height: screenHeight * 0.4, // 40% of the screen height
                  decoration: BoxDecoration(
                    color: Colors.blue, // Set the aquarium background to blue
                    border: Border.all(color: Colors.white),
                    borderRadius:
                        BorderRadius.circular(15), // Rounded edges for aquarium
                  ),
                  child: Stack(
                    children: fishList.map((fish) => fish.buildFish()).toList(),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02), // Space after the aquarium

              // Buttons and settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _addFish,
                    child: Text('Add Fish'),
                  ),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: Text('Save Settings'),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.02), // Space after buttons

              // Slider to control fish speed
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal:
                        screenWidth * 0.1), // Padding based on screen width
                child: Slider(
                  value: selectedSpeed,
                  onChanged: (newSpeed) {
                    setState(() {
                      selectedSpeed = newSpeed;
                    });
                    _saveSettings(); // Save settings when speed changes
                  },
                  min: 0.5,
                  max: 3.0,
                  divisions: 5,
                  label: '$selectedSpeed',
                ),
              ),

              // Dropdown to select fish color with proper names
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal:
                        screenWidth * 0.1), // Padding based on screen width
                child: DropdownButton<Color>(
                  value:
                      selectedColor, // Ensure selectedColor matches one of the items below
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
                      selectedColor = color ??
                          Colors.red; // Default to red if color is null
                    });
                    _saveSettings(); // Save settings when color changes
                  },
                ),
              ),

              SizedBox(height: screenHeight * 0.02), // Space after dropdown

              // Toggle switch for enabling/disabling collision effect
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

          // Name and Panther ID centered at the bottom in a small rounded card
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                color: Colors.white
                    .withOpacity(0.8), // Slightly transparent background
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    'CW05 Mahendra Krishna',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
