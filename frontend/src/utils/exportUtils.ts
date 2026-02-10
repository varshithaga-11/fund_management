import * as XLSX from 'xlsx';
import { jsPDF } from 'jspdf';
import 'jspdf-autotable';
import { CompanyData } from '../pages/Companies/api';
import { RatioResultData } from '../pages/FinancialStatements/api';

// Declare module augmentation for autoTable
declare module 'jspdf' {
  interface jsPDF {
    autoTable: (options: any) => jsPDF;
    lastAutoTable: { finalY: number };
  }
}

// ==================== EXCEL EXPORT ====================

/**
 * Export company list to Excel
 */
export const exportCompaniesToExcel = (companies: CompanyData[], fileName: string = 'Companies') => {
  try {
    const worksheetData = companies.map((company, index) => ({
      'S.No': index + 1,
      'Company Name': company.name,
      'Registration No': company.registration_no,
      'Created Date': new Date(company.created_at).toLocaleDateString(),
    }));

    const worksheet = XLSX.utils.json_to_sheet(worksheetData);

    // Style the header row
    worksheet['!cols'] = [
      { wch: 8 },  // S.No
      { wch: 30 }, // Company Name
      { wch: 20 }, // Registration No
      { wch: 15 }, // Created Date
    ];

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Companies');

    XLSX.writeFile(workbook, `${fileName}_${new Date().toISOString().split('T')[0]}.xlsx`);

    return true;
  } catch (error) {
    console.error('Error exporting to Excel:', error);
    throw new Error('Failed to export to Excel');
  }
};

// ==================== PDF EXPORT ====================

/**
 * Export company list to PDF
 */
export const exportCompaniesToPDF = (companies: CompanyData[], fileName: string = 'Companies') => {
  try {
    const doc = new jsPDF({
      orientation: 'landscape',
      unit: 'mm',
      format: 'a4',
    });

    // Set colors and fonts
    const primaryColor: [number, number, number] = [70, 95, 255]; // Brand color
    const darkGray: [number, number, number] = [51, 51, 51];
    const lightGray: [number, number, number] = [240, 240, 240];

    // Title
    doc.setFontSize(18);
    doc.setTextColor(...primaryColor);
    doc.text('Company List', 14, 20);

    // Date generated
    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, 28);

    // Table headers
    const tableColumn = ['S.No', 'Company Name', 'Registration No', 'Created Date'];
    const tableRows: string[][] = [];

    companies.forEach((company, index) => {
      tableRows.push([
        String(index + 1),
        company.name,
        company.registration_no,
        new Date(company.created_at).toLocaleDateString(),
      ]);
    });

    // Create table using autoTable
    doc.autoTable({
      head: [tableColumn],
      body: tableRows,
      startY: 35,
      margin: { top: 35 },
      headStyles: {
        fillColor: primaryColor,
        textColor: [255, 255, 255],
        fontStyle: 'bold',
        halign: 'left',
        cellPadding: 4,
      },
      bodyStyles: {
        textColor: darkGray,
        cellPadding: 3.5,
      },
      alternateRowStyles: {
        fillColor: lightGray,
      },
      columnStyles: {
        0: { halign: 'center', cellWidth: 15 },
        1: { cellWidth: 70 },
        2: { cellWidth: 50 },
        3: { cellWidth: 40 },
      },
      didDrawPage: (data: any) => {
        // Footer
        const pageCount = doc.getNumberOfPages();
        const pageSize = doc.internal.pageSize;
        const pageHeight = pageSize.getHeight();
        const pageWidth = pageSize.getWidth();

        doc.setFontSize(9);
        doc.setTextColor(150, 150, 150);
        doc.text(
          `Page ${data.pageNumber} of ${pageCount}`,
          pageWidth / 2,
          pageHeight - 10,
          { align: 'center' }
        );
      },
    });

    // Add summary
    const finalY = doc.lastAutoTable?.finalY || 100;
    doc.setFontSize(10);
    doc.setTextColor(...darkGray);
    doc.text(`Total Companies: ${companies.length}`, 14, finalY + 10);

    doc.save(`${fileName}_${new Date().toISOString().split('T')[0]}.pdf`);

    return true;
  } catch (error) {
    console.error('Error exporting to PDF:', error);
    throw new Error('Failed to export to PDF');
  }
};

/**
 * Export company details to PDF (detailed view)
 */
export const exportCompanyDetailsToPDF = (company: CompanyData[], fileName: string = 'Company_Details') => {
  try {
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'mm',
      format: 'a4',
    });

    const primaryColor: [number, number, number] = [70, 95, 255];
    const darkGray: [number, number, number] = [51, 51, 51];
    const lightGray: [number, number, number] = [240, 240, 240];

    let yPosition = 20;

    // Title
    doc.setFontSize(18);
    doc.setTextColor(...primaryColor);
    doc.text('Company Details Report', 14, yPosition);
    yPosition += 10;

    // Date generated
    doc.setFontSize(9);
    doc.setTextColor(100, 100, 100);
    doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, yPosition);
    yPosition += 8;

    doc.setDrawColor(200, 200, 200);
    doc.line(14, yPosition, 196, yPosition);
    yPosition += 8;

    // Company details
    company.forEach((comp, index) => {
      if (index > 0) {
        yPosition += 5;
        doc.setDrawColor(200, 200, 200);
        doc.line(14, yPosition, 196, yPosition);
        yPosition += 5;
      }

      doc.setFontSize(12);
      doc.setTextColor(...primaryColor);
      doc.text(`Company #${index + 1}`, 14, yPosition);
      yPosition += 8;

      doc.setFontSize(10);
      doc.setTextColor(...darkGray);

      // Fill light gray background for details
      doc.setFillColor(lightGray[0] + 10, lightGray[1] + 10, lightGray[2] + 10);
      doc.rect(14, yPosition - 2, 182, 25, 'F');

      const details = [
        { label: 'Company Name:', value: comp.name },
        { label: 'Registration No:', value: comp.registration_no },
        { label: 'Created Date:', value: new Date(comp.created_at).toLocaleDateString() },
      ];

      details.forEach((detail) => {
        doc.setFont('helvetica', 'bold');
        doc.text(`${detail.label}`, 18, yPosition);
        doc.setFont('helvetica', 'normal');
        doc.text(detail.value, 60, yPosition);
        yPosition += 7;
      });

      yPosition += 3;

      // Check if we need a new page
      if (yPosition > 250) {
        doc.addPage();
        yPosition = 20;
      }
    });

    doc.save(`${fileName}_${new Date().toISOString().split('T')[0]}.pdf`);
    return true;
  } catch (error) {
    console.error('Error exporting company details to PDF:', error);
    throw new Error('Failed to export company details to PDF');
  }
};

// ==================== RATIO ANALYSIS EXPORT ====================

/**
 * Export ratio analysis to Excel
 */
export const exportRatioAnalysisToExcel = (
  ratios: RatioResultData,
  companyName: string,
  periodLabel: string,
  fileName: string = 'Ratio_Analysis'
) => {
  try {
    // Prepare data for all ratio categories
    const tradingRatios = [
      { Category: 'Trading Ratios', Ratio: 'Stock Turnover', Value: ratios.stock_turnover, Unit: 'times', 'Ideal Value': 15.0, Status: ratios.traffic_light_status?.stock_turnover || 'N/A' },
      { Category: 'Trading Ratios', Ratio: 'Gross Profit Ratio', Value: ratios.gross_profit_ratio || 0, Unit: '%', 'Ideal Value': 10.0, Status: ratios.traffic_light_status?.gross_profit_ratio || 'N/A' },
      { Category: 'Trading Ratios', Ratio: 'Net Profit Ratio', Value: ratios.net_profit_ratio || 0, Unit: '%', 'Ideal Value': '-', Status: ratios.traffic_light_status?.net_profit_ratio || 'N/A' },
    ];

    const fundStructureRatios = [
      { Category: 'Fund Structure', Ratio: 'Own Fund to Working Fund', Value: ratios.own_fund_to_wf || 0, Unit: '%', 'Ideal Value': 8.0, Status: ratios.traffic_light_status?.own_fund_to_wf || 'N/A' },
      { Category: 'Fund Structure', Ratio: 'Deposits to Working Fund', Value: ratios.deposits_to_wf || 0, Unit: '%', 'Ideal Value': '-', Status: ratios.traffic_light_status?.deposits_to_wf || 'N/A' },
      { Category: 'Fund Structure', Ratio: 'Borrowings to Working Fund', Value: ratios.borrowings_to_wf || 0, Unit: '%', 'Ideal Value': '-', Status: ratios.traffic_light_status?.borrowings_to_wf || 'N/A' },
      { Category: 'Fund Structure', Ratio: 'Loans to Working Fund', Value: ratios.loans_to_wf || 0, Unit: '%', 'Ideal Value': 70.0, Status: ratios.traffic_light_status?.loans_to_wf || 'N/A' },
      { Category: 'Fund Structure', Ratio: 'Investments to Working Fund', Value: ratios.investments_to_wf || 0, Unit: '%', 'Ideal Value': 25.0, Status: ratios.traffic_light_status?.investments_to_wf || 'N/A' },
    ];

    const yieldCostRatios = [
      { Category: 'Yield & Cost', Ratio: 'Cost of Deposits', Value: ratios.cost_of_deposits, Unit: '%', 'Ideal Value': '-', Status: ratios.traffic_light_status?.cost_of_deposits || 'N/A' },
      { Category: 'Yield & Cost', Ratio: 'Yield on Loans', Value: ratios.yield_on_loans, Unit: '%', 'Ideal Value': '-', Status: ratios.traffic_light_status?.yield_on_loans || 'N/A' },
      { Category: 'Yield & Cost', Ratio: 'Yield on Investments', Value: ratios.yield_on_investments || 0, Unit: '%', 'Ideal Value': '-', Status: ratios.traffic_light_status?.yield_on_investments || 'N/A' },
      { Category: 'Yield & Cost', Ratio: 'Credit Deposit Ratio', Value: ratios.credit_deposit_ratio, Unit: '%', 'Ideal Value': 70.0, Status: ratios.traffic_light_status?.credit_deposit_ratio || 'N/A' },
      { Category: 'Yield & Cost', Ratio: 'Avg Cost of Working Fund', Value: ratios.avg_cost_of_wf || 0, Unit: '%', 'Ideal Value': 3.5, Status: ratios.traffic_light_status?.avg_cost_of_wf || 'N/A' },
      { Category: 'Yield & Cost', Ratio: 'Avg Yield on Working Fund', Value: ratios.avg_yield_on_wf || 0, Unit: '%', 'Ideal Value': 3.5, Status: ratios.traffic_light_status?.avg_yield_on_wf || 'N/A' },
    ];

    const marginRatios = [
      { Category: 'Margin Analysis', Ratio: 'Gross Financial Margin', Value: ratios.gross_fin_margin, Unit: '%', 'Ideal Value': 3.5, Status: ratios.traffic_light_status?.gross_fin_margin || 'N/A' },
      { Category: 'Margin Analysis', Ratio: 'Operating Cost to Working Fund', Value: ratios.operating_cost_to_wf || 0, Unit: '%', 'Ideal Value': 2.5, Status: ratios.traffic_light_status?.operating_cost_to_wf || 'N/A' },
      { Category: 'Margin Analysis', Ratio: 'Net Financial Margin', Value: ratios.net_fin_margin, Unit: '%', 'Ideal Value': 1.5, Status: ratios.traffic_light_status?.net_fin_margin || 'N/A' },
      { Category: 'Margin Analysis', Ratio: 'Risk Cost to Working Fund', Value: ratios.risk_cost_to_wf || 0, Unit: '%', 'Ideal Value': 0.25, Status: ratios.traffic_light_status?.risk_cost_to_wf || 'N/A' },
      { Category: 'Margin Analysis', Ratio: 'Net Margin', Value: ratios.net_margin, Unit: '%', 'Ideal Value': 1.0, Status: ratios.traffic_light_status?.net_margin || 'N/A' },
    ];

    // Combine all ratios
    const allRatios = [...tradingRatios, ...fundStructureRatios, ...yieldCostRatios, ...marginRatios];

    // Create worksheet
    const worksheet = XLSX.utils.json_to_sheet(allRatios);

    // Add header information
    XLSX.utils.sheet_add_aoa(worksheet, [
      [`Company: ${companyName}`],
      [`Period: ${periodLabel}`],
      [`Generated: ${new Date().toLocaleString()}`],
      [], // Empty row
    ], { origin: 'A1' });

    // Adjust column widths
    worksheet['!cols'] = [
      { wch: 20 }, // Category
      { wch: 35 }, // Ratio
      { wch: 12 }, // Value
      { wch: 8 },  // Unit
      { wch: 12 }, // Ideal Value
      { wch: 10 }, // Status
    ];

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Ratio Analysis');

    XLSX.writeFile(workbook, `${fileName}_${companyName.replace(/\s+/g, '_')}_${new Date().toISOString().split('T')[0]}.xlsx`);

    return true;
  } catch (error) {
    console.error('Error exporting ratio analysis to Excel:', error);
    throw new Error('Failed to export ratio analysis to Excel');
  }
};

/**
 * Export ratio analysis to PDF (without using autoTable)
 */
export const exportRatioAnalysisToPDF = (
  ratios: RatioResultData,
  companyName: string,
  periodLabel: string,
  fileName: string = 'Ratio_Analysis'
) => {
  try {
    const doc = new jsPDF({
      orientation: 'landscape',
      unit: 'mm',
      format: 'a4',
    });

    const primaryColor: [number, number, number] = [70, 95, 255];
    const darkGray: [number, number, number] = [51, 51, 51];
    const lightGray: [number, number, number] = [240, 240, 240];

    let yPosition = 20;

    // Title
    doc.setFontSize(18);
    doc.setTextColor(...primaryColor);
    doc.text('Ratio Analysis Report', 14, yPosition);
    yPosition += 8;

    // Company and Period Info
    doc.setFontSize(11);
    doc.setTextColor(...darkGray);
    doc.text(`Company: ${companyName}`, 14, yPosition);
    yPosition += 6;
    doc.text(`Period: ${periodLabel}`, 14, yPosition);
    yPosition += 6;

    // Date generated
    doc.setFontSize(9);
    doc.setTextColor(100, 100, 100);
    doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, yPosition);
    yPosition += 10;

    // Helper to safely convert to number
    const toNumber = (value: any): number => {
      if (value === null || value === undefined) return 0;
      const num = Number(value);
      return isNaN(num) ? 0 : num;
    };

    // Helper to draw a ratio section
    const drawRatioSection = (title: string, ratioData: Array<{ name: string, value: number, unit: string, idealValue?: number, status?: string }>) => {
      // Section title
      doc.setFontSize(12);
      doc.setTextColor(...primaryColor);
      doc.text(title, 14, yPosition);
      yPosition += 7;

      // Table header background
      doc.setFillColor(...lightGray);
      doc.rect(14, yPosition - 5, 263, 7, 'F');

      // Table headers
      doc.setFontSize(9);
      doc.setTextColor(...darkGray);
      doc.setFont('helvetica', 'bold');
      doc.text('Ratio', 16, yPosition);
      doc.text('Value', 130, yPosition);
      doc.text('Unit', 160, yPosition);
      doc.text('Ideal', 185, yPosition);
      doc.text('Status', 220, yPosition);
      yPosition += 5;

      // Draw separator line
      doc.setDrawColor(200, 200, 200);
      doc.line(14, yPosition, 277, yPosition);
      yPosition += 5;

      // Table rows
      doc.setFont('helvetica', 'normal');
      ratioData.forEach((ratio, index) => {
        // Alternate row background
        if (index % 2 === 1) {
          doc.setFillColor(...lightGray);
          doc.rect(14, yPosition - 4, 263, 6, 'F');
        }

        doc.setTextColor(...darkGray);
        doc.text(ratio.name, 16, yPosition);
        doc.text(ratio.value.toFixed(2), 135, yPosition, { align: 'right' });
        doc.text(ratio.unit, 165, yPosition, { align: 'center' });
        doc.text(ratio.idealValue !== undefined ? ratio.idealValue.toString() : '-', 195, yPosition, { align: 'center' });

        // Status with color
        const status = ratio.status || 'N/A';
        const statusLower = status.toLowerCase();
        if (statusLower === 'green') {
          doc.setTextColor(34, 197, 94);
        } else if (statusLower === 'yellow') {
          doc.setTextColor(234, 179, 8);
        } else if (statusLower === 'red') {
          doc.setTextColor(239, 68, 68);
        } else {
          doc.setTextColor(...darkGray);
        }
        doc.setFont('helvetica', 'bold');
        doc.text(status, 235, yPosition, { align: 'center' });
        doc.setFont('helvetica', 'normal');

        yPosition += 6;
      });

      yPosition += 5;

      // Check if we need a new page
      if (yPosition > 160) {
        doc.addPage();
        yPosition = 20;
      }
    };

    // Trading Ratios
    drawRatioSection('Trading Ratios', [
      { name: 'Stock Turnover', value: toNumber(ratios.stock_turnover), unit: 'times', idealValue: 15.0, status: ratios.traffic_light_status?.stock_turnover },
      { name: 'Gross Profit Ratio', value: toNumber(ratios.gross_profit_ratio), unit: '%', idealValue: 10.0, status: ratios.traffic_light_status?.gross_profit_ratio },
      { name: 'Net Profit Ratio', value: toNumber(ratios.net_profit_ratio), unit: '%', status: ratios.traffic_light_status?.net_profit_ratio },
    ]);

    // Fund Structure Ratios
    drawRatioSection('Fund Structure', [
      { name: 'Own Fund to Working Fund', value: toNumber(ratios.own_fund_to_wf), unit: '%', idealValue: 8.0, status: ratios.traffic_light_status?.own_fund_to_wf },
      { name: 'Deposits to Working Fund', value: toNumber(ratios.deposits_to_wf), unit: '%', status: ratios.traffic_light_status?.deposits_to_wf },
      { name: 'Borrowings to Working Fund', value: toNumber(ratios.borrowings_to_wf), unit: '%', status: ratios.traffic_light_status?.borrowings_to_wf },
      { name: 'Loans to Working Fund', value: toNumber(ratios.loans_to_wf), unit: '%', idealValue: 70.0, status: ratios.traffic_light_status?.loans_to_wf },
      { name: 'Investments to Working Fund', value: toNumber(ratios.investments_to_wf), unit: '%', idealValue: 25.0, status: ratios.traffic_light_status?.investments_to_wf },
    ]);

    // Yield & Cost Ratios
    drawRatioSection('Yield & Cost Analysis', [
      { name: 'Cost of Deposits', value: toNumber(ratios.cost_of_deposits), unit: '%', status: ratios.traffic_light_status?.cost_of_deposits },
      { name: 'Yield on Loans', value: toNumber(ratios.yield_on_loans), unit: '%', status: ratios.traffic_light_status?.yield_on_loans },
      { name: 'Yield on Investments', value: toNumber(ratios.yield_on_investments), unit: '%', status: ratios.traffic_light_status?.yield_on_investments },
      { name: 'Credit Deposit Ratio', value: toNumber(ratios.credit_deposit_ratio), unit: '%', idealValue: 70.0, status: ratios.traffic_light_status?.credit_deposit_ratio },
      { name: 'Avg Cost of Working Fund', value: toNumber(ratios.avg_cost_of_wf), unit: '%', idealValue: 3.5, status: ratios.traffic_light_status?.avg_cost_of_wf },
      { name: 'Avg Yield on Working Fund', value: toNumber(ratios.avg_yield_on_wf), unit: '%', idealValue: 3.5, status: ratios.traffic_light_status?.avg_yield_on_wf },
    ]);

    // Margin Ratios
    drawRatioSection('Margin Analysis', [
      { name: 'Gross Financial Margin', value: toNumber(ratios.gross_fin_margin), unit: '%', idealValue: 3.5, status: ratios.traffic_light_status?.gross_fin_margin },
      { name: 'Operating Cost to Working Fund', value: toNumber(ratios.operating_cost_to_wf), unit: '%', idealValue: 2.5, status: ratios.traffic_light_status?.operating_cost_to_wf },
      { name: 'Net Financial Margin', value: toNumber(ratios.net_fin_margin), unit: '%', idealValue: 1.5, status: ratios.traffic_light_status?.net_fin_margin },
      { name: 'Risk Cost to Working Fund', value: toNumber(ratios.risk_cost_to_wf), unit: '%', idealValue: 0.25, status: ratios.traffic_light_status?.risk_cost_to_wf },
      { name: 'Net Margin', value: toNumber(ratios.net_margin), unit: '%', idealValue: 1.0, status: ratios.traffic_light_status?.net_margin },
    ]);

    // Add footer to all pages
    const pageCount = doc.getNumberOfPages();
    for (let i = 1; i <= pageCount; i++) {
      doc.setPage(i);
      const pageSize = doc.internal.pageSize;
      const pageHeight = pageSize.getHeight();
      const pageWidth = pageSize.getWidth();

      doc.setFontSize(9);
      doc.setTextColor(150, 150, 150);
      doc.text(
        `Page ${i} of ${pageCount}`,
        pageWidth / 2,
        pageHeight - 10,
        { align: 'center' }
      );
    }

    doc.save(`${fileName}_${companyName.replace(/\s+/g, '_')}_${new Date().toISOString().split('T')[0]}.pdf`);

    return true;
  } catch (error) {
    console.error('Error exporting ratio analysis to PDF:', error);
    console.error('Error details:', {
      message: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : undefined,
    });
    throw new Error('Failed to export ratio analysis to PDF: ' + (error instanceof Error ? error.message : 'Unknown error'));
  }
};
