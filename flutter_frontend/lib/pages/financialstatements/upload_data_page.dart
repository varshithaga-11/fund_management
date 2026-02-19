import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart'; // import open_filex
import 'financial_statements_api.dart';
import 'financial_period_page.dart'; // To navigate to period page

class UploadDataPage extends StatefulWidget {
  const UploadDataPage({super.key});

  @override
  State<UploadDataPage> createState() => _UploadDataPageState();
}

class _UploadDataPageState extends State<UploadDataPage> {
  PlatformFile? _selectedFile;
  bool _uploading = false;
  String? _downloadingTemplate; // 'excel' or 'word'

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'docx', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file (Excel, Word, or PDF)')),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      http.MultipartFile multipartFile;
      
      if (_selectedFile!.path != null) {
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        );
      } else if (_selectedFile!.bytes != null) {
        multipartFile = http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        );
      } else {
        throw Exception('File path or bytes not available');
      }

      final result = await uploadExcelData(multipartFile);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data uploaded successfully!'), backgroundColor: Colors.green),
      );

      // Navigate to financial period page if period_id exists
      if (result['period_id'] != null && mounted) {
        // Wait a bit then navigate
        await Future.delayed(const Duration(milliseconds: 1500));
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => FinancialPeriodPage(periodId: result['period_id']))
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _downloadTemplate(String type) async {
    setState(() => _downloadingTemplate = type);
    try {
      List<int> bytes;
      String filename;
      
      if (type == 'excel') {
        bytes = await downloadExcelTemplate();
        filename = 'Financial_Data_Template.xlsx';
      } else {
        bytes = await downloadWordTemplate();
        filename = 'Financial_Data_Template.docx';
      }

      // Save file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type template downloaded to ${file.path}'), backgroundColor: Colors.green),
      );
      
      // Open file
      await OpenFilex.open(file.path);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _downloadingTemplate = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Financial Data')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text(
              'Upload Financial Data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload an Excel file (.xlsx, .xls), Word document (.docx), or PDF for financial data or statements',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Download Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadingTemplate != null ? null : () => _downloadTemplate('excel'),
                    icon: _downloadingTemplate == 'excel' 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download),
                    label: const Text('Excel Template'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadingTemplate != null ? null : () => _downloadTemplate('word'),
                    icon: _downloadingTemplate == 'word'
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download),
                    label: const Text('Word Template'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Upload Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('File (Excel, Word, or PDF) *', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  InkWell(
                    onTap: _uploading ? null : _pickFile,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid), // Dashed borders need custom painter, solid is fine
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.upload_file, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFile != null ? _selectedFile!.name : 'Click to select file',
                            style: TextStyle(
                              color: _selectedFile != null ? Colors.blue : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  const Text('Supported formats: .xlsx, .xls, .docx, .pdf', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  
                  const SizedBox(height: 24),
                  
                  // Info Boxes
                  _buildInfoBox(
                    'Filename = Period (India FY Apr–Mar)',
                    'Name the file to auto-detect period. Use _ format: e.g. FY_2024_25, Q1_FY_2024_25, Apr_2024',
                    Colors.amber.shade50,
                    Colors.amber.shade900,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoBox(
                    'Excel File Format (recommended – 5 sheets):',
                    'Financial_Statement, Balance_Sheet_Liabilities, Balance_Sheet_Assets, Profit_Loss, Trading_Account',
                    Colors.blue.shade50,
                    Colors.blue.shade900,
                  ),

                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: (_selectedFile == null || _uploading) ? null : _handleUpload,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _uploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Upload & Process'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String content, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(content, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }
}
