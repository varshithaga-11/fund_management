import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../services/api_service.dart';

class ExportService {
  // Export to CSV
  static Future<void> exportToCSV({
    required String dataType,
    required String fileName,
    int? periodId,
  }) async {
    try {
      final csvData = await ApiService.exportToCSV(
        dataType: dataType,
        periodId: periodId,
      );

      _downloadFile(
        csvData,
        '$fileName.csv',
        'text/csv;charset=utf-8',
      );
    } catch (e) {
      throw 'Error exporting to CSV: $e';
    }
  }

  // Export to Excel
  static Future<void> exportToExcel({
    required String dataType,
    required String fileName,
    int? periodId,
  }) async {
    try {
      final excelData = await ApiService.exportToExcel(
        dataType: dataType,
        periodId: periodId,
      );

      _downloadFile(
        String.fromCharCodes(excelData),
        '$fileName.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      throw 'Error exporting to Excel: $e';
    }
  }

  // Export to PDF
  static Future<void> exportToPDF({
    required String dataType,
    required String fileName,
    int? periodId,
  }) async {
    try {
      final pdfData = await ApiService.exportToPDF(
        dataType: dataType,
        periodId: periodId,
      );

      _downloadFile(
        String.fromCharCodes(pdfData),
        '$fileName.pdf',
        'application/pdf',
      );
    } catch (e) {
      throw 'Error exporting to PDF: $e';
    }
  }

  // Helper function to download files in browser
  static void _downloadFile(
    String content,
    String fileName,
    String mimeType,
  ) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Export dashboard data
  static Future<void> exportDashboardData({
    required String format,
    int? periodId,
  }) async {
    final timestamp = DateTime.now().toString().split('.')[0].replaceAll(':', '-');

    switch (format.toLowerCase()) {
      case 'csv':
        await exportToCSV(
          dataType: 'dashboard',
          fileName: 'dashboard_$timestamp',
          periodId: periodId,
        );
        break;
      case 'xlsx':
      case 'excel':
        await exportToExcel(
          dataType: 'dashboard',
          fileName: 'dashboard_$timestamp',
          periodId: periodId,
        );
        break;
      case 'pdf':
        await exportToPDF(
          dataType: 'dashboard',
          fileName: 'dashboard_$timestamp',
          periodId: periodId,
        );
        break;
      default:
        throw 'Unsupported format: $format';
    }
  }

  // Generate in-memory preview
  static String generateCSVPreview(
    List<List<String>> data, {
    List<String>? headers,
  }) {
    final lines = <String>[];

    if (headers != null) {
      lines.add(headers.join(','));
    }

    for (final row in data) {
      lines.add(row.map((cell) => '"$cell"').join(','));
    }

    return lines.join('\n');
  }

  // Export chart as image (requires additional package)
  static Future<void> exportChartAsImage({
    required String fileName,
  }) async {
    // This would require a screenshot or canvas-based approach
    // Using screenshot package or similar
    throw 'Chart export not yet implemented - requires screenshot package';
  }
}
