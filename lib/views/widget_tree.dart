import 'package:flutter/material.dart';
import 'package:BasketballManager/data/notifiers.dart';
import 'package:BasketballManager/gameData/game_class.dart';
import 'package:BasketballManager/views/pages/home_page.dart';
import 'package:BasketballManager/views/pages/match_history_page.dart';
import 'package:BasketballManager/views/pages/profile_page.dart';
import 'package:BasketballManager/views/pages/team_view_page.dart';
import 'package:BasketballManager/views/widgets/navbar_widget.dart';




class WidgetTree extends StatelessWidget {
  final Game game;  // This is the object the widget will accept
  
  const WidgetTree({super.key, required this.game});

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
      title: Text('Basketball Manager'),
      centerTitle: true,
    ),
      drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 59, 34, 104),
            ),
            child: Text(
              'Manager Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Match History'),
            onTap: () {
              // Navigate to MatchHistoryPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchHistoryPage(conference: game.currentConference),
                ),
              );
            },
          ),
        ],
      ),
    ),
        body : ValueListenableBuilder(
          valueListenable: selectedPageNotifier,
          builder: (context, selectedPage, child) {
            List<Widget> pages = [
              HomePage(game: game),
              TeamViewPage(team: game.currentConference.teams[game.currentManager.team]),
              ProfilePage(game: game),
            ];
            return  pages.elementAt(selectedPage);
          },
        ),
        bottomNavigationBar: NavBarWidget(),
      );
  }
}