import 'package:flutter/material.dart';
import 'package:google_maps_webservice2/places.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'address_autocomplete.dart';

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final addressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('배송지 목록')),
      body: StreamBuilder<QuerySnapshot>(
        stream: addressRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('저장된 배송지가 없습니다.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final display =
                  '${data['recipient']} ${data['phone'] ?? ''}\n${data['address']} ${data['detail'] ?? ''}';

              return Dismissible(
                key: Key(docId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('addresses')
                      .doc(docId)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('주소가 삭제되었습니다.')),
                  );
                },
                child: ListTile(
                  title: Text(display),
                  onTap: () {
                    Navigator.pop(context, data);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddressAutocompleteScreen(),
            ),
          );

          if (result != null && context.mounted) {
            Navigator.pop(context, result); // 새 주소도 즉시 선택으로 반환
          }
        },
      ),
    );
  }
}
