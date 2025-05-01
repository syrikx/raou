import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/state_provider.dart';

class ConfirmOrderScreen extends StatelessWidget {
  const ConfirmOrderScreen({super.key});

  Future<void> _submitOrder(BuildContext context) async {
    final user = context.watch<AppStateProvider>().currentUser;
    final cartItems = context.read<AppStateProvider>().cartItems;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장바구니가 비어 있습니다.')),
      );
      return;
    }

    final orderId =
        'ORD-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().second}${user.uid.substring(0, 4)}';
    final now = Timestamp.now();

    final items = cartItems.map((entry) {
      final parts = entry.split(' | ');
      return {
        'url': parts[0],
        'price': parts.length > 1 ? parts[1] : '가격 정보 없음',
      };
    }).toList();

    final orderData = {
      'orderId': orderId,
      'userId': user.uid,
      'createdAt': now,
      'items': items,
      'status': 'pending',
    };

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .set(orderData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ 주문이 접수되었습니다.\n주문번호: $orderId')),
    );

    Navigator.pop(context, true); // 이전 화면으로 돌아가면서 결과 전달
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = context.watch<AppStateProvider>().cartItems;

    return Scaffold(
      appBar: AppBar(title: const Text('주문 확인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🧾 주문 내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) => Text('• ${cartItems[index]}'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('주문 확정'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _submitOrder(context),
              ),
            )
          ],
        ),
      ),
    );
  }
}
