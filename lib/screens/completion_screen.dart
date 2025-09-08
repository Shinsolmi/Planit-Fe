import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'mypage_screen.dart';
import 'transportation_screen.dart';
import 'profile_guest_screen.dart';
import '../env.dart';

class CompletionScreen extends StatefulWidget {
  @override
  _CompletionScreenState createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  List<dynamic> itinerary = [];
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchItinerary();
  }

  Future<void> fetchItinerary() async {
    final url = Uri.parse('$baseUrl'); // 여기 수정하셈 !!!!!!!!!!!!!!!!!
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          itinerary = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load itinerary');
      }
    } catch (e) {
      print('Error fetching itinerary: $e');
      setState(() => isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TransportSelectionPage()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MypageScreen()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileGuestScreen())),
          child: Text('PLANIT'),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : itinerary.isEmpty
              ? Center(child: Text('일정 데이터가 없습니다.'))
              : ListView.builder(
                  itemCount: itinerary.length,
                  itemBuilder: (context, index) {
                    final dayPlan = itinerary[index];
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Day ${dayPlan["day"]}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ...List<Widget>.from(dayPlan['plan'].map<Widget>((item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Text(item['time'], style: TextStyle(fontWeight: FontWeight.bold)),
                                    title: Text(item['place']),
                                    subtitle: Text(item['memo']),
                                  )))
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.directions_transit), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
