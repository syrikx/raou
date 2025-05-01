/// 가격 추출 관련 JavaScript 코드 분리

class ProductDetailGetter {
  static const String js = '''
    (() => {
      const quantityDiv = document.querySelector('#MWEB_PRODUCT_DETAIL_ATF_QUANTITY');
      if (quantityDiv) {
        const bold = quantityDiv.querySelector('b');
        if (bold && bold.innerText) {
          return bold.innerText;
        }
      }

      const priceInfoDiv = document.querySelector('#MWEB_PRODUCT_DETAIL_ATF_PRICE_INFO');
      if (priceInfoDiv) {
        const span = priceInfoDiv.querySelector('span[class^="PriceInfo_finalPrice"]');
        if (span && span.innerText) {
          return span.innerText;
        }
      }

      return '가격 없음';
    })()
  ''';
}
