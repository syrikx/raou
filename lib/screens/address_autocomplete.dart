import 'package:flutter/material.dart';
import 'package:google_maps_webservice2/places.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const kGoogleApiKey = 'AIzaSyAKJphBUiApD4fG9xCfCfjocjVSRz1leFI';
final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
final _uuid = Uuid();

class AddressAutocompleteScreen extends StatefulWidget {
  const AddressAutocompleteScreen({super.key});

  @override
  State<AddressAutocompleteScreen> createState() => _AddressAutocompleteScreenState();
}

class _AddressAutocompleteScreenState extends State<AddressAutocompleteScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  List<Prediction> _suggestions = [];
  String? _selectedAddress;
  String? _sessionToken;

  void _onChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    _sessionToken ??= _uuid.v4();

    final response = await _places.autocomplete(
      value,
      sessionToken: _sessionToken,
      components: [Component(Component.country, 'us')],
      language: 'en',
    );

    if (response.isOkay) {
      setState(() => _suggestions = response.predictions);
    } else {
      debugPrint('❗️Google Places Error: ${response.errorMessage}');
    }
  }

  void _onSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _selectedAddress != null) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc();

      await docRef.set({
        'address': _selectedAddress,
        'detail': _detailController.text.trim(),
        'recipient': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주소가 저장되었습니다.')),
      );
      Navigator.pop(context, {
        'address': _selectedAddress,
        'detail': _detailController.text.trim(),
        'recipient': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
    }
  }

  void _onSelectPrediction(Prediction prediction) async {
    final detail = await _places.getDetailsByPlaceId(prediction.placeId!);
    final formatted = detail.result.formattedAddress;

    setState(() {
      _selectedAddress = formatted;
      _controller.text = formatted ?? '';
      _suggestions = [];
      _sessionToken = null; // 세션 초기화
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주소 자동완성')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '주소 검색',
                  border: OutlineInputBorder(),
                ),
                onChanged: _onChanged,
              ),
              const SizedBox(height: 12),
              if (_suggestions.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    return ListTile(
                      title: Text(item.description ?? ''),
                      onTap: () => _onSelectPrediction(item),
                    );
                  },
                ),
              if (_selectedAddress != null && _suggestions.isEmpty) ...[
                const SizedBox(height: 20),
                Text('선택된 주소:\n$_selectedAddress', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _detailController,
                  decoration: const InputDecoration(
                    labelText: '상세 주소 (예: Apt 101, PO Box 등)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '수신자 이름',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '전화번호',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onSave,
                    child: const Text('주소 저장'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
