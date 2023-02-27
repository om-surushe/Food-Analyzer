import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:nutriscan/food_response.dart';
import 'package:path/path.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  final firstCamera = cameras.first;

  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.green,
    ),
    home: MyHomePage(title: 'NutriScan', camera: firstCamera),
  ));
}

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//       ),
//       home: MyHomePage(title: 'NutriScan'),
//     );
//   }
// }

class MyHomePage extends StatefulWidget {
  String title;
  final CameraDescription camera;
  MyHomePage({super.key, required this.title, required this.camera});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool nuts = false,
      onion = false,
      lactose = false,
      peanut = false,
      garlic = false,
      allergy = false,
      finalIngredients = false,
      imageTaken = false,
      tableImage = false,
      isAnalyzed = false;

  String ingredients = "", nutritionTable = "", result = "";

  // save the current photo ans show it
  late File _imageFile;

  late FoodResponse food;

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  Future<http.Response> analyse() {
    var body = tableImage
        ? jsonEncode({
            "ingredients": ingredients,
            "nutrition": nutritionTable,
          })
        : jsonEncode({
            "ingredients": ingredients,
          });
    return http.post(
      Uri.parse('https://foodanalyzer-fast-api.onrender.com'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // keep the app bar title in the center
        title: Text(widget.title, style: TextStyle(color: Colors.black)),

        // keep the app bar title in the center
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // message to be shown
            finalIngredients & tableImage
                ? Text(
                    "Scan Nutrition Table",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : finalIngredients
                    ? Text(
                        "Scan Nutrition Table",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        "Scan Ingredients",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

            // create a widget for camera and scan button
            Padding(
              padding: const EdgeInsets.only(
                  top: 10.0, left: 20, right: 20, bottom: 10),
              child: SizedBox(
                height: 300,
                child: imageTaken
                    ?
                    // show the image
                    Image.file(_imageFile)
                    : FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            // If the Future is complete, display the preview.
                            return CameraPreview(_controller);
                          } else {
                            // Otherwise, display a loading indicator.
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        },
                      ),
              ),
            ),

            // create a button for scan
            finalIngredients & tableImage
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Scan Nutrition Table again button
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            tableImage = false;
                            imageTaken = false;
                          });
                        },
                        child: Text("Retake"),
                      ),
                      ElevatedButton(
                          onPressed: () async {
                            final textRecognizer = TextRecognizer(
                                script: TextRecognitionScript.latin);

                            final RecognizedText recognizedText =
                                await textRecognizer.processImage(
                                    InputImage.fromFilePath(_imageFile.path));

                            String text = recognizedText.text;

                            setState(() {
                              nutritionTable = text.replaceAll("\n", " ");
                              tableImage = true;
                            });

                            // send get request to https://foodanalyzer-fast-api.onrender.com
                            final response = await analyse();
                            FoodResponse foodResponse = FoodResponse.fromJson(
                                jsonDecode(response.body));

                            if (kDebugMode) {
                              print(foodResponse);
                            }
                            setState(() {
                              isAnalyzed = true;
                              result = response.body.toString();
                              food = foodResponse;
                            });
                          },
                          child: Text("Analyse")),
                    ],
                  )
                : finalIngredients
                    ? Row(
                        // scan nutrition table or skip button
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            child: Text("Scan"),
                            onPressed: () async {
                              final image = await _controller.takePicture();

                              if (!mounted) return;
                              InputImage inputImage = InputImage.fromFilePath(
                                  image.path); // a File object

                              // set the new image to the image file and show it
                              setState(() {
                                tableImage = true;
                                _imageFile = File(image.path);
                                imageTaken = true;
                              });
                            },
                          ),

                          // skip button
                          ElevatedButton(
                            child: Text("Skip"),
                            onPressed: () async {
                              // send get request to https://foodanalyzer-fast-api.onrender.com
                              final response = await analyse();
                              FoodResponse foodResponse = FoodResponse.fromJson(
                                  jsonDecode(response.body));

                              if (kDebugMode) {
                                print(foodResponse);
                              }
                              setState(() {
                                isAnalyzed = true;
                                result = response.body.toString();
                                food = foodResponse;
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // make button to scan again
                          imageTaken
                              ? ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      imageTaken = false;
                                    });
                                  },
                                  child: Text("Retake"),
                                )
                              : ElevatedButton(
                                  child: Text("Scan"),
                                  onPressed: () async {
                                    try {
                                      await _initializeControllerFuture;
                                      await _controller
                                          .setFlashMode(FlashMode.off);
                                      final image =
                                          await _controller.takePicture();

                                      if (!mounted) return;
                                      InputImage inputImage =
                                          InputImage.fromFilePath(
                                              image.path); // a File object
                                      // set the new image to the image file and show it
                                      setState(() {
                                        imageTaken = true;
                                        _imageFile = File(image.path);
                                      });
                                    } catch (e) {
                                      // If an error occurs, log the error to the console.
                                      print(e);
                                    }
                                  },
                                ),

                          // a button for final ingredients
                          imageTaken
                              ? ElevatedButton(
                                  onPressed: () async {
                                    // get the ingredients from the image
                                    final textRecognizer = TextRecognizer(
                                        script: TextRecognitionScript.latin);

                                    final RecognizedText recognizedText =
                                        await textRecognizer.processImage(
                                            InputImage.fromFilePath(
                                                _imageFile.path));

                                    String text = recognizedText.text;
                                    setState(() {
                                      finalIngredients = true;
                                      ingredients = text.replaceAll("\n", " ");
                                      imageTaken = false;
                                    });
                                    if (kDebugMode) {
                                      print(ingredients);
                                    }
                                  },
                                  child: Text("Next"),
                                )
                              : Container(),
                        ],
                      ),

            isAnalyzed ? AnalysisWidget(foodResponse: food) : Container(),

            // finalIngredients ? Text(ingredients) : Container(),

            // tableImage ? Text(nutritionTable) : Container(),
          ],
        ),
      ),
    );
  }
}

// make a stateful widget for showing the analysis on FoodResponse
class AnalysisWidget extends StatefulWidget {
  final FoodResponse foodResponse;
  const AnalysisWidget({super.key, required this.foodResponse});

  @override
  State<AnalysisWidget> createState() => _AnalysisWidgetState();
}

class _AnalysisWidgetState extends State<AnalysisWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: [
        const Text("Analysis"),
        // make a horizontal card showing weather it has onion or not
        // hasNuts;
        Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Nuts"),
              Icon(widget.foodResponse.hasNuts ? Icons.check : Icons.close),
            ],
          ),
        ),
        // hasOnion;
        Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Onion"),
              Icon(widget.foodResponse.hasOnion ? Icons.check : Icons.close),
            ],
          ),
        ),
        // hasGarlic;
        Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Garlic"),
              Icon(widget.foodResponse.hasGarlic ? Icons.check : Icons.close),
            ],
          ),
        ),
        // hasLactose;
        Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Lactose"),
              Icon(widget.foodResponse.hasLactose ? Icons.check : Icons.close),
            ],
          ),
        ),
        // hasAllergen;
        Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Allergen"),
              Icon(widget.foodResponse.hasAllergen ? Icons.check : Icons.close),
            ],
          ),
        ),
        // hasPeanut;
        Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Peanut"),
              Icon(widget.foodResponse.hasPeanut ? Icons.check : Icons.close),
            ],
          ),
        ),

        // if length is greater than 1, show the rest of the ingredients
        if (widget.foodResponse.goodIngrediants.length > 1)
          for (var i = 0;
              i < widget.foodResponse.goodIngrediants.length;
              i++)
            ExpandedIngredients(
              ingredient: widget.foodResponse.goodIngrediants[i][0].toString(),
              description: widget.foodResponse.goodIngrediants[i][1].toString(),
              color: Colors.green,
            ),

        // if length is greater than 1, show the rest of the ingredients
        if (widget.foodResponse.badIngrediants.length > 1)
          for (var i = 0;
              i < widget.foodResponse.badIngrediants.length;
              i++)
            ExpandedIngredients(
              ingredient: widget.foodResponse.badIngrediants[i][0].toString(),
              description: widget.foodResponse.badIngrediants[i][1].toString(),
              color: Colors.red,
            ),
      ],
    ));
  }
}

// make a statefull expandable widget for showing the ingredients
class ExpandedIngredients extends StatefulWidget {
  // ingredient, description
  final String ingredient;
  final String description;
  Color color;
  bool isExpanded = false;
  ExpandedIngredients(
      {super.key, required this.ingredient,required this.description , required this.color});

  @override
  State<ExpandedIngredients> createState() => _ExpandedIngredientsState();
}

class _ExpandedIngredientsState extends State<ExpandedIngredients> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            widget.isExpanded = !widget.isExpanded;
          });
        },
        child: Container(
          color: widget.color,
          child: Column(
            children: [
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.ingredient),
                    Icon(widget.isExpanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
              widget.isExpanded ? Text(widget.description) : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
