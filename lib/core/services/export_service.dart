import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/trip.dart';
import '../../models/expense.dart';
import '../../models/advance.dart';
import '../../models/user_profile.dart';
import '../utils/file_download_helper.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Returns the path to the saved file, or null for web
  Future<String?> exportToExcel(
    Trip trip,
    List<Expense> expenses, {
    UserProfile? userProfile,
    List<Advance>? advances,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    // Header styling
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.blue700,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    final boldStyle = CellStyle(bold: true);

    // Style for submitter sheet with vertical alignment
    final submitterBoldStyle = CellStyle(
      bold: true,
      verticalAlign: VerticalAlign.Center,
    );
    final submitterDataStyle = CellStyle(
      verticalAlign: VerticalAlign.Center,
    );
    // Style for section headers (black background, white text)
    final submitterSectionHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      verticalAlign: VerticalAlign.Center,
    );

    // Create Submitter Sheet
    final submitterSheet = excel['Submitter'];
    int submitterRow = 0;
    bool isFirstSection = true;

    // Add blank row above row 0 (15px height)
    submitterSheet.setRowHeight(submitterRow, 15);
    submitterRow++;

    // Add blank column before column A (2 character units width) - Column 0
    submitterSheet.setColumnWidth(0, 2);

    if (userProfile != null) {
      // Submitter Details Header
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .value = TextCellValue('Submitter Details');
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .cellStyle = submitterSectionHeaderStyle;
      // Apply same style to next cell
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
          .cellStyle = submitterSectionHeaderStyle;
      submitterSheet.setRowHeight(submitterRow, 22);
      submitterRow++;

      // Employee Name
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .value = TextCellValue('Employee Name');
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .cellStyle = submitterDataStyle;
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
          .value = TextCellValue(userProfile.fullName);
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
          .cellStyle = submitterDataStyle;
      submitterSheet.setRowHeight(submitterRow, 22);
      submitterRow++;

      // Employee ID
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .value = TextCellValue('Employee ID');
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .cellStyle = submitterDataStyle;
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
          .value = TextCellValue(userProfile.employeeId);
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
          .cellStyle = submitterDataStyle;
      submitterSheet.setRowHeight(submitterRow, 22);
      submitterRow++;

      // Employee Email
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .value = TextCellValue('Employee Email');
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .cellStyle = submitterDataStyle;
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
          .value = TextCellValue(userProfile.email);
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
          .cellStyle = submitterDataStyle;
      submitterSheet.setRowHeight(submitterRow, 22);
      submitterRow++;

      // Company
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .value = TextCellValue('Company');
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .cellStyle = submitterDataStyle;
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
          .value = TextCellValue(userProfile.company);
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
          .cellStyle = submitterDataStyle;
      submitterSheet.setRowHeight(submitterRow, 22);
      submitterRow++;

      // Bank Details Section
      if (userProfile.accountName != null ||
          userProfile.accountNumber != null ||
          userProfile.ifscCode != null ||
          userProfile.bankName != null ||
          userProfile.branch != null) {
        // Add one blank row before new section
        submitterRow += 1;
        isFirstSection = false;

        // Section header in bold
        submitterSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
            .value = TextCellValue('Bank Details');
        submitterSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
            .cellStyle = submitterSectionHeaderStyle;
        // Apply same style to next cell
        submitterSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
            .cellStyle = submitterSectionHeaderStyle;
        submitterSheet.setRowHeight(submitterRow, 22);
        submitterRow++;

        if (userProfile.accountName != null) {
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .value = TextCellValue('Account Name');
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .value = TextCellValue(userProfile.accountName!);
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet.setRowHeight(submitterRow, 22);
          submitterRow++;
        }
        if (userProfile.accountNumber != null) {
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .value = TextCellValue('Account Number');
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .value = TextCellValue(userProfile.accountNumber!);
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet.setRowHeight(submitterRow, 22);
          submitterRow++;
        }
        if (userProfile.ifscCode != null) {
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .value = TextCellValue('IFSC Code');
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .value = TextCellValue(userProfile.ifscCode!);
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet.setRowHeight(submitterRow, 22);
          submitterRow++;
        }
        if (userProfile.bankName != null) {
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .value = TextCellValue('Bank Name');
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .value = TextCellValue(userProfile.bankName!);
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet.setRowHeight(submitterRow, 22);
          submitterRow++;
        }
        if (userProfile.branch != null) {
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .value = TextCellValue('Branch');
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .value = TextCellValue(userProfile.branch!);
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet.setRowHeight(submitterRow, 22);
          submitterRow++;
        }
      }

      // UPI Details Section
      if (userProfile.upiId != null || userProfile.upiName != null) {
        // Add one blank row before new section (2nd section onwards)
        if (!isFirstSection) {
          submitterRow += 1;
        }
        isFirstSection = false;

        // Section header in bold
        submitterSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
            .value = TextCellValue('UPI Details');
        submitterSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
            .cellStyle = submitterSectionHeaderStyle;
        // Apply same style to next cell
        submitterSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
            .cellStyle = submitterSectionHeaderStyle;
        submitterSheet.setRowHeight(submitterRow, 22);
        submitterRow++;

        if (userProfile.upiId != null) {
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .value = TextCellValue('UPI ID');
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .value = TextCellValue(userProfile.upiId!);
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet.setRowHeight(submitterRow, 22);
          submitterRow++;
        }
        if (userProfile.upiName != null) {
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .value = TextCellValue('UPI Name');
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .value = TextCellValue(userProfile.upiName!);
          submitterSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: submitterRow))
              .cellStyle = submitterDataStyle;
          submitterSheet.setRowHeight(submitterRow, 22);
          submitterRow++;
        }
      }
    } else {
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .value = TextCellValue('Profile information not available');
      submitterSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: submitterRow))
          .cellStyle = submitterDataStyle;
      submitterSheet.setRowHeight(submitterRow, 22);
      submitterRow++;
    }

    // Calculate and set column widths to fit content for Submitter sheet
    // Column 0: Blank column (already set to 2)
    
    // Column 1: Labels column
    double maxLabelWidth = 'Submitter Details'.length.toDouble();
    if (userProfile != null) {
      final labels = [
        'Employee Name',
        'Employee ID',
        'Employee Email',
        'Company',
        'Bank Details',
        'Account Name',
        'Account Number',
        'IFSC Code',
        'Bank Name',
        'Branch',
        'UPI Details',
        'UPI ID',
        'UPI Name',
      ];
      for (final label in labels) {
        if (label.length.toDouble() > maxLabelWidth) {
          maxLabelWidth = label.length.toDouble();
        }
      }
    }
    submitterSheet.setColumnWidth(1, maxLabelWidth + 2); // Add padding

    // Column 2: Values column
    double maxValueWidth = 0.0;
    if (userProfile != null) {
      final values = [
        userProfile.fullName,
        userProfile.employeeId,
        userProfile.email,
        userProfile.company,
        userProfile.accountName ?? '',
        userProfile.accountNumber ?? '',
        userProfile.ifscCode ?? '',
        userProfile.bankName ?? '',
        userProfile.branch ?? '',
        userProfile.upiId ?? '',
        userProfile.upiName ?? '',
      ];
      for (final value in values) {
        if (value.isNotEmpty && value.length.toDouble() > maxValueWidth) {
          maxValueWidth = value.length.toDouble();
        }
      }
    }
    submitterSheet.setColumnWidth(2, maxValueWidth + 2); // Add padding

    // Create Summary Sheet
    final summarySheet = excel['Summary'];
    int summaryRow = 0;

    // Add blank row above row 0 (15px height)
    summarySheet.setRowHeight(summaryRow, 15);
    summaryRow++;

    // Add blank column before column A (2 character units width) - Column 0
    summarySheet.setColumnWidth(0, 2);

    // Trip Details Section
    final tripDetailsStyle = CellStyle(bold: true, verticalAlign: VerticalAlign.Center);
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = TextCellValue('Trip Details');
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = tripDetailsStyle;
    summarySheet.setRowHeight(summaryRow, 22);
    summaryRow++;

    final tripDetailsDataStyle = CellStyle(verticalAlign: VerticalAlign.Center);
    summarySheet
        .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = TextCellValue('Trip Name: ${trip.name}');
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = tripDetailsDataStyle;
    summarySheet.setRowHeight(summaryRow, 22);
    summaryRow++;

    final dateFormat = DateFormat('dd MMM yyyy');
    final dateRange = trip.endDate != null
        ? '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate!)}'
        : '${dateFormat.format(trip.startDate)} - Ongoing';
    summarySheet
        .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = TextCellValue('Date Range: $dateRange');
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = tripDetailsDataStyle;
    summarySheet.setRowHeight(summaryRow, 22);
    summaryRow++;

    summarySheet
        .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = TextCellValue('Locations Covered: ${trip.cities.join(', ')}');
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = tripDetailsDataStyle;
    summarySheet.setRowHeight(summaryRow, 22);
    summaryRow++;

    // Calculate total days
    final totalDays = trip.endDate != null
        ? trip.endDate!.difference(trip.startDate).inDays + 1
        : DateTime.now().difference(trip.startDate).inDays + 1;
    summarySheet
        .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = TextCellValue('Total Days: $totalDays');
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = tripDetailsDataStyle;
    summarySheet.setRowHeight(summaryRow, 22);
    summaryRow++;

    summaryRow++; // Spacer

    // Summarised Expense Report Section
    final summarisedReportStyle = CellStyle(
      bold: true,
      verticalAlign: VerticalAlign.Center,
    );
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = TextCellValue('Summarised Expense Report');
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = summarisedReportStyle;
    summarySheet.setRowHeight(summaryRow, 22);
    summaryRow++;

    // Build pivot data
    final Map<String, Map<String, double>> pivotData = {};
    // Group by Head -> SubHead -> Bill Available/Not Available
    for (final expense in expenses) {
      final head = expense.head;
      final subHead = expense.subHead ?? '-';
      final key = '$head|$subHead';
      final billStatus = expense.billPaths.isNotEmpty ? 'Available' : 'Not Available';

      pivotData.putIfAbsent(key, () => {
        'Available': 0.0,
        'Not Available': 0.0,
      });
      pivotData[key]![billStatus] =
          (pivotData[key]![billStatus] ?? 0.0) + expense.amount;
    }

    // Sort pivot data by Head then Sub-head
    final sortedEntries = pivotData.entries.toList()
      ..sort((a, b) {
        final aParts = a.key.split('|');
        final bParts = b.key.split('|');
        final headCompare = aParts[0].compareTo(bParts[0]);
        if (headCompare != 0) return headCompare;
        return aParts[1].compareTo(bParts[1]);
      });

    // Table Headers (starting from column 1, column 0 is already blank)
    final pivotHeaders = ['Expense Head', 'Sub Head', 'Amount with Bill', 'Amount without Bill', 'Sub-total'];
    // Insert empty cell at the beginning for the blank column
    final headerRow = [TextCellValue('')]..addAll(pivotHeaders.map((e) => TextCellValue(e)).toList());
    summarySheet.appendRow(headerRow);
    final pivotHeaderRow = summaryRow;
    
    // Left align style for Head and Sub Head columns
    final leftAlignStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    
    // Right align style for amount columns
    final rightAlignHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    
    // Apply styles to headers (skip column 0 which is blank)
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: pivotHeaderRow))
        .cellStyle = leftAlignStyle; // Expense Head - left aligned
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: pivotHeaderRow))
        .cellStyle = leftAlignStyle; // Sub Head - left aligned
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: pivotHeaderRow))
        .cellStyle = rightAlignHeaderStyle; // Amount with Bill - right aligned
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: pivotHeaderRow))
        .cellStyle = rightAlignHeaderStyle; // Amount without Bill - right aligned
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: pivotHeaderRow))
        .cellStyle = rightAlignHeaderStyle; // Sub-total - right aligned
    
    // Set row height for header
    summarySheet.setRowHeight(pivotHeaderRow, 22);
    summaryRow++;

    // Data row styles
    final leftAlignDataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final rightAlignDataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    // Table Data
    double grandTotalWithBill = 0.0;
    double grandTotalWithoutBill = 0.0;
    double grandSubTotal = 0.0;
    
    for (final entry in sortedEntries) {
      final parts = entry.key.split('|');
      final head = parts[0];
      final subHead = parts[1];
      final available = entry.value['Available'] ?? 0.0;
      final notAvailable = entry.value['Not Available'] ?? 0.0;
      final subTotal = available + notAvailable;

      grandTotalWithBill += available;
      grandTotalWithoutBill += notAvailable;
      grandSubTotal += subTotal;

      final dataRow = summaryRow;
      // Insert empty cell at the beginning for the blank column
      summarySheet.appendRow([
        TextCellValue(''), // Blank column
        TextCellValue(head),
        TextCellValue(subHead),
        DoubleCellValue(available),
        DoubleCellValue(notAvailable),
        DoubleCellValue(subTotal),
      ]);
      
      // Apply alignment styles (skip column 0 which is blank)
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dataRow))
          .cellStyle = leftAlignDataStyle; // Expense Head - left aligned
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: dataRow))
          .cellStyle = leftAlignDataStyle; // Sub Head - left aligned
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: dataRow))
          .cellStyle = rightAlignDataStyle; // Amount with Bill - right aligned
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: dataRow))
          .cellStyle = rightAlignDataStyle; // Amount without Bill - right aligned
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: dataRow))
          .cellStyle = rightAlignDataStyle; // Sub-total - right aligned
      
      // Set row height
      summarySheet.setRowHeight(dataRow, 22);
      summaryRow++;
    }

    // Grand Total Row (or "Total Expenses" when advances exist)
    final grandTotalRow = summaryRow;
    final grandTotalLabel = (advances?.isNotEmpty == true)
        ? 'Total Expenses'
        : 'Grand Total';
    // Insert empty cell at the beginning for the blank column
    summarySheet.appendRow([
      TextCellValue(''), // Blank column
      TextCellValue(grandTotalLabel),
      TextCellValue(''),
      DoubleCellValue(grandTotalWithBill),
      DoubleCellValue(grandTotalWithoutBill),
      DoubleCellValue(grandSubTotal),
    ]);
    
    // Apply styles to grand total row (same as header style, or light grey when advances exist)
    final grandTotalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final grandTotalRightStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final lightGreyTotalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.grey200,
      fontColorHex: ExcelColor.black,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final lightGreyTotalRightStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.grey200,
      fontColorHex: ExcelColor.black,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final totalRowLeft = (advances?.isNotEmpty == true) ? lightGreyTotalStyle : grandTotalStyle;
    final totalRowRight = (advances?.isNotEmpty == true) ? lightGreyTotalRightStyle : grandTotalRightStyle;
    // Skip column 0 (blank), style columns 1-5
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: grandTotalRow))
        .cellStyle = totalRowLeft;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: grandTotalRow))
        .cellStyle = totalRowLeft;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: grandTotalRow))
        .cellStyle = totalRowRight;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: grandTotalRow))
        .cellStyle = totalRowRight;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: grandTotalRow))
        .cellStyle = totalRowRight;
    
    // Set row height for grand total
    summarySheet.setRowHeight(grandTotalRow, 22);
    summaryRow++;

    // When advances exist: add Advance row and Amount to submit/Due/Reimburse row
    if (advances?.isNotEmpty == true) {
      final totalAdvances = advances!.fold<double>(0.0, (s, a) => s + a.amount);
      final diff = (grandSubTotal - totalAdvances).abs();

      String thirdRowLabel;
      if (totalAdvances > grandSubTotal) {
        thirdRowLabel = 'Amount to be submitted';
      } else if ((totalAdvances - grandSubTotal).abs() < 0.01) {
        thirdRowLabel = 'Due';
      } else {
        thirdRowLabel = 'Amount to be Reimburse';
      }

      // Advance row: Amount with Bill and Amount without Bill show '-'; only Sub-total has the value
      final advanceRow = summaryRow;
      summarySheet.appendRow([
        TextCellValue(''),
        TextCellValue('Advance'),
        TextCellValue(''),
        TextCellValue('-'),
        TextCellValue('-'),
        DoubleCellValue(totalAdvances),
      ]);
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: advanceRow))
          .cellStyle = lightGreyTotalStyle;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: advanceRow))
          .cellStyle = lightGreyTotalStyle;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: advanceRow))
          .cellStyle = lightGreyTotalRightStyle;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: advanceRow))
          .cellStyle = lightGreyTotalRightStyle;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: advanceRow))
          .cellStyle = lightGreyTotalRightStyle;
      summarySheet.setRowHeight(advanceRow, 22);
      summaryRow++;

      // Third row: Amount to be submitted / Due / Amount to be Reimburse (black bg); Amount with Bill and Amount without Bill show '-'
      final thirdRow = summaryRow;
      summarySheet.appendRow([
        TextCellValue(''),
        TextCellValue(thirdRowLabel),
        TextCellValue(''),
        TextCellValue('-'),
        TextCellValue('-'),
        DoubleCellValue(diff),
      ]);
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: thirdRow))
          .cellStyle = grandTotalStyle;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: thirdRow))
          .cellStyle = grandTotalStyle;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: thirdRow))
          .cellStyle = grandTotalRightStyle;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: thirdRow))
          .cellStyle = grandTotalRightStyle;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: thirdRow))
          .cellStyle = grandTotalRightStyle;
      summarySheet.setRowHeight(thirdRow, 22);
      summaryRow++;
    }

    // Calculate and set column widths to fit content
    // Column 0: Blank column (already set to 15px)
    
    // Column 1: Expense Head
    double maxHeadWidth = 'Expense Head'.length.toDouble();
    for (final entry in sortedEntries) {
      final head = entry.key.split('|')[0];
      maxHeadWidth = maxHeadWidth > head.length.toDouble() 
          ? maxHeadWidth 
          : head.length.toDouble();
    }
    maxHeadWidth = maxHeadWidth > 'Grand Total'.length.toDouble()
        ? maxHeadWidth
        : 'Grand Total'.length.toDouble();
    if (advances?.isNotEmpty == true) {
      for (final label in ['Total Expenses', 'Advance', 'Amount to be submitted', 'Due', 'Amount to be Reimburse']) {
        if (label.length.toDouble() > maxHeadWidth) maxHeadWidth = label.length.toDouble();
      }
    }
    summarySheet.setColumnWidth(1, maxHeadWidth + 2); // Add padding

    // Column 2: Sub Head
    double maxSubHeadWidth = 'Sub Head'.length.toDouble();
    for (final entry in sortedEntries) {
      final subHead = entry.key.split('|')[1];
      maxSubHeadWidth = maxSubHeadWidth > subHead.length.toDouble()
          ? maxSubHeadWidth
          : subHead.length.toDouble();
    }
    summarySheet.setColumnWidth(2, maxSubHeadWidth + 2); // Add padding

    // Column 3: Amount with Bill
    double maxAmountWithBillWidth = 'Amount with Bill'.length.toDouble();
    for (final entry in sortedEntries) {
      final amount = entry.value['Available'] ?? 0.0;
      final amountStr = amount.toStringAsFixed(2);
      maxAmountWithBillWidth = maxAmountWithBillWidth > amountStr.length.toDouble()
          ? maxAmountWithBillWidth
          : amountStr.length.toDouble();
    }
    final grandTotalWithBillStr = grandTotalWithBill.toStringAsFixed(2);
    maxAmountWithBillWidth = maxAmountWithBillWidth > grandTotalWithBillStr.length.toDouble()
        ? maxAmountWithBillWidth
        : grandTotalWithBillStr.length.toDouble();
    summarySheet.setColumnWidth(3, maxAmountWithBillWidth + 2); // Add padding

    // Column 4: Amount without Bill
    double maxAmountWithoutBillWidth = 'Amount without Bill'.length.toDouble();
    for (final entry in sortedEntries) {
      final amount = entry.value['Not Available'] ?? 0.0;
      final amountStr = amount.toStringAsFixed(2);
      maxAmountWithoutBillWidth = maxAmountWithoutBillWidth > amountStr.length.toDouble()
          ? maxAmountWithoutBillWidth
          : amountStr.length.toDouble();
    }
    final grandTotalWithoutBillStr = grandTotalWithoutBill.toStringAsFixed(2);
    maxAmountWithoutBillWidth = maxAmountWithoutBillWidth > grandTotalWithoutBillStr.length.toDouble()
        ? maxAmountWithoutBillWidth
        : grandTotalWithoutBillStr.length.toDouble();
    summarySheet.setColumnWidth(4, maxAmountWithoutBillWidth + 2); // Add padding

    // Column 5: Sub-total
    double maxSubTotalWidth = 'Sub-total'.length.toDouble();
    for (final entry in sortedEntries) {
      final subTotal = (entry.value['Available'] ?? 0.0) + (entry.value['Not Available'] ?? 0.0);
      final subTotalStr = subTotal.toStringAsFixed(2);
      maxSubTotalWidth = maxSubTotalWidth > subTotalStr.length.toDouble()
          ? maxSubTotalWidth
          : subTotalStr.length.toDouble();
    }
    final grandSubTotalStr = grandSubTotal.toStringAsFixed(2);
    maxSubTotalWidth = maxSubTotalWidth > grandSubTotalStr.length.toDouble()
        ? maxSubTotalWidth
        : grandSubTotalStr.length.toDouble();
    if (advances?.isNotEmpty == true) {
      final totalAdvances = advances!.fold<double>(0.0, (s, a) => s + a.amount);
      final diff = (grandSubTotal - totalAdvances).abs();
      for (final v in [totalAdvances, diff]) {
        final str = v.toStringAsFixed(2);
        if (str.length.toDouble() > maxSubTotalWidth) maxSubTotalWidth = str.length.toDouble();
      }
    }
    summarySheet.setColumnWidth(5, maxSubTotalWidth + 2); // Add padding

    summaryRow++; // Spacer

    // Total Amounts Section
    final totalAmount = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final amountWithBill = expenses
        .where((e) => e.billPaths.isNotEmpty)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final amountWithoutBill = expenses
        .where((e) => e.billPaths.isEmpty)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final percentageWithBill =
        totalAmount > 0 ? (amountWithBill / totalAmount * 100) : 0.0;
    final percentageWithoutBill =
        totalAmount > 0 ? (amountWithoutBill / totalAmount * 100) : 0.0;

    final totalAmountStyle = CellStyle(
      bold: true,
      verticalAlign: VerticalAlign.Center,
    );

    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = TextCellValue(
        'Total amount requested with Bill: ${amountWithBill.toStringAsFixed(2)} (${percentageWithBill.toStringAsFixed(2)}%)');
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = totalAmountStyle;
    summarySheet.setRowHeight(summaryRow, 22);
    summaryRow++;

    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = TextCellValue(
        'Total amount requested without Bill: ${amountWithoutBill.toStringAsFixed(2)} (${percentageWithoutBill.toStringAsFixed(2)}%)');
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = totalAmountStyle;
    summarySheet.setRowHeight(summaryRow, 22);
    summaryRow++;

    // Create Detailed Entry Sheet
    final detailedSheet = excel['Detailed Entry'];
    int detailedRow = 0;

    // Styles for Detailed Entry sheet
    final detailedHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    final detailedCenterHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    final detailedLeftHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    
    final detailedRightHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    
    final detailedCenterDataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    final detailedLeftDataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    
    final detailedRightDataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    // Headers for Detailed Entry
    final detailedHeaders = [
      'Bill ID',
      'Head',
      'Sub Head',
      'Notes',
      'Start Date',
      'End Date',
      'From Location',
      'To Location',
      'PAX',
      'Bill',
      'Amount',
    ];
    detailedSheet.appendRow(detailedHeaders.map((e) => TextCellValue(e)).toList());
    final headerRowIndex = detailedRow;
    
    // Apply header styles based on column
    // Column 0: Bill ID - Center
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRowIndex))
        .cellStyle = detailedCenterHeaderStyle;
    // Column 1: Head - Left
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRowIndex))
        .cellStyle = detailedLeftHeaderStyle;
    // Column 2: Sub Head - Left
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: headerRowIndex))
        .cellStyle = detailedLeftHeaderStyle;
    // Column 3: Notes - Left
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRowIndex))
        .cellStyle = detailedLeftHeaderStyle;
    // Column 4: Start Date - Right
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: headerRowIndex))
        .cellStyle = detailedRightHeaderStyle;
    // Column 5: End Date - Right
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: headerRowIndex))
        .cellStyle = detailedRightHeaderStyle;
    // Column 6: From Location - Left
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: headerRowIndex))
        .cellStyle = detailedLeftHeaderStyle;
    // Column 7: To Location - Left
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: headerRowIndex))
        .cellStyle = detailedLeftHeaderStyle;
    // Column 8: PAX - Left
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: headerRowIndex))
        .cellStyle = detailedLeftHeaderStyle;
    // Column 9: Bill - Left
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: headerRowIndex))
        .cellStyle = detailedLeftHeaderStyle;
    // Column 10: Amount - Right
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: headerRowIndex))
        .cellStyle = detailedRightHeaderStyle;
    
    detailedSheet.setRowHeight(headerRowIndex, 20);
    detailedRow++;

    // Detailed Entry Data (display ID = 1-based index, label remains "Bill ID")
    double grandTotalAmount = 0.0;
    for (var i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      final displayId = (i + 1).toString();
      grandTotalAmount += expense.amount;
      final dataRowIndex = detailedRow;
      detailedSheet.appendRow([
        TextCellValue(displayId),
        TextCellValue(expense.head),
        TextCellValue(expense.subHead ?? '-'),
        TextCellValue(expense.notes ?? '-'),
        TextCellValue(DateFormat('dd-MM-yyyy').format(expense.startDate)),
        TextCellValue(DateFormat('dd-MM-yyyy').format(expense.endDate)),
        TextCellValue(expense.city),
        TextCellValue(expense.toCity ?? '-'),
        TextCellValue(expense.pax?.toString() ?? '-'),
        TextCellValue(expense.billPaths.isNotEmpty ? 'Available' : 'Not Available'),
        DoubleCellValue((expense.amount * 100).round() / 100.0),
      ]);
      
      // Apply data styles based on column
      // Column 0: Bill ID - Center
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: dataRowIndex))
          .cellStyle = detailedCenterDataStyle;
      // Column 1: Head - Left
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dataRowIndex))
          .cellStyle = detailedLeftDataStyle;
      // Column 2: Sub Head - Left
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: dataRowIndex))
          .cellStyle = detailedLeftDataStyle;
      // Column 3: Notes - Left
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: dataRowIndex))
          .cellStyle = detailedLeftDataStyle;
      // Column 4: Start Date - Right
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: dataRowIndex))
          .cellStyle = detailedRightDataStyle;
      // Column 5: End Date - Right
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: dataRowIndex))
          .cellStyle = detailedRightDataStyle;
      // Column 6: From Location - Left
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: dataRowIndex))
          .cellStyle = detailedLeftDataStyle;
      // Column 7: To Location - Left
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: dataRowIndex))
          .cellStyle = detailedLeftDataStyle;
      // Column 8: PAX - Left
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: dataRowIndex))
          .cellStyle = detailedLeftDataStyle;
      // Column 9: Bill - Left
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: dataRowIndex))
          .cellStyle = detailedLeftDataStyle;
      // Column 10: Amount - Right
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: dataRowIndex))
          .cellStyle = detailedRightDataStyle;
      
      detailedSheet.setRowHeight(dataRowIndex, 20);
      detailedRow++;
    }

    // Grand Total Row
    final grandTotalRowIndex = detailedRow;
    detailedSheet.appendRow([
      TextCellValue('Grand Total'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue((grandTotalAmount * 100).round() / 100.0),
    ]);
    
    // Apply Grand Total row styles (same as header - black background, white text, bold)
    // All cells in Grand Total row should have black background
    final detailedGrandTotalLeftStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    
    final detailedGrandTotalRightStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.black,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    
    // Style all cells in Grand Total row
    for (var i = 0; i < detailedHeaders.length; i++) {
      if (i == 10) {
        // Amount column - right aligned
        detailedSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: grandTotalRowIndex))
            .cellStyle = detailedGrandTotalRightStyle;
      } else {
        // All other columns - left aligned with black background
        detailedSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: grandTotalRowIndex))
            .cellStyle = detailedGrandTotalLeftStyle;
      }
    }
    
    detailedSheet.setRowHeight(grandTotalRowIndex, 20);

    // Calculate and set column widths to fit content
    // Column 0: Bill ID (display ID = 1-based index)
    double maxBillIdWidth = 'Bill ID'.length.toDouble();
    if (expenses.isNotEmpty) {
      final maxDisplayIdLen = (expenses.length).toString().length.toDouble();
      if (maxDisplayIdLen > maxBillIdWidth) maxBillIdWidth = maxDisplayIdLen;
    }
    detailedSheet.setColumnWidth(0, maxBillIdWidth + 2);

    // Column 1: Head
    double maxDetailedHeadWidth = 'Head'.length.toDouble();
    for (final expense in expenses) {
      if (expense.head.length.toDouble() > maxDetailedHeadWidth) {
        maxDetailedHeadWidth = expense.head.length.toDouble();
      }
    }
    detailedSheet.setColumnWidth(1, maxDetailedHeadWidth + 2);

    // Column 2: Sub Head
    double maxDetailedSubHeadWidth = 'Sub Head'.length.toDouble();
    for (final expense in expenses) {
      final subHead = expense.subHead ?? '-';
      if (subHead.length.toDouble() > maxDetailedSubHeadWidth) {
        maxDetailedSubHeadWidth = subHead.length.toDouble();
      }
    }
    detailedSheet.setColumnWidth(2, maxDetailedSubHeadWidth + 2);

    // Column 3: Notes
    double maxNotesWidth = 'Notes'.length.toDouble();
    for (final expense in expenses) {
      final notes = expense.notes ?? '-';
      if (notes.length.toDouble() > maxNotesWidth) {
        maxNotesWidth = notes.length.toDouble();
      }
    }
    detailedSheet.setColumnWidth(3, maxNotesWidth + 2);

    // Column 4: Start Date
    double maxStartDateWidth = 'Start Date'.length.toDouble();
    final startDateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    if (startDateStr.length.toDouble() > maxStartDateWidth) {
      maxStartDateWidth = startDateStr.length.toDouble();
    }
    detailedSheet.setColumnWidth(4, maxStartDateWidth + 2);

    // Column 5: End Date
    double maxEndDateWidth = 'End Date'.length.toDouble();
    final endDateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    if (endDateStr.length.toDouble() > maxEndDateWidth) {
      maxEndDateWidth = endDateStr.length.toDouble();
    }
    detailedSheet.setColumnWidth(5, maxEndDateWidth + 2);

    // Column 6: From Location
    double maxFromLocationWidth = 'From Location'.length.toDouble();
    for (final expense in expenses) {
      if (expense.city.length.toDouble() > maxFromLocationWidth) {
        maxFromLocationWidth = expense.city.length.toDouble();
      }
    }
    detailedSheet.setColumnWidth(6, maxFromLocationWidth + 2);

    // Column 7: To Location
    double maxToLocationWidth = 'To Location'.length.toDouble();
    for (final expense in expenses) {
      final toCity = expense.toCity ?? '-';
      if (toCity.length.toDouble() > maxToLocationWidth) {
        maxToLocationWidth = toCity.length.toDouble();
      }
    }
    detailedSheet.setColumnWidth(7, maxToLocationWidth + 2);

    // Column 8: PAX
    double maxPaxWidth = 'PAX'.length.toDouble();
    for (final expense in expenses) {
      final paxStr = expense.pax?.toString() ?? '-';
      if (paxStr.length.toDouble() > maxPaxWidth) {
        maxPaxWidth = paxStr.length.toDouble();
      }
    }
    detailedSheet.setColumnWidth(8, maxPaxWidth + 2);

    // Column 9: Bill
    double maxBillWidth = 'Bill'.length.toDouble();
    final billStatusStr = 'Not Available';
    if (billStatusStr.length.toDouble() > maxBillWidth) {
      maxBillWidth = billStatusStr.length.toDouble();
    }
    detailedSheet.setColumnWidth(9, maxBillWidth + 2);

    // Column 10: Amount
    double maxAmountWidth = 'Amount'.length.toDouble();
    for (final expense in expenses) {
      final amountStr = expense.amount.toStringAsFixed(2);
      if (amountStr.length.toDouble() > maxAmountWidth) {
        maxAmountWidth = amountStr.length.toDouble();
      }
    }
    detailedSheet.setColumnWidth(10, maxAmountWidth + 2);

    // Ensure Sheet1 is deleted before saving
    try {
      excel.delete('Sheet1');
    } catch (e) {
      // Sheet1 might not exist, ignore error
    }

    // Save and Download
    final bytes = excel.save();
    
    // IMPORTANT: Clean up immediately after excel.save() in case it created any files
    // The Excel package may create FlutterExcel.xlsx internally
    await _cleanupFlutterExcelFiles();
    
    if (bytes != null) {
      if (kIsWeb) {
        downloadFile(
          Uint8List.fromList(bytes),
          '${trip.name}_report.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        return null; // Web doesn't return a file path
      } else {
        final directory = await _getDownloadDirectory();
        final fileName = '${trip.name}_report.xlsx';
        final path = "${directory.path}/$fileName";
        
        // Clean up any existing files with the same name or FlutterExcel.xlsx
        await _cleanupOldFiles(directory, fileName);
        
        final file = File(path);
        await file.writeAsBytes(bytes);
        
        // Clean up FlutterExcel.xlsx only (do NOT call _cleanupOldFiles here:
        // it would delete the file we just wrote)
        await _cleanupFlutterExcelFiles();
        
        return path;
      }
    }
    return null;
  }

  /// Comprehensively cleans up FlutterExcel.xlsx files from all possible locations
  /// This checks temp, external storage, cache, and documents directories
  Future<void> _cleanupFlutterExcelFiles() async {
    try {
      final directoriesToCheck = <Future<Directory?>>[];
      
      // Check temporary directory
      try {
        directoriesToCheck.add(getTemporaryDirectory());
      } catch (e) {
        // Ignore errors
      }
      
      // Check external storage directory (Android)
      if (Platform.isAndroid) {
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) directoriesToCheck.add(Future.value(externalDir));
        } catch (e) {
          // Ignore errors
        }
      }
      
      // Check application documents directory (where we save files)
      try {
        directoriesToCheck.add(getApplicationDocumentsDirectory());
      } catch (e) {
        // Ignore errors
      }
      
      // Check application support directory (cache location)
      try {
        directoriesToCheck.add(getApplicationSupportDirectory());
      } catch (e) {
        // Ignore errors
      }
      
      // Clean up FlutterExcel.xlsx from all checked directories
      final dirs = await Future.wait(directoriesToCheck);
      for (final dir in dirs) {
        if (dir == null) continue;
        
        try {
          if (await dir.exists()) {
            final files = dir.listSync();
            for (final file in files) {
              if (file is File && file.path.endsWith('.xlsx')) {
                final fileName = file.path.split(Platform.pathSeparator).last;
                // Delete any FlutterExcel.xlsx files
                if (fileName == 'FlutterExcel.xlsx' || fileName.startsWith('FlutterExcel')) {
                  try {
                    await file.delete();
                  } catch (e) {
                    // Ignore deletion errors
                  }
                }
              }
            }
          }
        } catch (e) {
          // Ignore errors for individual directories
        }
      }
    } catch (e) {
      // Ignore all cleanup errors - continue with file creation
    }
  }

  /// Cleans up old Excel files that might have been created
  Future<void> _cleanupOldFiles(Directory directory, String correctFileName) async {
    try {
      // Delete the target file if it already exists (to avoid duplicates)
      final targetFile = File("${directory.path}/$correctFileName");
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      
      // Delete any FlutterExcel.xlsx files that might have been created
      final flutterExcelFile = File("${directory.path}/FlutterExcel.xlsx");
      if (await flutterExcelFile.exists()) {
        await flutterExcelFile.delete();
      }
      
      // Also check for any other files with similar names that might be duplicates
      // List all files in the directory and check for duplicates
      if (await directory.exists()) {
        final files = directory.listSync();
        for (final file in files) {
          if (file is File && file.path.endsWith('.xlsx')) {
            final fileName = file.path.split('/').last;
            // Delete FlutterExcel.xlsx or any files with FlutterExcel in the name
            if (fileName == 'FlutterExcel.xlsx' || 
                fileName.startsWith('FlutterExcel') ||
                (fileName != correctFileName && fileName.contains('FlutterExcel'))) {
              try {
                await file.delete();
              } catch (e) {
                // Ignore errors when deleting old files
              }
            }
          }
        }
      }
      
      // Also check temporary directory for any FlutterExcel.xlsx files
      try {
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          final tempFiles = tempDir.listSync();
          for (final file in tempFiles) {
            if (file is File && file.path.endsWith('.xlsx')) {
              final fileName = file.path.split('/').last;
              if (fileName == 'FlutterExcel.xlsx' || fileName.startsWith('FlutterExcel')) {
                try {
                  await file.delete();
                } catch (e) {
                  // Ignore errors
                }
              }
            }
          }
        }
      } catch (e) {
        // Ignore temp directory cleanup errors
      }
    } catch (e) {
      // Ignore cleanup errors - continue with file creation
    }
  }

  /// Returns the Expenza folder for exports. Creates it if missing.
  /// - Android: tries Internal storage > Expenza (/storage/emulated/0/Expenza) first
  ///   when MANAGE_EXTERNAL_STORAGE is granted; else falls back to app-specific
  ///   downloads, external, or app documents/Expenza.
  /// - iOS / others: app documents/Expenza
  Future<Directory> _getDownloadDirectory() async {
    Directory base;
    if (Platform.isAndroid) {
      try {
        final root = Directory('/storage/emulated/0/Expenza');
        await root.create(recursive: true);
        base = root;
      } catch (_) {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          base = Directory('${downloads.path}/Expenza');
        } else {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            base = Directory('${ext.path}/Expenza');
          } else {
            final appDoc = await getApplicationDocumentsDirectory();
            base = Directory('${appDoc.path}/Expenza');
          }
        }
        if (!await base.exists()) {
          await base.create(recursive: true);
        }
      }
    } else {
      final appDoc = await getApplicationDocumentsDirectory();
      base = Directory('${appDoc.path}/Expenza');
      if (!await base.exists()) {
        await base.create(recursive: true);
      }
    }
    return base;
  }

  /// Returns the path to the saved file, or null for web
  Future<String?> exportToPdf(
    Trip trip,
    List<Expense> expenses, {
    UserProfile? userProfile,
  }) async {
    // Load Unicode-capable font for rupee symbol support
    pw.Font? robotoRegular;
    pw.Font? robotoBold;
    
    try {
      final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      robotoRegular = pw.Font.ttf(regularData.buffer.asByteData());
      debugPrint('✓ Successfully loaded Roboto-Regular.ttf (${regularData.lengthInBytes} bytes)');
    } catch (e) {
      debugPrint('✗ ERROR: Could not load Roboto-Regular.ttf: $e');
      debugPrint('  Make sure:');
      debugPrint('  1. Font file exists at assets/fonts/Roboto-Regular.ttf');
      debugPrint('  2. pubspec.yaml includes assets/fonts/ in assets section');
      debugPrint('  3. You ran "flutter pub get"');
      debugPrint('  4. You FULLY RESTARTED the app (not just hot restart)');
    }
    
    try {
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      robotoBold = pw.Font.ttf(boldData.buffer.asByteData());
      debugPrint('✓ Successfully loaded Roboto-Bold.ttf (${boldData.lengthInBytes} bytes)');
    } catch (e) {
      debugPrint('✗ ERROR: Could not load Roboto-Bold.ttf: $e');
      // Fallback to regular font for bold
      robotoBold = robotoRegular;
    }
    
    // Use default font if Roboto not available (fallback)
    final baseFont = robotoRegular;
    final boldFont = robotoBold ?? robotoRegular;
    
    if (baseFont == null) {
      debugPrint('⚠ WARNING: No Unicode font loaded. Rupee symbol (₹) may not display correctly.');
      debugPrint('  PDF will use default font which may show "?" or blank for rupee symbol.');
    } else {
      debugPrint('✓ Fonts ready for PDF generation with rupee symbol support');
    }
    
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final dateRangeFormat = DateFormat('dd-MM-yyyy');

    // Calculate summary data (same as Excel export)
    final Map<String, Map<String, double>> pivotData = {};
    for (final expense in expenses) {
      final head = expense.head;
      final subHead = expense.subHead ?? '-';
      final key = '$head|$subHead';
      final billStatus = expense.billPaths.isNotEmpty ? 'Available' : 'Not Available';

      pivotData.putIfAbsent(key, () => {
        'Available': 0.0,
        'Not Available': 0.0,
      });
      pivotData[key]![billStatus] =
          (pivotData[key]![billStatus] ?? 0.0) + expense.amount;
    }

    // Sort pivot data by Head then Sub-head
    final sortedEntries = pivotData.entries.toList()
      ..sort((a, b) {
        final aParts = a.key.split('|');
        final bParts = b.key.split('|');
        final headCompare = aParts[0].compareTo(bParts[0]);
        if (headCompare != 0) return headCompare;
        return aParts[1].compareTo(bParts[1]);
      });

    // Calculate grand totals
    double grandTotalWithBill = 0.0;
    double grandTotalWithoutBill = 0.0;
    double grandSubTotal = 0.0;

    for (final entry in sortedEntries) {
      final available = entry.value['Available'] ?? 0.0;
      final notAvailable = entry.value['Not Available'] ?? 0.0;
      grandTotalWithBill += available;
      grandTotalWithoutBill += notAvailable;
      grandSubTotal += (available + notAvailable);
    }

    // Calculate total days
    final totalDays = trip.endDate != null
        ? trip.endDate!.difference(trip.startDate).inDays + 1
        : DateTime.now().difference(trip.startDate).inDays + 1;

    // Create stylish first page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title Section with stylish design
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey900,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EXPENSE REPORT SUMMARY',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 1.2,
                        font: boldFont,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      trip.name,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.6,
                        font: boldFont,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      '${dateFormat.format(trip.startDate)} to ${trip.endDate != null ? dateFormat.format(trip.endDate!) : dateFormat.format(DateTime.now())} [${totalDays} ${totalDays == 1 ? 'Day' : 'Days'}]',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey300,
                        letterSpacing: 0.4,
                        font: baseFont,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Location covered: ',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey900,
                        letterSpacing: 0.4,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                      ),
                    ),
                    pw.TextSpan(
                      text: ([...trip.cities]..sort()).join(', '),
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey900,
                        letterSpacing: 0.4,
                        font: baseFont,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Submitter Details Section
              if (userProfile != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Submitter Details',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                          font: boldFont,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildInfoRow('Employee Name', userProfile.fullName, font: baseFont, boldFont: boldFont),
                      pw.SizedBox(height: 6),
                      _buildInfoRow('Employee ID', userProfile.employeeId, font: baseFont, boldFont: boldFont),
                      pw.SizedBox(height: 6),
                      _buildInfoRow('Employee Email', userProfile.email, font: baseFont, boldFont: boldFont),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Summary Table Title
              pw.Text(
                'Summarised Expense Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                  font: boldFont,
                ),
              ),
              pw.SizedBox(height: 8),

              // Summary Table
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.IntrinsicColumnWidth(), // Expense Head - fit content
                  1: const pw.IntrinsicColumnWidth(), // Sub Head - fit content
                  2: const pw.IntrinsicColumnWidth(), // Amount with Bill - fit content
                  3: const pw.IntrinsicColumnWidth(), // Amount without Bill - fit content
                  4: const pw.IntrinsicColumnWidth(), // Sub-total - fit content
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey900,
                    ),
                    children: [
                      _buildTableCell('Expense Head', isHeader: true, alignLeft: true, font: baseFont, boldFont: boldFont),
                      _buildTableCell('Sub Head', isHeader: true, alignLeft: true, font: baseFont, boldFont: boldFont),
                      _buildTableCell('Amount with Bill', isHeader: true, alignLeft: false, font: baseFont, boldFont: boldFont),
                      _buildTableCell('Amount without Bill', isHeader: true, alignLeft: false, font: baseFont, boldFont: boldFont),
                      _buildTableCell('Sub-total', isHeader: true, alignLeft: false, font: baseFont, boldFont: boldFont),
                    ],
                  ),
                  // Data Rows
                  ...sortedEntries.map((entry) {
                    final parts = entry.key.split('|');
                    final head = parts[0];
                    final subHead = parts[1];
                    final available = entry.value['Available'] ?? 0.0;
                    final notAvailable = entry.value['Not Available'] ?? 0.0;
                    final subTotal = available + notAvailable;

                    return pw.TableRow(
                      children: [
                        _buildTableCell(head, isHeader: false, alignLeft: true, font: baseFont, boldFont: boldFont),
                        _buildTableCell(subHead, isHeader: false, alignLeft: true, font: baseFont, boldFont: boldFont),
                        _buildTableCell(
                          '₹ ${available.toStringAsFixed(2)}',
                          isHeader: false,
                          alignLeft: false,
                          font: baseFont,
                          boldFont: boldFont,
                        ),
                        _buildTableCell(
                          '₹ ${notAvailable.toStringAsFixed(2)}',
                          isHeader: false,
                          alignLeft: false,
                          font: baseFont,
                          boldFont: boldFont,
                        ),
                        _buildTableCell(
                          '₹ ${subTotal.toStringAsFixed(2)}',
                          isHeader: false,
                          alignLeft: false,
                          font: baseFont,
                          boldFont: boldFont,
                        ),
                      ],
                    );
                  }),
                  // Grand Total Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey900,
                    ),
                    children: [
                      _buildTableCell('Grand Total', isHeader: true, alignLeft: true, font: baseFont, boldFont: boldFont),
                      _buildTableCell('', isHeader: true, alignLeft: true, font: baseFont, boldFont: boldFont),
                      _buildTableCell(
                        '₹ ${grandTotalWithBill.toStringAsFixed(2)}',
                        isHeader: true,
                        alignLeft: false,
                        font: baseFont,
                        boldFont: boldFont,
                      ),
                      _buildTableCell(
                        '₹ ${grandTotalWithoutBill.toStringAsFixed(2)}',
                        isHeader: true,
                        alignLeft: false,
                        font: baseFont,
                        boldFont: boldFont,
                      ),
                      _buildTableCell(
                        '₹ ${grandSubTotal.toStringAsFixed(2)}',
                        isHeader: true,
                        alignLeft: false,
                        font: baseFont,
                        boldFont: boldFont,
                      ),
                    ],
                  ),
                ],
              ),
              
              // Expense Head Distribution Chart
              if (grandSubTotal > 0) ...[
                pw.SizedBox(height: 20),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(120), // Header column
                    1: const pw.FlexColumnWidth(), // Chart column
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        // Column 1: Header
                        pw.Container(
                          alignment: pw.Alignment.topLeft,
                          child: pw.Text(
                            'Expense Head Distribution',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                              font: boldFont,
                            ),
                          ),
                        ),
                        // Column 2: Chart and Legend
                        pw.Container(
                          alignment: pw.Alignment.topLeft,
                          child: _buildExpenseHeadChart(expenses, grandSubTotal, baseFont, boldFont),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.only(top: 12),
                          alignment: pw.Alignment.topLeft,
                          child: pw.Text(
                            'Expense Sub-Head Distribution',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                              font: boldFont,
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.only(top: 12),
                          alignment: pw.Alignment.topLeft,
                          child: _buildExpenseSubHeadChart(expenses, grandSubTotal, baseFont, boldFont),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
              
              pw.Expanded(child: pw.SizedBox()),
              // Report Generated Timestamp
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Report Generated at ${DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now())} IST',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                    font: baseFont,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Add Evidence Images as Appendix (display ID = 1-based index, label "Bill ID")
    for (var expenseIndex = 0; expenseIndex < expenses.length; expenseIndex++) {
      final expense = expenses[expenseIndex];
      final displayId = expenseIndex + 1;
      if (expense.billPaths.isNotEmpty) {
        for (var j = 0; j < expense.billPaths.length; j++) {
          final path = expense.billPaths[j];
          try {
            final File imageFile = File(path);
            if (await imageFile.exists()) {
              final imageBytes = await imageFile.readAsBytes();
              if (imageBytes.isNotEmpty) {
                try {
                  final image = pw.MemoryImage(imageBytes);
                  pdf.addPage(
                    pw.Page(
                      pageFormat: PdfPageFormat.a4,
                      build: (pw.Context context) {
                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Header: Left = Bill ID (display ID, bold, primary); Right = startDate - endDate • Page j/n
                            pw.Header(
                              level: 1,
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Bill #$displayId',
                                    style: pw.TextStyle(
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColor(37/255, 99/255, 235/255),
                                      font: boldFont,
                                    ),
                                  ),
                                  pw.Text(
                                    '${dateFormat.format(expense.startDate)} - ${dateFormat.format(expense.endDate)} • Page ${j + 1}/${expense.billPaths.length}',
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      font: baseFont,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            // Subtitle: Left = Amount • [head>subHead] [Pax]; Right = from - to
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Amount: ₹ ${expense.amount.toStringAsFixed(2)} • [${expense.head} > ${expense.subHead ?? '-'}] [Pax: ${expense.pax ?? '-'}]',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    font: baseFont,
                                  ),
                                ),
                                pw.Text(
                                  '${expense.city}${expense.toCity != null && expense.toCity!.isNotEmpty ? ' - ${expense.toCity}' : ''}',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    font: baseFont,
                                  ),
                                ),
                              ],
                            ),
                            if (expense.notes != null &&
                                expense.notes!.isNotEmpty) ...[
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'Notes: ${expense.notes}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey700,
                                  font: baseFont,
                                ),
                              ),
                            ],
                            pw.SizedBox(height: 20),
                            pw.Expanded(
                              child: pw.Center(
                                child: pw.Image(image, fit: pw.BoxFit.contain),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                } catch (imageError) {
                  debugPrint('Error creating PDF image from file $path: $imageError');
                  // Continue to next image instead of failing completely
                }
              } else {
                debugPrint('Image file $path is empty');
              }
            } else {
              debugPrint('Image file $path does not exist');
            }
          } catch (e) {
            debugPrint('Error processing image file $path: $e');
            // Continue to next image instead of failing completely
          }
        }
      }
    }

    final bytes = await pdf.save();
    if (kIsWeb) {
      downloadFile(bytes, '${trip.name}_report.pdf', 'application/pdf');
      return null; // Web doesn't return a file path
    } else {
      final directory = await _getDownloadDirectory();
      final fileName = '${trip.name}_report.pdf';
      final path = "${directory.path}/$fileName";
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    }
  }

  // Helper method to build info rows in trip details section
  pw.Widget _buildInfoRow(String label, String value, {pw.Font? font, pw.Font? boldFont}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey900,
              font: font,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build table cells
  pw.Widget _buildTableCell(
    String text, {
    required bool isHeader,
    required bool alignLeft,
    pw.Font? font,
    pw.Font? boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.grey900,
          font: isHeader ? boldFont : font,
        ),
      ),
    );
  }

  // Helper method to build expense head chart
  pw.Widget _buildExpenseHeadChart(
    List<Expense> expenses,
    double totalAmount,
    pw.Font? font,
    pw.Font? boldFont,
  ) {
    // Calculate totals by expense head
    final Map<String, double> headTotals = {};
    for (final expense in expenses) {
      headTotals[expense.head] = (headTotals[expense.head] ?? 0.0) + expense.amount;
    }

    // Sort by amount (descending) for better visualization
    final sortedHeads = headTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Color scheme for different expense heads
    final headColors = {
      'Travel': PdfColors.blue700,
      'Accommodation': PdfColors.green700,
      'Food': PdfColors.orange700,
      'Event': PdfColors.purple700,
      'Miscellaneous': PdfColors.grey700,
    };

    // Calculate max bar width (available width minus padding and left column)
    // A4 page width = 595 points, with 40pt margins = 515pt available
    // Left column = 120pt, spacing = ~20pt, so chart column ≈ 375pt
    const maxBarWidth = 375.0;
    const barHeight = 24.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Stacked Bar Chart
        pw.Container(
          width: maxBarWidth,
          height: barHeight,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            children: sortedHeads.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              final head = entry.key;
              final amount = entry.value;
              final percentage = (amount / totalAmount) * 100;
              final isLast = index == sortedHeads.length - 1;
              // Calculate width, ensure last segment fills remaining space
              final width = isLast 
                  ? maxBarWidth - (sortedHeads.take(index).fold<double>(0.0, (sum, e) {
                      final pct = (e.value / totalAmount) * 100;
                      return sum + (maxBarWidth * pct / 100);
                    }))
                  : (maxBarWidth * percentage / 100);
              final color = headColors[head] ?? PdfColors.grey500;

              return pw.Container(
                width: width,
                height: barHeight,
                decoration: pw.BoxDecoration(
                  color: color,
                  border: !isLast 
                      ? pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                        )
                      : null,
                ),
                child: percentage > 5 && width > 40 // Only show label if segment is large enough
                    ? pw.Center(
                        child: pw.Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            font: boldFont,
                          ),
                        ),
                      )
                    : pw.SizedBox(),
              );
            }).toList(),
          ),
        ),
        pw.SizedBox(height: 12),
        
        // Legend
        pw.Wrap(
          spacing: 16,
          runSpacing: 8,
          children: sortedHeads.map((entry) {
            final head = entry.key;
            final amount = entry.value;
            final percentage = (amount / totalAmount) * 100;
            final color = headColors[head] ?? PdfColors.grey500;

            return pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Color indicator
                pw.Container(
                  width: 12,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    color: color,
                    shape: pw.BoxShape.rectangle,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                ),
                pw.SizedBox(width: 6),
                // Label and amount
                pw.Text(
                  '$head: ₹ ${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey900,
                    font: font,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper method to build expense sub-head chart (bigger to smaller, left to right)
  pw.Widget _buildExpenseSubHeadChart(
    List<Expense> expenses,
    double totalAmount,
    pw.Font? font,
    pw.Font? boldFont,
  ) {
    // Totals by "Head > SubHead"
    final Map<String, double> subHeadTotals = {};
    for (final expense in expenses) {
      final key = '${expense.head} > ${expense.subHead ?? '-'}';
      subHeadTotals[key] = (subHeadTotals[key] ?? 0.0) + expense.amount;
    }

    // Sort by amount descending (bigger to smaller, same order for bar and legend)
    final sortedEntries = subHeadTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) {
      return pw.Text(
        'No sub-head data',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, font: font),
      );
    }

    // Extended palette for many sub-heads (bigger to smaller, left to right)
    final palette = [
      PdfColors.blue700,
      PdfColors.green700,
      PdfColors.orange700,
      PdfColors.purple700,
      PdfColors.grey700,
      PdfColors.blue800,
      PdfColors.green800,
      PdfColors.orange800,
      PdfColors.red700,
      PdfColors.grey800,
      PdfColors.grey600,
      PdfColors.blue,
      PdfColors.green,
      PdfColors.orange,
      PdfColors.purple,
    ];

    const maxBarWidth = 375.0;
    const barHeight = 24.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: maxBarWidth,
          height: barHeight,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            children: sortedEntries.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              final amount = entry.value;
              final percentage = (amount / totalAmount) * 100;
              final isLast = index == sortedEntries.length - 1;
              final width = isLast
                  ? maxBarWidth - (sortedEntries.take(index).fold<double>(0.0, (sum, e) {
                      final pct = (e.value / totalAmount) * 100;
                      return sum + (maxBarWidth * pct / 100);
                    }))
                  : (maxBarWidth * percentage / 100);
              final color = palette[index % palette.length];

              return pw.Container(
                width: width,
                height: barHeight,
                decoration: pw.BoxDecoration(
                  color: color,
                  border: !isLast
                      ? pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                        )
                      : null,
                ),
                child: percentage > 5 && width > 40
                    ? pw.Center(
                        child: pw.Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            font: boldFont,
                          ),
                        ),
                      )
                    : pw.SizedBox(),
              );
            }).toList(),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 16,
          runSpacing: 8,
          children: sortedEntries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final label = entry.key;
            final amount = entry.value;
            final percentage = (amount / totalAmount) * 100;
            final color = palette[index % palette.length];
            return pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  width: 12,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    color: color,
                    shape: pw.BoxShape.rectangle,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  '$label: ₹ ${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey900,
                    font: font,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
