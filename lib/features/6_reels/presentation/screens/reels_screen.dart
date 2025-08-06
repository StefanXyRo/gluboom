// FILE: lib/features/6_reels/presentation/screens/reels_screen.dart
// Creează acest fișier nou în locația specificată.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/reel_model.dart';
import '../widgets/reel_player_widget.dart'; // Vom crea acest widget

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Am eliminat Scaffold-ul pentru a evita imbricarea și conflictele de temă.
    // Culoarea de fundal va fi gestionată de HomeScreen.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reels')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Niciun Reel disponibil.', style: TextStyle(color: Colors.white)));
        }

        final reels = snapshot.data!.docs.map((doc) => ReelModel.fromFirestore(doc)).toList();

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: reels.length,
          itemBuilder: (context, index) {
            return ReelPlayer(reel: reels[index]);
          },
        );
      },
    );
  }
}
