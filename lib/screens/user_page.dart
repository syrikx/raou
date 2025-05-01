import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/state_provider.dart'; // AppStateProvider
import 'address_list.dart';
import '../services/auth_service.dart';
import '../utils/helper.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  Future<void> _loadDefaultAddress(BuildContext context, String uid) async {
    final defaultSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .orderBy('timeSetDefault', descending: true)
        .limit(1)
        .get();

    if (!context.mounted) return; // `context.mounted` 체크로 안전하게 실행

    if (defaultSnapshot.docs.isNotEmpty) {
      final data = defaultSnapshot.docs.first.data();
      context.read<AppStateProvider>().setAddress(Map<String, dynamic>.from(data));
    } else {
      final fallbackSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (!context.mounted) return; // `context.mounted` 체크로 안전하게 실행

      if (fallbackSnapshot.docs.isNotEmpty) {
        final data = fallbackSnapshot.docs.first.data();
        context.read<AppStateProvider>().setAddress(Map<String, dynamic>.from(data));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStateProvider>().currentUser;
    final address = context.watch<AppStateProvider>().selectedAddress;
    final addressSummary = address != null
        ? '${address['recipient']} ${address['phone'] ?? ''}\n${address['address']} ${address['detail'] ?? ''}'
        : '기본 배송지가 설정되지 않았습니다';

    // 비동기 작업이 끝난 후 위젯이 화면에 그려진 후 작업
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null && context.mounted) {
        _loadDefaultAddress(context, user.uid); // 안전하게 주소 로딩
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('마이 페이지')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null
            ? Center(
          child: ElevatedButton(
            onPressed: () async {
              final signedInUser = await AuthService().signInWithGoogle(context);
              if (signedInUser != null) {
                context.read<AppStateProvider>().setUser(signedInUser);
                if (!context.mounted) return;
                showSnack(context, '로그인 성공');
              }
            },
            child: const Text('Google 로그인'),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName ?? '이름 없음', style: const TextStyle(fontSize: 18)),
                    Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    context.read<AppStateProvider>().setUser(null);
                    if (!context.mounted) return;
                    context.read<AppStateProvider>().clearAddress();
                    showSnack(context, '로그아웃 되었습니다');
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('배송지 관리'),
              subtitle: Text(addressSummary),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddressListScreen(),
                  ),
                );

                if (result != null && context.mounted) {
                  final uid = context.read<AppStateProvider>().currentUser?.uid;
                  final docId = result['id'];

                  if (uid != null && docId != null) {
                    final addressRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('addresses');

                    final batch = FirebaseFirestore.instance.batch();

                    // 선택된 주소에 timeSetDefault를 현재 시간으로 설정
                    batch.update(addressRef.doc(docId), {
                      'timeSetDefault': FieldValue.serverTimestamp()
                    });
                    await batch.commit();
                  }

                  context.read<AppStateProvider>().setAddress(Map<String, dynamic>.from(result));
                  if (!context.mounted) return;
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('주문 내역'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.remove_red_eye_outlined),
              title: const Text('최근 본 상품'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('회원정보 수정'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
