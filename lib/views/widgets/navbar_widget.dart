import 'package:flutter/material.dart';
import 'package:test1/data/notifiers.dart';

class NavBarWidget extends StatelessWidget {
  const NavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return  NavigationBar(
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home), 
              label: 'Home',),
            NavigationDestination(
              icon: Icon(Icons.group), 
              label: 'Team Profile',),
            NavigationDestination(
              icon: Icon(Icons.person), 
              label: 'Coach Profile',),
            
          ],
          onDestinationSelected: (int value) {
            selectedPageNotifier.value = value;
          },
          selectedIndex: selectedPage, 
        );
      },
    );
  }
}