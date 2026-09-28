import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() =>
      _FirestoreTestScreenState();
}

class _FirestoreTestScreenState
    extends State<FirestoreTestScreen> {
  bool _loading = false;
  String _message = 'Ready to test Firestore';

  Future<void> _testFirestore() async {
    setState(() {
      _loading = true;
      _message = 'Testing Firestore...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'No user is logged in. Please login first.',
        );
      }

      final uid = user.uid;

      // 1. Create / update owner document
      await FirebaseFirestore.instance
          .collection('owners')
          .doc(uid)
          .set({
        'uid': uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Create test property
      await FirebaseFirestore.instance
          .collection('owners')
          .doc(uid)
          .collection('properties')
          .doc('test_property_001')
          .set({
        'ownerId': uid,
        'name': 'Test Property',
        'type': 'PG',
        'address': 'Test Address',
        'city': 'Bangalore',
        'state': 'Karnataka',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Read properties
      final snapshot = await FirebaseFirestore.instance
          .collection('owners')
          .doc(uid)
          .collection('properties')
          .get();

      setState(() {
        _message =
            'SUCCESS!\n\n'
            'Owner UID:\n$uid\n\n'
            'Properties found: ${snapshot.docs.length}\n\n'
            'Firestore write + read working.';
      });
    } catch (e) {
      setState(() {
        _message =
            'Firestore test failed:\n\n$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Firebase / Firestore Connection Test',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed:
                  _loading ? null : _testFirestore,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'TEST FIRESTORE',
                    ),
            ),

            const SizedBox(height: 30),

            SelectableText(
              _message,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}