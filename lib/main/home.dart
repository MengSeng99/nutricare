import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../food_recipe/food_recipe.dart';
import 'articles.dart';
import 'virtual_consultation.dart';
import '../specialist/specialist_lists.dart';
import '../bmi_features/bmi_tracker.dart';
import '../health_record/health_record.dart';

// Removed the dummy data definition

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late Timer _timer;
  List<Map<String, dynamic>> _articles = []; 
  String _greetingWithUserName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentIndex = 0;

    // Fetch articles from Firestore
    _fetchArticles();

       // Fetch greeting with username once
    _fetchGreetingWithUserName();


    // Timer to change pages automatically
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentIndex < _articles.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0; // Restart from the beginning
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {}); // Update the UI
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel(); // Dispose of the timer
    super.dispose();
  }

  Future<void> _fetchArticles() async {
  try {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('articles').get();
    setState(() {
      _articles = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title'] as String,
          'description': doc['description'] as String,
          'imageUrl': doc['imageUrl'] as String,
          'postDate': doc['postDate'] is Timestamp ? doc['postDate'] : Timestamp.now(), // Check if Timestamp exists
          'specialistId': doc['specialistId'] as String? ?? '', // Handle null case
        };
      }).toList().where((article) => article['specialistId'].isNotEmpty).toList(); // Ensure specialistId is not empty
    });
  } catch (e) {
    // print("Error fetching articles: $e");
    // Handle error here
  }
}

  // Determine greeting based on the current time
  String _getGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    return greeting;
  }

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userData['name'];
    }
    return 'Guest';
  }

  Future<void> _fetchGreetingWithUserName() async {
    final greeting = _getGreeting();
    final userName = await _getUserName();
    setState(() {
      _greetingWithUserName = '$greeting, $userName';
    });
  }

  // Function to build articles and blogs section with pagination
  Widget _buildArticlesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        //   child: Text(
        //     'Articles and Blogs',
        //     style: TextStyle(
        //       fontSize: 22,
        //       fontWeight: FontWeight.bold,
        //       color: Color.fromARGB(255, 73, 73, 73),
        //     ),
        //   ),
        // ),
        Container(
          height: MediaQuery.of(context).size.height *
              0.25, // Adjust height to fit your design
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _articles.length,
            itemBuilder: (context, index) {
              return _buildArticleCard(_articles[index]);
            },
          ),
        ),
        const SizedBox(height: 10), // Space before indicators
        _buildPageIndicators(),
      ],
    );
  }

  // Build page indicators
  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_articles.length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == index
                ? const Color.fromARGB(255, 90, 113, 243) // Selected color
                : Colors.grey, // Unselected color
          ),
        );
      }),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
  return GestureDetector(
    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ArticleScreen(
        title: article['title']!,
        imageUrl: article['imageUrl']!,
        postDate: article['postDate'],
        specialistId: article['specialistId'],
        articleId: article['id'],
      ),
    ),
  );
},
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Add margin here
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey[400]!), // Light grey border
        image: DecorationImage(
          image: NetworkImage(article['imageUrl']!), // Load image from URL
          fit: BoxFit.cover, // Cover the whole card
        ),
      ),
      child: Stack(
        children: [
          // Semi-transparent black overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.black.withOpacity(0.2), // Adjust opacity to your liking
            ),
          ),
          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.end, // Align children at the bottom
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      article['title']!,
                      style: const TextStyle(
                        fontSize: 18, // Increased font size for better visibility
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black, // Shadow color
                            blurRadius: 4.0, // Shadow blur radius
                            offset: Offset(2.0, 2.0), // Shadow offset
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6), // Space between title and description
                    // Description
                    Text(
                      article['description']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4.0,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                      maxLines: 4, // Limit to 4 lines
                      overflow: TextOverflow.ellipsis, // Show ellipsis if text overflows
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  // List of services with icons and descriptions
  final List<Map<String, dynamic>> _services = const [
    {'icon': Icons.fastfood_rounded, 'label': 'Food Recipe'},
    {'icon': Icons.calendar_today_rounded, 'label': 'Book an Appointment'},
    {'icon': Icons.monitor_weight_rounded, 'label': 'BMI Tracker'},
    {'icon': Icons.book_rounded, 'label': 'Health Records'},
  ];

  // List of consultation options with images and descriptions
  final List<Map<String, dynamic>> _consultations = const [
    {
      'image': 'images/dietitian.png',
      'title': 'Dietitian',
      'description':
          'Get advice from certified dietitians on meal plans and dietary needs.',
    },
    {
      'image': 'images/nutritionist-2.png',
      'title': 'Nutritionist',
      'description':
          'Consult with professional nutritionists for personalized diet guidance.',
    },
  ];

  // Build the horizontal services list
  Widget _buildServicesBar(BuildContext context) {
    return SizedBox(
      height: 113,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _services.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              if (_services[index]['label'] == 'Book an Appointment') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VirtualConsultationScreen()),
                );
              } else if (_services[index]['label'] == 'BMI Tracker') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BmiTrackerScreen()),
                );
              } else if (_services[index]['label'] == 'Food Recipe') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FoodRecipeScreen()),
                );
              } else if (_services[index]['label'] == 'Health Records') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HealthRecordScreen()),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                children: [
                  // Icon container with a modern card-like design
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Icon(
                      _services[index]['icon'],
                      color: const Color.fromARGB(255, 90, 113, 243),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _services[index]['label'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Build the horizontal virtual consultation section
  Widget _buildConsultationBar(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _consultations.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingAppointmentScreen(
                    title: _consultations[index]['title'],
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildConsultationBox(
                _consultations[index]['image'],
                _consultations[index]['title'],
                _consultations[index]['description'],
              ),
            ),
          );
        },
      ),
    );
  }

  // Function to create individual consultation boxes
  Widget _buildConsultationBox(
      String imagePath, String title, String description) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _greetingWithUserName,
          style: const TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArticlesSection(context),
              const SizedBox(height: 20), // Space between sections
              _buildServicesBar(context),
              const SizedBox(height: 20), // Space between sections
              // Virtual Consultation Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Virtual Consultation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 73, 73, 73),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward,
                          color: Color.fromARGB(255, 90, 113, 243)),
                      onPressed: () {
                        // Navigate to Virtual Consultation screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const VirtualConsultationScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(
                  height: 10), // Space between header and consultation list
              _buildConsultationBar(context),
            ],
          ),
        ),
      ),
    );
  }
}
