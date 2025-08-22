import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            '''
Your Terms & Conditions go here.

1. Introduction
2. User Responsibilities
3. Payment Terms
4. Delivery Policy
5. ...etc.
''',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      ),
    );
  }
}