import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const EducationPredictorApp());
}

class EducationPredictorApp extends StatelessWidget {
  const EducationPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Education Prediction API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color.fromARGB(255, 0, 2, 51),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 248, 248, 249),
      ),
      home: const PredictionPage(),
    );
  }
}

class _FieldSpec {
  final String key;
  final String label;
  final String hint;
  final double min;
  final double max;

  const _FieldSpec(this.key, this.label, this.hint, this.min, this.max);
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  static const String apiUrl =
      'https://african-tertiary-education-predictor.onrender.com/predict';

  final _formKey = GlobalKey<FormState>();

  final List<_FieldSpec> _fields = const [
    _FieldSpec(
      'OOSR_Pre0Primary_Age_Male',
      'OOSR Pre-Primary Age (Male) %',
      'e.g. 20',
      0,
      100,
    ),
    _FieldSpec(
      'OOSR_Pre0Primary_Age_Female',
      'OOSR Pre-Primary Age (Female) %',
      'e.g. 22',
      0,
      100,
    ),
    _FieldSpec(
      'OOSR_Primary_Age_Male',
      'OOSR Primary Age (Male) %',
      'e.g. 5',
      0,
      100,
    ),
    _FieldSpec(
      'OOSR_Primary_Age_Female',
      'OOSR Primary Age (Female) %',
      'e.g. 6',
      0,
      100,
    ),
    _FieldSpec(
      'OOSR_Lower_Secondary_Age_Male',
      'OOSR Lower Secondary Age (Male) %',
      'e.g. 8',
      0,
      100,
    ),
    _FieldSpec(
      'OOSR_Lower_Secondary_Age_Female',
      'OOSR Lower Secondary Age (Female) %',
      'e.g. 9',
      0,
      100,
    ),
    _FieldSpec(
      'OOSR_Upper_Secondary_Age_Male',
      'OOSR Upper Secondary Age (Male) %',
      'e.g. 15',
      0,
      100,
    ),
    _FieldSpec(
      'OOSR_Upper_Secondary_Age_Female',
      'OOSR Upper Secondary Age (Female) %',
      'e.g. 16',
      0,
      100,
    ),
    _FieldSpec(
      'Completion_Rate_Primary_Male',
      'Completion Rate Primary (Male) %',
      'e.g. 70',
      0,
      100,
    ),
    _FieldSpec(
      'Completion_Rate_Primary_Female',
      'Completion Rate Primary (Female) %',
      'e.g. 68',
      0,
      100,
    ),
    _FieldSpec(
      'Completion_Rate_Lower_Secondary_Male',
      'Completion Rate Lower Secondary (Male) %',
      'e.g. 55',
      0,
      100,
    ),
    _FieldSpec(
      'Completion_Rate_Lower_Secondary_Female',
      'Completion Rate Lower Secondary (Female) %',
      'e.g. 53',
      0,
      100,
    ),
    _FieldSpec(
      'Completion_Rate_Upper_Secondary_Male',
      'Completion Rate Upper Secondary (Male) %',
      'e.g. 35',
      0,
      100,
    ),
    _FieldSpec(
      'Completion_Rate_Upper_Secondary_Female',
      'Completion Rate Upper Secondary (Female) %',
      'e.g. 33',
      0,
      100,
    ),
    _FieldSpec(
      'Grade_2_3_Proficiency_Reading',
      'Grade 2-3 Proficiency Reading %',
      'e.g. 40',
      0,
      100,
    ),
    _FieldSpec(
      'Grade_2_3_Proficiency_Math',
      'Grade 2-3 Proficiency Math %',
      'e.g. 38',
      0,
      100,
    ),
    _FieldSpec(
      'Primary_End_Proficiency_Reading',
      'Primary-End Proficiency Reading %',
      'e.g. 30',
      0,
      100,
    ),
    _FieldSpec(
      'Primary_End_Proficiency_Math',
      'Primary-End Proficiency Math %',
      'e.g. 28',
      0,
      100,
    ),
    _FieldSpec(
      'Lower_Secondary_End_Proficiency_Reading',
      'Lower-Secondary-End Proficiency Reading %',
      'e.g. 25',
      0,
      100,
    ),
    _FieldSpec(
      'Lower_Secondary_End_Proficiency_Math',
      'Lower-Secondary-End Proficiency Math %',
      'e.g. 24',
      0,
      100,
    ),
    _FieldSpec(
      'Youth_15_24_Literacy_Rate_Male',
      'Youth 15-24 Literacy Rate (Male) %',
      'e.g. 72',
      0,
      100,
    ),
    _FieldSpec(
      'Youth_15_24_Literacy_Rate_Female',
      'Youth 15-24 Literacy Rate (Female) %',
      'e.g. 68',
      0,
      100,
    ),
    _FieldSpec('Birth_Rate', 'Birth Rate (per 1,000 people)', 'e.g. 28', 0, 60),
    _FieldSpec(
      'Gross_Primary_Education_Enrollment',
      'Gross Primary Education Enrollment %',
      'e.g. 100',
      0,
      200,
    ),
    _FieldSpec('Unemployment_Rate', 'Unemployment Rate %', 'e.g. 8', 0, 40),
  ];

  late final Map<String, TextEditingController> _controllers = {
    for (final f in _fields) f.key: TextEditingController(),
  };

  bool _loading = false;
  String? _resultText;
  String? _errorText;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _predict() async {
    setState(() {
      _errorText = null;
      _resultText = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _errorText = 'Please fix the highlighted fields.');
      return;
    }

    setState(() => _loading = true);

    final Map<String, dynamic> body = {
      for (final f in _fields) f.key: double.parse(_controllers[f.key]!.text),
    };

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // main.py returns: {"Predicted Gross Tertiary Education Enrollment": <value>}
        final value = data['Predicted Gross Tertiary Education Enrollment'];
        setState(() {
          _resultText =
              'Predicted Gross Tertiary Education Enrollment: $value%';
        });
      } else {
        final data = jsonDecode(response.body);
        setState(
          () => _errorText =
              'Server rejected the request: ${data['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      setState(() => _errorText = 'Could not reach the prediction service: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education Prediction API'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Enter a country\'s education indicators below to '
                'estimate its Gross Tertiary Education Enrollment rate.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color.fromARGB(136, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 20),
              ..._fields.map(_buildTextField),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _predict,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Predict', style: TextStyle(fontSize: 17)),
                ),
              ),
              const SizedBox(height: 20),
              _buildResultArea(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(_FieldSpec field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controllers[field.key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          final parsed = double.tryParse(value);
          if (parsed == null) {
            return 'Enter a valid number';
          }
          if (parsed < field.min || parsed > field.max) {
            return 'Must be between ${field.min} and ${field.max}';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildResultArea() {
    if (_loading) {
      return const SizedBox.shrink();
    }
    if (_errorText != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE57373)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFC62828)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorText!,
                style: const TextStyle(color: Color(0xFFC62828)),
              ),
            ),
          ],
        ),
      );
    }
    if (_resultText != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 219, 224, 228),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromARGB(174, 3, 0, 39)),
        ),
        child: Row(
          children: [
            const Icon(Icons.school, color: Color.fromARGB(255, 2, 3, 45)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _resultText!,
                style: const TextStyle(
                  color: Color.fromARGB(255, 7, 2, 62),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
