import 'package:aplikasi_kontrakan/pages/daftar_kamar.dart';
import 'package:aplikasi_kontrakan/pages/histori.dart';
import 'package:aplikasi_kontrakan/pages/list_penghuni.dart';
import 'package:flutter/material.dart';

class NavMenu extends StatefulWidget {
  const NavMenu({super.key});

  @override
  State<NavMenu> createState() => _NavMenuState();
}

class _NavMenuState extends State<NavMenu> {
  int myCurrentIndex = 0;
  List pages = const [DaftarKamar(), ListPenghuni(), Histori()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: myCurrentIndex,
          onTap: (index) {
            setState(() {
              myCurrentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Kamar"),
            BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Penghuni"),
            BottomNavigationBarItem(
              icon: Icon(Icons.history), label: "Histori"),
          ]),
      body: pages[myCurrentIndex],
    );
  }
}
