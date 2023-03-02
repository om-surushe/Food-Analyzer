import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

// Camera and OCR
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// FoodResponse Model
import 'package:nutriscan/food_response.dart';

Future<void> main() async {
  // Initialize the camera
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras[0];

  runApp(MaterialApp(
    title: 'NutriScan',
    theme: ThemeData(
      primarySwatch: Colors.green,
    ),
    home: MyHomePage(title: 'NutriScan', camera: firstCamera),
  ));
}

class MyHomePage extends StatefulWidget {
  // This widget is the home page of your application.
  final String title; // title of the app
  final CameraDescription camera; // camera to be used
  const MyHomePage({super.key, required this.title, required this.camera});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // variables to be used
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

  // ingredients and nutrition table
  String ingredients = "", nutritionTable = "", result = "";

  // save the current photo ans show it
  late File _imageFile;

  // food response
  late FoodResponse food;

  // camera controller
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  // function to send post request to the api
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
    // initialize the camera controller
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // set the app bar title
        title: Text(widget.title, style: const TextStyle(color: Colors.black)),

        // set the app bar background color
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // check if the ingredients and nutrition table are scanned
            finalIngredients & tableImage
                ?
                // if yes, show the result
                const Text(
                    "Scan Nutrition Table",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                :
                // if only ingredients are scanned, show the scan nutrition table button
                finalIngredients
                    ? const Text(
                        "Scan Nutrition Table",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    :
                    // if nothing is scanned, show the scan ingredients button
                    const Text(
                        "Scan Ingredients",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

            // show the image taken
            Padding(
              padding: const EdgeInsets.only(
                  top: 10.0, left: 20, right: 20, bottom: 10),
              child: SizedBox(
                height: 300,
                child:
                    // check if the image is taken
                    imageTaken
                        ?
                        // if yes, show the image
                        Image.file(_imageFile)
                        :
                        // if no, show the camera preview
                        FutureBuilder<void>(
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

            // check if the ingredients and nutrition table are scanned
            finalIngredients & tableImage
                ?
                // if yes, show the result
                Row(
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
                        child: const Text("Retake"),
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
                          // Analyse button to send the request
                          child: const Text("Analyse")),
                    ],
                  )
                :
                // if only ingredients are scanned, show the scan nutrition table button
                finalIngredients
                    ? Row(
                        // scan nutrition table or skip button
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // scan nutrition table button
                          ElevatedButton(
                            child: const Text("Scan"),
                            onPressed: () async {
                              final image = await _controller.takePicture();

                              if (!mounted) return;
// a File object

                              // set the new image to the image file and show it
                              setState(() {
                                tableImage = true;
                                _imageFile = File(image.path);
                                imageTaken = true;
                              });
                            },
                          ),

                          // skip button to send the request without nutrition table
                          ElevatedButton(
                            child: const Text("Skip"),
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
                          // scan ingredients button
                          imageTaken
                              ? ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      imageTaken = false;
                                    });
                                  },
                                  child: const Text("Retake"),
                                )
                              : ElevatedButton(
                                  child: const Text("Scan"),
                                  onPressed: () async {
                                    try {
                                      // Ensure that the camera is initialized.
                                      // turn off the flash
                                      await _initializeControllerFuture;
                                      await _controller
                                          .setFlashMode(FlashMode.off);
                                      final image =
                                          await _controller.takePicture();

                                      if (!mounted) return;
// a File object
                                      // set the new image to the image file and show it
                                      setState(() {
                                        imageTaken = true;
                                        _imageFile = File(image.path);
                                      });
                                    } catch (e) {
                                      // If an error occurs, log the error to the console.
                                      if (kDebugMode) {
                                        print(e);
                                      }
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
                                      // set the ingredients to the text
                                      finalIngredients = true;
                                      ingredients = text.replaceAll("\n", " ");
                                      imageTaken = false;
                                    });
                                    if (kDebugMode) {
                                      print(ingredients);
                                    }
                                  },
                                  child: const Text("Next"),
                                )
                              : Container(),
                        ],
                      ),

            isAnalyzed ? AnalysisWidget(foodResponse: food) : Container(),
          ],
        ),
      ),
    );
  }
}

// make a stateful widget for showing the analysis on FoodResponse
class AnalysisWidget extends StatefulWidget {
  // get the food response from the parent widget and fill it in a model
  final FoodResponse foodResponse;
  const AnalysisWidget({super.key, required this.foodResponse});

  @override
  State<AnalysisWidget> createState() => _AnalysisWidgetState();
}

class _AnalysisWidgetState extends State<AnalysisWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Analysis"),

        // card which shows the name of the food is present or not

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
          for (var i = 0; i < widget.foodResponse.goodIngrediants.length; i++)
            ExpandedIngredients(
              ingredient: widget.foodResponse.goodIngrediants[i][0].toString(),
              description: widget.foodResponse.goodIngrediants[i][1].toString(),
              color: Colors.green,
            ),

        // if length is greater than 1, show the rest of the ingredients
        if (widget.foodResponse.badIngrediants.length > 1)
          for (var i = 0; i < widget.foodResponse.badIngrediants.length; i++)
            ExpandedIngredients(
              ingredient: widget.foodResponse.badIngrediants[i][0].toString(),
              description: widget.foodResponse.badIngrediants[i][1].toString(),
              color: Colors.red,
            ),

        // if (widget.foodResponse.hasSodium)
          Quantity(
            percent: widget.foodResponse.sodiumuPercentage.toDouble(),
            max: 100,
            amount: widget.foodResponse.sodiumQuantity.toDouble(),
            name: "Sodium",
          ),

        // if (widget.foodResponse.hasSugar)
          Quantity(
            percent: widget.foodResponse.sugarPercentage.toDouble(),
            max: 100,
            amount: widget.foodResponse.sugarQuantity.toDouble(),
            name: "Sugar",
          ),

        // if (widget.foodResponse.hasCarbs)
          Quantity(
            percent: widget.foodResponse.carbsPercentage.toDouble(),
            max: 100,
            amount: widget.foodResponse.carbsQuantity.toDouble(),
            name: "Carbs",
          ),

        // add padding in the bottom
        const SizedBox(
          height: 10,
        )
      ],
    );
  }
}

// make a statefull expandable widget for showing the ingredients
class ExpandedIngredients extends StatefulWidget {
  // ingredient, description
  final String ingredient;
  final String description;
  final Color color;
  const ExpandedIngredients(
      {super.key,
      required this.ingredient,
      required this.description,
      required this.color});

  @override
  State<ExpandedIngredients> createState() => _ExpandedIngredientsState();
}

class _ExpandedIngredientsState extends State<ExpandedIngredients> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: Container(
          color: widget.color,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.ingredient),
                  Icon(isExpanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                ],
              ),
              isExpanded ? Text(widget.description) : Container(),
            ],
          ),
        ),
      ),
    );
  }
}

// make a stateful widget for showing the percentage of sodium with progress bar, and the amount of sodium
class Quantity extends StatefulWidget {
  final double percent;
  final double max;
  final double amount;
  final String name;
  const Quantity(
      {super.key,
      required this.percent,
      required this.max,
      required this.amount,
      required this.name});

  @override
  State<Quantity> createState() => _QuantityState();
}

class _QuantityState extends State<Quantity> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(widget.name),
          LinearProgressIndicator(
            value: widget.amount / widget.max,
          ),
          Text(widget.amount.toString()),
        ],
      ),
    );
  }
}
