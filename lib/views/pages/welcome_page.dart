import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:BasketballManager/views/pages/loading_page.dart';
import 'package:BasketballManager/views/pages/manager_creation_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lottie/Manager.json', repeat: false),
            FittedBox(
              child: Text(
              'Basketball Manager',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 100.0,
                letterSpacing: 10.0,
                ),
              ),
            ),
            SizedBox(height: 20),
            FilledButton( 
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ManagerProfilePage();
                    }
                  )
                );
              }, 
              child: Text("New Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return LoadingManagerProfilesPage();
                    }
                  )
                );
              }, 
              child: Text("Load"),
            ),
          ],
        ),
      )
    );
  }
}