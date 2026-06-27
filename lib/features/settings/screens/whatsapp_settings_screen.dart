import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/navigation/swipe_back_detector.dart';

class WhatsappSettingsScreen extends StatefulWidget {
  const WhatsappSettingsScreen({super.key});

  @override
  State<WhatsappSettingsScreen> createState() => _WhatsappSettingsScreenState();
}

class _WhatsappSettingsScreenState extends State<WhatsappSettingsScreen> {
  final TextEditingController _templateController = TextEditingController();
  bool _isLoading = true;

  final String _defaultTemplate = '''*Rincian Hutang {nama}*
====================
{rincian_hutang}
====================
Total Hutang: {total_hutang}
Total Deposit: {total_deposit}
Sisa Hutang Bersih: *{sisa_hutang}*

Harap segera dibayarkan. Terima kasih.''';

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final template = prefs.getString('wa_template') ?? _defaultTemplate;
    setState(() {
      _templateController.text = template;
      _isLoading = false;
    });
  }

  Future<void> _saveTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wa_template', _templateController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template WhatsApp berhasil disimpan!')));
    }
  }

  Future<void> _resetTemplate() async {
    setState(() {
      _templateController.text = _defaultTemplate;
    });
    await _saveTemplate();
  }

  @override
  void dispose() {
    _templateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SwipeBackDetector(
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 70,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              alignment: Alignment.center,
              child: Text(
                'Back',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          title: const Text('Pengaturan WhatsApp'),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Gunakan variabel berikut (akan diganti otomatis):\n'
                  '{nama} - Nama staff\n'
                  '{rincian_hutang} - Daftar transaksi hutang\n'
                  '{total_hutang} - Nominal total hutang\n'
                  '{total_deposit} - Nominal deposit\n'
                  '{sisa_hutang} - Nominal hutang dikurangi deposit',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _templateController,
                  maxLines: 12,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _resetTemplate,
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Reset Default'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saveTemplate,
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
  }
}
