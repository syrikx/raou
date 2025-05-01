import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/navigation_bar.dart';
import '../services/product_detail_getter.dart';
import 'confirm_order.dart';
import 'user_page.dart';
import '../utils/state_provider.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final url = request.url;
          if (url.startsWith('http') || url.startsWith('https')) {
            return NavigationDecision.navigate;
          } else {
            debugPrint('차단된 URL 스킴: $url');
            return NavigationDecision.prevent;
          }
        },
        onPageFinished: (url) async {
          final extractedPrice = await controller.runJavaScriptReturningResult(ProductDetailGetter.js);

          context.read<AppStateProvider>().setAddress({
            'url': url,
            'price': extractedPrice.toString().replaceAll('"', '')
          });

          await controller.runJavaScript("""
            (() => {
              const selectors = [
                'div[aria-label="앱으로 보기"]',
                '.floating-app-banner',
                '.app-banner-area',
                '.app-link',
                '.coupangapp-open-link',
              ];
              selectors.forEach(sel => {
                const el = document.querySelector(sel);
                if (el) el.style.display = 'none';
              });
            })();
          """);
        },
      ))
      ..loadRequest(Uri.parse('https://www.coupang.com/'));
  }

  void onOrderPressed() async {
    final result = await controller.runJavaScriptReturningResult("""
      (() => {
        const quantityDiv = document.querySelector('#MWEB_PRODUCT_DETAIL_ATF_QUANTITY');
        if (quantityDiv) {
          const bold = quantityDiv.querySelector('b');
          if (bold && bold.innerText) return bold.innerText;
        }
        const priceInfoDiv = document.querySelector('#MWEB_PRODUCT_DETAIL_ATF_PRICE_INFO');
        if (priceInfoDiv) {
          const span = priceInfoDiv.querySelector('span[class^="PriceInfo_finalPrice"]');
          if (span && span.innerText) return span.innerText;
        }
        return '가격 없음';
      })()
    """);

    final price = result.toString().replaceAll('"', '');
    final currentUrl = await controller.currentUrl() ?? '';
    context.read<AppStateProvider>().addToCart('$currentUrl | $price');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('장바구니에 추가됨\n가격: $price')),
    );
  }

  void onCartPressed() async {
    final cartItems = context.read<AppStateProvider>().cartItems;

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장바구니가 비어 있습니다.')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfirmOrderScreen(),
      ),
    );

    if (result == true) {
      context.read<AppStateProvider>().clearCart();

    }
  }

  void onProfilePressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserPage()),
    );

    if (result == true) {
      // Provider로 자동 반영되므로 setState() 필요 없음
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (await controller.canGoBack()) {
            controller.goBack();
            return false;
          }
          return true;
        },
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: WebViewWidget(controller: controller)),
              Align(
                alignment: Alignment.bottomCenter,
                child: RaouNavigationBar(
                  onHomePressed: () {
                    controller.loadRequest(Uri.parse('https://raou.kr/'));
                  },
                  onCoupangPressed: () {
                    controller.loadRequest(Uri.parse('https://www.coupang.com/'));
                  },
                  onOrderPressed: onOrderPressed,
                  onCartPressed: onCartPressed,
                  onProfilePressed: onProfilePressed,
                  cartItemCount: context.watch<AppStateProvider>().cartItemCount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
