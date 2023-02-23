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
      isAnalyzed = false
      ;

  String ingredients = "", nutritionTable = "", result = "";

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  Future<http.Response> analyse() {
    return http.post(
      Uri.parse('https://foodanalyzer-fast-api.onrender.com'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'ingredients': ingredients,
        'nutrition': nutritionTable,
      }),
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
            // options to be selected
            Row(
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        // text
                        Text("Nuts"),
                        // check box
                        Checkbox(
                          value: nuts,
                          onChanged: (value) {
                            setState(() {
                              nuts = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    // create a row for onion
                    Row(
                      children: [
                        // text
                        Text("Onion"),
                        // check box
                        Checkbox(
                          value: onion,
                          onChanged: (value) {
                            setState(() {
                              onion = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    // create a row for lactose
                    Row(
                      children: [
                        // text
                        Text("Lactose"),
                        // check box
                        Checkbox(
                          value: lactose,
                          onChanged: (value) {
                            setState(() {
                              lactose = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                // create a column for peanut, garlic and allergy
                Column(
                  children: [
                    // create a row for peanut
                    Row(
                      children: [
                        // text
                        Text("Peanut"),
                        // check box
                        Checkbox(
                          value: peanut,
                          onChanged: (value) {
                            setState(() {
                              peanut = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    // create a row for garlic
                    Row(
                      children: [
                        // text
                        Text("Garlic"),
                        // check box
                        Checkbox(
                          value: garlic,
                          onChanged: (value) {
                            setState(() {
                              garlic = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    // create a row for allergy
                    Row(
                      children: [
                        // text
                        Text("Allergy"),
                        // check box
                        Checkbox(
                          value: allergy,
                          onChanged: (value) {
                            setState(() {
                              allergy = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // create a widget for camera and scan button
            Container(
              width: 400,
              height: 400,
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    // If the Future is complete, display the preview.
                    return CameraPreview(_controller);
                  } else {
                    // Otherwise, display a loading indicator.
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),

            // create a button for scan
            finalIngredients & tableImage
                ? ElevatedButton(
                    onPressed: () async {
                      // send get request to https://foodanalyzer-fast-api.onrender.com
                      final response = await analyse();
                      FoodResponse foodResponse =
                          FoodResponse.fromJson(jsonDecode(response.body));
                      

                      if (kDebugMode) {
                        print(foodResponse.good_ingrediants[0]['250']);
                      }
                      setState(() {
                        isAnalyzed = true;
                        result = response.body.toString();
                      });
                    },
                    child: Text("Analyse"))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _initializeControllerFuture;
                            await _controller.setFlashMode(FlashMode.off);
                            final image = await _controller.takePicture();

                            if (!mounted) return;

                            InputImage inputImage =
                                InputImage.fromFilePath(image.path);

                            final textRecognizer = TextRecognizer(
                                script: TextRecognitionScript.latin);

                            final RecognizedText recognizedText =
                                await textRecognizer.processImage(inputImage);

                            String text = recognizedText.text;

                            if (kDebugMode) {
                              print(text);
                            }

                            textRecognizer.close();

                            // If the picture was taken, display it on a new screen.
                            setState(() {
                              imageTaken = true;
                              if (finalIngredients) {
                                nutritionTable = text.replaceAll("\n", " ");
                                tableImage = true;
                              } else {
                                ingredients = text.replaceAll("\n", " ");
                              }
                            });
                          } catch (e) {
                            // If an error occurs, log the error to the console.
                            if (kDebugMode) {
                              print(e);
                            }
                          }
                        },
                        child: Text(imageTaken
                            ? finalIngredients
                                ? "Scan Nutrition Table"
                                : 'Scan Again'
                            : 'Scan'),
                      ),

                      // a button for final ingredients
                      imageTaken
                          ? ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  finalIngredients = true;
                                });
                                if (kDebugMode) {
                                  print(ingredients);
                                }
                              },
                              child: Text("Finalize Ingredients"),
                            )
                          : Container(),
                    ],
                  ),

            isAnalyzed ? Text(result) : Container(),

            // finalIngredients ? Text(ingredients) : Container(),

            // tableImage ? Text(nutritionTable) : Container(),
          ],
        ),
      ),
    );
  }
}
