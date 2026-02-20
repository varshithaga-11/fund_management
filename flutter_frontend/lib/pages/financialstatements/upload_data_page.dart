import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      
      if (kIsWeb) {
        // On web, path is unavailable and accessing it throws. Use bytes instead.
        if (_selectedFile!.bytes != null) {
          multipartFile = http.MultipartFile.fromBytes(
            'file',
            _selectedFile!.bytes!,
            filename: _selectedFile!.name,
          );
        } else {
             throw Exception('File bytes not available. Please try picking the file again.');
        }
      } else {
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
      backgroundColor: Colors.grey.shade50, // Light background for the page
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Upload Financial Data',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload an Excel file (.xlsx, .xls), Word document (.docx), or PDF for financial data or statements',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Template Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _downloadingTemplate != null ? null : () => _downloadTemplate('excel'),
                  icon: _downloadingTemplate == 'excel' 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download, size: 18),
                  label: const Text('Download Excel Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _downloadingTemplate != null ? null : () => _downloadTemplate('word'),
                  icon: _downloadingTemplate == 'word'
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download, size: 18),
                  label: const Text('Download Word Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6), // Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Main Content Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Input Label
                  const Text(
                    'File (Excel, Word, or PDF) *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  // Custom File File Input
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _uploading ? null : _pickFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF), // Light blue bg
                          foregroundColor: const Color(0xFF3B82F6), // Blue text
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Choose file', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFile != null ? _selectedFile!.name : 'No file chosen',
                          style: TextStyle(
                            color: _selectedFile != null ? Colors.black87 : Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supported formats: .xlsx, .xls (Excel), .docx (Word), .pdf',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),

                  const SizedBox(height: 24),

                  // Yellow Info Box
                  _buildInfoBox(
                    title: 'Filename = Period (India FY Apr–Mar)',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name the file to auto-detect period. Use _ format:', style: TextStyle(fontSize: 13, color: Colors.orange.shade900)),
                        const SizedBox(height: 8),
                        _buildRichTextParams('MONTHLY:', ' Apr_2024, May_2024, Jun_2024, Jul_2024, Aug_2024, Sep_2024, Oct_2024, Nov_2024, Dec_2024, Jan_2025, Feb_2025, Mar_2025'),
                        _buildRichTextParams('QUARTERLY:', ' Q1_FY_2024_25, Q2_FY_2024_25, Q3_FY_2024_25, Q4_FY_2024_25'),
                        _buildRichTextParams('HALF YEARLY:', ' H1_FY_2024_25, H2_FY_2024_25'),
                        _buildRichTextParams('YEARLY:', ' FY_2024_25'),
                      ],
                    ),
                    bgColor: const Color(0xFFFFFBEB), // Light yellow
                    borderColor: const Color(0xFFFDE68A),
                    titleColor: Colors.black87,
                  ),

                  const SizedBox(height: 16),

                  // Blue Info Box
                  _buildInfoBox(
                    title: 'Excel File Format (recommended – 5 sheets):',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBulletPoint('Financial_Statement – Entity Name, Fiscal Year End, Currency, Staff Count'),
                        _buildBulletPoint('Balance_Sheet_Liabilities – Liability Type, Amount (e.g. Share Capital, Deposits, Borrowings, Reserves, Provisions, Other Liabilities, Undistributed Profit)'),
                        _buildBulletPoint('Balance_Sheet_Assets – Asset Type, Amount (e.g. Cash in Hand, Cash at Bank, Investments, Loans & Advances, Fixed Assets, Other Assets, Stock in Trade)'),
                        _buildBulletPoint('Profit_Loss – Category, Item, Amount (Income / Expense / Net Profit rows)'),
                        _buildBulletPoint('Trading_Account – Item, Amount (Opening Stock, Purchases, Trade Charges, Sales, Closing Stock)'),
                      ],
                    ),
                    bgColor: const Color(0xFFEFF6FF), // Light blue
                    borderColor: const Color(0xFFBFDBFE),
                    titleColor: Colors.black87,
                  ),

                  const SizedBox(height: 24),

                  // Upload Button (Right Aligned)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: (_selectedFile == null || _uploading) ? null : _handleUpload,
                      style: ButtonStyle(
                         backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.disabled)) return const Color(0xFFE0E7FF); // Lighter blue for disabled
                          return const Color(0xFF6366F1); // Indigo/Periwinkle kind of blue
                        }),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      ),
                      // Actually let's just use standard blue for functionality, design tweak can follow.
                      // Screenshots show it is bottom right.
                      child: _uploading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Upload & Process', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Expected Sheet Structures (Use LayoutBuilder for responsiveness)
            const Text(
              'Expected Sheet Structures (5-sheet format):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // If wide enough, 2 columns. Else 1 column.
                // React screenshot shows 2 columns.
                if (constraints.maxWidth > 800) {
                   return Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             _buildSimpleStructureItem('Financial_Statement:', 'Entity Name, Fiscal Year End, Currency, Staff Count'),
                             const SizedBox(height: 16),
                             _buildSimpleStructureItem('Balance_Sheet_Assets:', 'Asset Type, Amount (one row per asset)'),
                             const SizedBox(height: 16),
                             _buildSimpleStructureItem('Trading_Account:', 'Item, Amount (Opening Stock, Purchases, Trade Charges, Sales, Closing Stock)'),
                           ],
                         ),
                       ),
                       const SizedBox(width: 40),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              _buildSimpleStructureItem('Balance_Sheet_Liabilities:', 'Liability Type, Amount (one row per liability)'),
                              const SizedBox(height: 16),
                              _buildSimpleStructureItem('Profit_Loss:', 'Category, Item, Amount (Income / Expense / Net Profit)'),
                           ],
                         ),
                       ),
                     ],
                   );
                } else {
                   return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       _buildSimpleStructureItem('Financial_Statement:', 'Entity Name, Fiscal Year End, Currency, Staff Count'),
                       const SizedBox(height: 16),
                       _buildSimpleStructureItem('Balance_Sheet_Liabilities:', 'Liability Type, Amount (one row per liability)'),
                       const SizedBox(height: 16),
                       _buildSimpleStructureItem('Balance_Sheet_Assets:', 'Asset Type, Amount (one row per asset)'),
                       const SizedBox(height: 16),
                       _buildSimpleStructureItem('Profit_Loss:', 'Category, Item, Amount (Income / Expense / Net Profit)'),
                       const SizedBox(height: 16),
                       _buildSimpleStructureItem('Trading_Account:', 'Item, Amount (Opening Stock, Purchases, Trade Charges, Sales, Closing Stock)'),
                     ],
                   );
                }
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required String title,
    required Widget content,
    required Color bgColor,
    required Color borderColor,
    required Color titleColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildRichTextParams(String label, String value) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 4.0),
       child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            children: [
              TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: value),
            ],
          ),
        ),
     );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4))),
        ],
      ),
    );
  }
  
  Widget _buildSimpleStructureItem(String title, String desc) {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
         const SizedBox(height: 2),
         Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
       ],
    );
  }

}
