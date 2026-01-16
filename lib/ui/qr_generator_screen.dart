import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
// Import tambahan untuk PDF & Printing
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const Color primaryColor = Color(0xFF3A2EC3);

const List<Color> qrColors = [
  Colors.white,
  Colors.grey,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.cyan,
  Colors.purple,
];

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  String? _qrData;
  Color _qrColor = Colors.white;

  // --- TUGAS 1: Fitur Send/Share ---
  Future<void> _shareQrCode() async {
    if (_qrData == null || _qrData!.isEmpty) return;

    // Loading indicator (Bonus)
    _showLoading();

    try {
      final imageBytes = await _screenshotController.capture(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );

      if (mounted) Navigator.pop(context); // Tutup loading

      if (imageBytes != null) {
        await Share.shareXFiles(
          [
            XFile.fromData(
              imageBytes,
              name: 'qr_code.png',
              mimeType: 'image/png',
            ),
          ],
          text: 'QR Code untuk: $_qrData\nDibuat dengan QR S&G oleh Rifai Gusnian',
          subject: 'QR Code dari QR S&G App',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar("Gagal membagikan QR Code");
    }
  }

  // --- TUGAS 2: Fitur Print/PDF ---
  Future<void> _generateAndPrintPdf() async {
    if (_qrData == null || _qrData!.isEmpty) return;

    _showLoading();

    try {
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) throw Exception("Capture failed");

      final pdf = pw.Document();
      final qrImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('QR Code Generated',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Image(qrImage, width: 250, height: 250),
                  pw.SizedBox(height: 20),
                  pw.Text('Link/Teks: $_qrData',
                      style: pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 40),
                  pw.Divider(),
                  pw.Text('Dibuat oleh: Rifai Gusnian - QR S&G App',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                ],
              ),
            );
          },
        ),
      );

      if (mounted) Navigator.pop(context); // Tutup loading

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'QR_Code_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar("Gagal membuat PDF");
    }
  }

  // Helper Widgets untuk Bonus Challenge
  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tombol aktif hanya jika data tidak kosong (Bonus)
    bool isDataValid = _qrData != null && _qrData!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create QR', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(height: 220, color: primaryColor),
              Expanded(child: Container(color: Colors.grey.shade50)),
            ],
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Screenshot(
                          controller: _screenshotController,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _qrColor,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: Colors.black12, width: 2),
                            ),
                            child: _qrData == null || _qrData!.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Text(
                                      'Masukkan teks/link untuk generate QR',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : PrettyQrView.data(
                                    data: _qrData!,
                                    decoration: const PrettyQrDecoration(
                                      shape: PrettyQrSmoothSymbol(),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Link atau Teks',
                            hintText: 'https://example.com',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          maxLines: 2,
                          onChanged: (value) {
                            setState(() => _qrData =
                                value.trim().isEmpty ? null : value.trim());
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text('Pilih Warna Background QR'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: qrColors.map((color) {
                            return GestureDetector(
                              onTap: () => setState(() => _qrColor = color),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _qrColor == color
                                        ? Colors.black
                                        : Colors.black12,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // BARIS TOMBOL AKSI
                        Row(
                          children: [
                            // Tombol Reset
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _qrData = null;
                                    _qrColor = Colors.white;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Reset'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Tombol Send (Tugas 1)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isDataValid ? _shareQrCode : null,
                                icon: const Icon(Icons.send),
                                label: const Text('Send'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Tombol Print (Tugas 2)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isDataValid ? _generateAndPrintPdf : null,
                                icon: const Icon(Icons.print),
                                label: const Text('Print'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}