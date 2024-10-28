import 'package:flutter/material.dart';
import '../authentication_process/login.dart';  // Import the login page
import '../authentication_process/signup.dart';  // Import the signup page

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  final List<Map<String, String>> _splashData = [
    {
      'image': 'images/counseling.png',
      'description': 'We solve nutrition issues for those who struggle with managing their nutrition and diet.'
    },
    {
      'image': 'images/nutritionist.png',
      'description': 'We provide personalized meal plans from professionals who design the best plans suited for you.'
    },
    {
      'image': 'images/online-consultation.png',
      'description': 'We provide online consultation services, saving time and travel costs with flexible scheduling.'
    },
    {
      'image': 'images/appointment.png',
      'description': 'We offer appointments to consult with our specialists.'
    },
    {
      'image': 'images/BMI Tracker.png',
      'description': 'We offer several features to support your diet journey, such as a BMI tracker and diet tracker.'
    }
  ];
  
  int _currentPage = 0;
  bool _isHoveredLogin = false;
  bool _isHoveredSignUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _splashData.length,
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    _splashData[index]['image']!,
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _splashData[index]['description']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 90, 113, 243),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
          // Positioned logo at the top right corner
          Positioned(
            top: 20,
            // right: 20,
            child: Image.asset(
              'images/Logo-rounded.png',
              width: MediaQuery.of(context).size.width * 0.2,
              height: MediaQuery.of(context).size.width * 0.2,
            ),
          ),
          // Dots indicator
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _splashData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: _currentPage == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Buttons at the bottom side by side
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Login button
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveredLogin = true),
                    onExit: (_) => setState(() => _isHoveredLogin = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _isHoveredLogin ? Colors.blueAccent : const Color.fromARGB(255, 90, 113, 243),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          if (_isHoveredLogin)
                            const BoxShadow(
                              color: Colors.blueAccent,
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      child: const Text(
                        'Login',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
                // Sign Up button
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupPage()),
                    );
                  },
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveredSignUp = true),
                    onExit: (_) => setState(() => _isHoveredSignUp = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _isHoveredSignUp ? Colors.blueAccent : const Color.fromARGB(255, 90, 113, 243),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          if (_isHoveredSignUp)
                            const BoxShadow(
                              color: Colors.blueAccent,
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
