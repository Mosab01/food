import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => MealOrderModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MealOrderPage(),
    );
  }
}

class MealOrderModel with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  // Constructor
  MealOrderModel() {
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    _user = _auth.currentUser;
    notifyListeners();
  }

  String get currentUserId => _user?.uid ?? 'Unknown UserID';

  List<Map<String, dynamic>> meals = [];
  bool isLoading = true;

  Future<void> fetchMeals() async {
    var url = Uri.parse('http://10.0.2.2:3000/meals');
    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as List;
        meals = data
            .map((meal) => {
                  'id': meal['_id']?.toString() ?? 'Unknown ID',
                  'name': meal['name']?.toString() ?? 'Unknown Name',
                  'price': meal['price'] ?? 0,
                  'description': meal['description']?.toString() ??
                      'No description available',
                  'image': meal['image']?.toString() ?? '',
                })
            .toList();
        isLoading = false;
        notifyListeners();
      } else {
        print('Failed to load meals. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }

  Future<void> placeOrder(String mealId) async {
    var url = Uri.parse('http://10.0.2.2:3000/orders');

    var orderData = {
      'customerId': "23984789237423", 
      'mealId': mealId,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        print('Order placed successfully');
      } else {
        print('Failed to place order. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }
}

class MealOrderPage extends StatefulWidget {
  @override
  _MealOrderPageState createState() => _MealOrderPageState();
}

class _MealOrderPageState extends State<MealOrderPage> {
  @override
  void initState() {
    super.initState();
    Provider.of<MealOrderModel>(context, listen: false).fetchMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Meal')),
      body: Consumer<MealOrderModel>(
        builder: (context, mealOrderModel, child) {
          return mealOrderModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: mealOrderModel.meals.length,
                  itemBuilder: (context, index) {
                    var meal = mealOrderModel.meals[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            meal['image'] != ''
                                ? Image.network(meal['image'])
                                : Container(
                                    height: 200,
                                    color: Colors.grey,
                                    child: const Center(
                                        child: Text('No Image Available')),
                                  ),
                            const SizedBox(height: 10),
                            Text(meal['name'],
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text('\$${meal['price']}',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 5),
                            Text(meal['description'],
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  Provider.of<MealOrderModel>(context,
                                          listen: false)
                                      .placeOrder(meal['id']);
                                },
                                child: const Text('Order'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}
