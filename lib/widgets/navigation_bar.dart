import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raou/utils/state_provider.dart';

class RaouNavigationBar extends StatelessWidget {
  final void Function() onHomePressed;
  final void Function() onCoupangPressed;
  final void Function() onOrderPressed;
  final void Function() onCartPressed;
  final void Function() onProfilePressed;
  final int cartItemCount;

  const RaouNavigationBar({
    super.key,
    required this.onHomePressed,
    required this.onCoupangPressed,
    required this.onOrderPressed,
    required this.onCartPressed,
    required this.onProfilePressed,
    required this.cartItemCount,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStateProvider>().currentUser;

    return Container(
      color: const Color(0xFF2C2C54),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _brandLabel(),
          const SizedBox(width: 16),
          _navItem(Icons.storefront_outlined, '쿠팡', onCoupangPressed),
          _navItem(Icons.shopping_bag_outlined, '주문', onOrderPressed),
          _cartIconWithBadge(onCartPressed, cartItemCount),
          GestureDetector(
            onTap: onProfilePressed,
            child: user != null && user.photoURL != null
                ? CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(user.photoURL!),
            )
                : _navItem(Icons.person_outline, '로그인', onProfilePressed),
          ),
        ],
      ),
    );
  }

  Widget _brandLabel() {
    return const Padding(
      padding: EdgeInsets.only(right: 4),
      child: Text(
        'Raou',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _cartIconWithBadge(VoidCallback onTap, int itemCount) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: onTap,
        ),
        if (itemCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                '$itemCount',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
