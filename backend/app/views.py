import os
import random
import logging
from datetime import datetime
from decimal import Decimal

from django.conf import settings
from django.contrib.auth.hashers import make_password
from django.db import transaction
from django.http import FileResponse, HttpResponse
from django.shortcuts import render
from django.utils import timezone

from rest_framework import viewsets, status
from rest_framework.generics import RetrieveUpdateDestroyAPIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from openpyxl import load_workbook

from .models import *
from .serializers import *

logger = logging.getLogger(__name__)



# Create your views here.
class UserRegisterView(APIView):
    permission_classes = [AllowAny]  
    
    def post(self, request):
        try:
            serializer = UserRegisterSerializer(data=request.data)
            if serializer.is_valid():
                user = serializer.save()
                return Response({
                    "status": "success",
                    "response_code": status.HTTP_201_CREATED,
                    "message": "User registered successfully",
                    "user": {
                        "id": user.id,
                        "username": user.username,
                        "email": user.email,
                        "role": user.role,
                        "created_by": user.created_by.id if user.created_by else None
                    }
                })
            return Response({
                "status": "failed",
                "response_code": status.HTTP_400_BAD_REQUEST,
                "message": serializer.errors
            })
        except Exception as e:
            message = str(e)
            return Response({
                "status": "failed",
                "response_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
                "message": message
            })
 

class LoginView(APIView):
    permission_classes = [AllowAny] 
    
    def post(self, request):
        try:
            serializer = LoginSerializer(data=request.data)
            if serializer.is_valid():
                return Response({"status":"success","response_code":status.HTTP_200_OK,"message":"User logged in successfully","tokens":serializer.validated_data})
            return Response({"status":"failed","response_code":status.HTTP_404_NOT_FOUND,"message":serializer.errors})
        except Exception as e:
            message = str(e)
            return Response({"status":"failed","response_code":status.HTTP_500_INTERNAL_SERVER_ERROR,"message":message})
        

class RefreshTokenView(APIView):
    permission_classes = [AllowAny] 

    def post(self, request):
        try:
            serializer = RefreshTokenSerializer(data=request.data)
            if serializer.is_valid():
                return Response(serializer.validated_data)
            return Response({"status":"failed","response_code":status.HTTP_404_NOT_FOUND,"message":serializer.errors})
        except Exception as e:
            message = str(e)
            return Response({"status":"failed","response_code":status.HTTP_500_INTERNAL_SERVER_ERROR,"message":message})


class ProfileView(viewsets.ModelViewSet):
    # permission_classes = [IsAuthenticated]
    queryset = UserRegister.objects.all()
    serializer_class = ProfileSerializer





class CompanyViewSet(viewsets.ModelViewSet):
    queryset = Company.objects.all().order_by("-created_at")
    serializer_class = CompanySerializer
    permission_classes = [IsAuthenticated]


class FinancialPeriodViewSet(viewsets.ModelViewSet):
    queryset = FinancialPeriod.objects.all().order_by("-created_at")
    serializer_class = FinancialPeriodSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = FinancialPeriod.objects.all()
        company_id = self.request.query_params.get('company', None)
        if company_id:
            queryset = queryset.filter(company_id=company_id)
        return queryset.order_by("-created_at")


class TradingAccountViewSet(viewsets.ModelViewSet):
    queryset = TradingAccount.objects.all()
    serializer_class = TradingAccountSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = TradingAccount.objects.all()
        period_id = self.request.query_params.get('period', None)
        if period_id:
            queryset = queryset.filter(period_id=period_id)
        return queryset


class ProfitAndLossViewSet(viewsets.ModelViewSet):
    queryset = ProfitAndLoss.objects.all()
    serializer_class = ProfitAndLossSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = ProfitAndLoss.objects.all()
        period_id = self.request.query_params.get('period', None)
        if period_id:
            queryset = queryset.filter(period_id=period_id)
        return queryset


class BalanceSheetViewSet(viewsets.ModelViewSet):
    queryset = BalanceSheet.objects.all()
    serializer_class = BalanceSheetSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = BalanceSheet.objects.all()
        period_id = self.request.query_params.get('period', None)
        if period_id:
            queryset = queryset.filter(period_id=period_id)
        return queryset


class OperationalMetricsViewSet(viewsets.ModelViewSet):
    queryset = OperationalMetrics.objects.all()
    serializer_class = OperationalMetricsSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = OperationalMetrics.objects.all()
        period_id = self.request.query_params.get('period', None)
        if period_id:
            queryset = queryset.filter(period_id=period_id)
        return queryset


class RatioResultViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = RatioResult.objects.all()
    serializer_class = RatioResultSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = RatioResult.objects.all()
        period_id = self.request.query_params.get('period', None)
        if period_id:
            queryset = queryset.filter(period_id=period_id)
        return queryset


class StatementColumnConfigViewSet(viewsets.ModelViewSet):
    """
    Manage display names / order for financial statement columns.
    Supports global configs (company null) and company-specific overrides.
    """
    queryset = StatementColumnConfig.objects.all()
    serializer_class = StatementColumnConfigSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = StatementColumnConfig.objects.all()
        company_id = self.request.query_params.get("company")
        statement_type = self.request.query_params.get("statement_type")
        if company_id == "global":
            qs = qs.filter(company__isnull=True)
        elif company_id:
            qs = qs.filter(company_id=company_id)
        # if no company param: return all (caller can filter client-side)
        if statement_type:
            qs = qs.filter(statement_type=statement_type)
        return qs.order_by("canonical_field")


class CalculateRatiosView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, period_id=None):
        """
        Calculate ratios for a given period
        POST /api/periods/<period_id>/calculate-ratios/
        """
        try:
            if period_id is None:
                period_id = request.data.get('period_id')
            
            if not period_id:
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": "period_id is required"
                })
            
            period = FinancialPeriod.objects.get(id=period_id)
            
            # Validate all required data exists
            if not hasattr(period, 'trading_account'):
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": "TradingAccount not found for this period"
                })
            if not hasattr(period, 'profit_loss'):
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": "ProfitAndLoss not found for this period"
                })
            if not hasattr(period, 'balance_sheet'):
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": "BalanceSheet not found for this period"
                })
            if not hasattr(period, 'operational_metrics'):
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": "OperationalMetrics not found for this period"
                })
            
            # Calculate ratios
            from app.services.ratio_calculator import RatioCalculator
            from decimal import Decimal
            
            calculator = RatioCalculator(period)
            all_ratios = calculator.calculate_all_ratios()
            traffic_light_statuses = calculator.get_traffic_light_statuses()
            
            # Create or update RatioResult
            ratio_result, created = RatioResult.objects.get_or_create(
                period=period,
                defaults={
                    'working_fund': Decimal(str(all_ratios['working_fund'])),
                    'stock_turnover': Decimal(str(all_ratios.get('stock_turnover', 0))),
                    'gross_profit_ratio': Decimal(str(all_ratios.get('gross_profit_ratio', 0))),
                    'net_profit_ratio': Decimal(str(all_ratios.get('net_profit_ratio', 0))),
                    'own_fund_to_wf': Decimal(str(all_ratios.get('own_fund_to_wf', 0))),
                    'deposits_to_wf': Decimal(str(all_ratios.get('deposits_to_wf', 0))),
                    'borrowings_to_wf': Decimal(str(all_ratios.get('borrowings_to_wf', 0))),
                    'loans_to_wf': Decimal(str(all_ratios.get('loans_to_wf', 0))),
                    'investments_to_wf': Decimal(str(all_ratios.get('investments_to_wf', 0))),
                    'cost_of_deposits': Decimal(str(all_ratios.get('cost_of_deposits', 0))),
                    'yield_on_loans': Decimal(str(all_ratios.get('yield_on_loans', 0))),
                    'yield_on_investments': Decimal(str(all_ratios.get('yield_on_investments', 0))),
                    'credit_deposit_ratio': Decimal(str(all_ratios.get('credit_deposit_ratio', 0))),
                    'avg_cost_of_wf': Decimal(str(all_ratios.get('avg_cost_of_wf', 0))),
                    'avg_yield_on_wf': Decimal(str(all_ratios.get('avg_yield_on_wf', 0))),
                    'gross_fin_margin': Decimal(str(all_ratios.get('gross_fin_margin', 0))),
                    'operating_cost_to_wf': Decimal(str(all_ratios.get('operating_cost_to_wf', 0))),
                    'net_fin_margin': Decimal(str(all_ratios.get('net_fin_margin', 0))),
                    'risk_cost_to_wf': Decimal(str(all_ratios.get('risk_cost_to_wf', 0))),
                    'net_margin': Decimal(str(all_ratios.get('net_margin', 0))),
                    'all_ratios': all_ratios,
                    'traffic_light_status': traffic_light_statuses
                }
            )
            
            if not created:
                # Update existing
                ratio_result.working_fund = Decimal(str(all_ratios['working_fund']))
                ratio_result.stock_turnover = Decimal(str(all_ratios.get('stock_turnover', 0)))
                ratio_result.gross_profit_ratio = Decimal(str(all_ratios.get('gross_profit_ratio', 0)))
                ratio_result.net_profit_ratio = Decimal(str(all_ratios.get('net_profit_ratio', 0)))
                ratio_result.own_fund_to_wf = Decimal(str(all_ratios.get('own_fund_to_wf', 0)))
                ratio_result.deposits_to_wf = Decimal(str(all_ratios.get('deposits_to_wf', 0)))
                ratio_result.borrowings_to_wf = Decimal(str(all_ratios.get('borrowings_to_wf', 0)))
                ratio_result.loans_to_wf = Decimal(str(all_ratios.get('loans_to_wf', 0)))
                ratio_result.investments_to_wf = Decimal(str(all_ratios.get('investments_to_wf', 0)))
                ratio_result.cost_of_deposits = Decimal(str(all_ratios.get('cost_of_deposits', 0)))
                ratio_result.yield_on_loans = Decimal(str(all_ratios.get('yield_on_loans', 0)))
                ratio_result.yield_on_investments = Decimal(str(all_ratios.get('yield_on_investments', 0)))
                ratio_result.credit_deposit_ratio = Decimal(str(all_ratios.get('credit_deposit_ratio', 0)))
                ratio_result.avg_cost_of_wf = Decimal(str(all_ratios.get('avg_cost_of_wf', 0)))
                ratio_result.avg_yield_on_wf = Decimal(str(all_ratios.get('avg_yield_on_wf', 0)))
                ratio_result.gross_fin_margin = Decimal(str(all_ratios.get('gross_fin_margin', 0)))
                ratio_result.operating_cost_to_wf = Decimal(str(all_ratios.get('operating_cost_to_wf', 0)))
                ratio_result.net_fin_margin = Decimal(str(all_ratios.get('net_fin_margin', 0)))
                ratio_result.risk_cost_to_wf = Decimal(str(all_ratios.get('risk_cost_to_wf', 0)))
                ratio_result.net_margin = Decimal(str(all_ratios.get('net_margin', 0)))
                ratio_result.all_ratios = all_ratios
                ratio_result.traffic_light_status = traffic_light_statuses
                ratio_result.save()
            
            serializer = RatioResultSerializer(ratio_result)
            return Response({
                "status": "success",
                "response_code": status.HTTP_200_OK,
                "message": "Ratios calculated successfully",
                "data": serializer.data
            })
            
        except FinancialPeriod.DoesNotExist:
            return Response({
                "status": "failed",
                "response_code": status.HTTP_404_NOT_FOUND,
                "message": "FinancialPeriod not found"
            })
        except Exception as e:
            return Response({
                "status": "failed",
                "response_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
                "message": str(e)
            })


class UploadExcelView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        """
        Upload Excel file and parse all 4 sheets
        POST /api/upload-excel/
        """
        logger.info("=== UploadExcelView POST request received ===")
        try:
            if 'file' not in request.FILES:
                logger.warning("DEBUG: No file provided")
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": "No file provided"
                })
            
            company_id = request.data.get('company_id')
            if not company_id:
                logger.warning("DEBUG: company_id is required")
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": "company_id is required"
                })
            
            try:
                company = Company.objects.get(id=company_id)
                logger.info(f"DEBUG: Found company - {company.name}")
            except Company.DoesNotExist:
                logger.warning(f"DEBUG: Company not found - ID: {company_id}")
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_404_NOT_FOUND,
                    "message": "Company not found"
                })
            
            excel_file = request.FILES['file']
            logger.info(f"DEBUG: Excel file received - {excel_file.name}")
            
            # Extract period information from filename if available
            filename = excel_file.name
            period_info = self._extract_period_from_filename(filename)
            
            # Load workbook
            logger.info("DEBUG: Loading workbook...")
            workbook = load_workbook(excel_file, data_only=True)
            logger.info(f"DEBUG: Workbook loaded, sheets: {workbook.sheetnames}")
            
            # Find required sheets – support both formats
            sheet_mapping = self._find_sheets(workbook)
            logger.info(f"DEBUG: Found sheets in mapping: {list(sheet_mapping.keys())}")
            available = workbook.sheetnames

            # Format A: Financial_Statement, Balance_Sheet_Liabilities, Balance_Sheet_Assets, Profit_Loss, Trading_Account
            format_a = all(k in sheet_mapping for k in ['Financial_Statement', 'Balance_Sheet_Liabilities', 'Balance_Sheet_Assets', 'Profit_Loss', 'Trading_Account'])

            # Format B: Balance Sheet, Profit and Loss, Trading Account, Operational Metrics
            format_b = all(k in sheet_mapping for k in ['Balance Sheet', 'Profit and Loss', 'Trading Account', 'Operational Metrics'])
            
            logger.info(f"DEBUG: Format A detected: {format_a}, Format B detected: {format_b}")

            if format_a:
                logger.info("DEBUG: Parsing Format A sheets...")
                financial_statement_data = self._parse_financial_statement_sheet(workbook[sheet_mapping['Financial_Statement']])
                liabilities_data = self._parse_balance_sheet_liabilities(workbook[sheet_mapping['Balance_Sheet_Liabilities']])
                assets_data = self._parse_balance_sheet_assets(workbook[sheet_mapping['Balance_Sheet_Assets']])
                balance_sheet_data = self._default_balance_sheet({**liabilities_data, **assets_data})
                profit_loss_data = self._default_profit_loss(self._parse_profit_loss_rows(workbook[sheet_mapping['Profit_Loss']]))
                trading_account_data = self._default_trading_account(self._parse_trading_account_rows(workbook[sheet_mapping['Trading_Account']]))
                staff_count = financial_statement_data.get('staff_count')
                if staff_count is not None:
                    operational_metrics_data = {'staff_count': int(float(staff_count))}
                else:
                    operational_metrics_data = {'staff_count': 1}
                fiscal_end = financial_statement_data.get('fiscal_year_end')
                if fiscal_end and not period_info.get('label'):
                    period_info['label'] = fiscal_end
                    period_info['end_date'] = fiscal_end
            elif format_b:
                logger.info("DEBUG: Parsing Format B sheets...")
                balance_sheet_data = self._parse_balance_sheet(workbook[sheet_mapping['Balance Sheet']])
                profit_loss_data = self._parse_profit_loss(workbook[sheet_mapping['Profit and Loss']])
                trading_account_data = self._parse_trading_account(workbook[sheet_mapping['Trading Account']])
                operational_metrics_data = self._parse_operational_metrics(workbook[sheet_mapping['Operational Metrics']])
                logger.info("DEBUG: Format B sheets parsed successfully")
            elif len(available) == 1 and available[0] == 'Sheet':
                # Format C: Single generic "Sheet" - try to auto-detect and parse as balance sheet
                logger.info("DEBUG: Detecting single generic 'Sheet'... attempting to auto-parse as balance sheet")
                single_sheet = workbook[available[0]]
                
                # Try to detect if it's balance sheet data by checking headers
                first_row = [str(cell.value).strip().lower() if cell.value else '' for cell in next(single_sheet.iter_rows(values_only=False))]
                has_liabilities = any('liabilit' in h for h in first_row)
                has_assets = any('asset' in h for h in first_row)
                
                if has_liabilities and has_assets:
                    logger.info("DEBUG: Detected balance sheet format - parsing as Format B (single sheet)")
                    balance_sheet_data = self._parse_balance_sheet(single_sheet)
                    # Set default/empty data for other required sheets
                    profit_loss_data = self._default_profit_loss({})
                    trading_account_data = self._default_trading_account({})
                    operational_metrics_data = {'staff_count': 1}
                else:
                    logger.error(f"DEBUG: Could not auto-detect sheet type. First row: {first_row}")
                    return Response({
                        "status": "failed",
                        "response_code": status.HTTP_400_BAD_REQUEST,
                        "message": f"Could not parse single sheet format. Please use properly named sheets or ensure balance sheet has 'Liabilities' and 'Assets' headers."
                    })
            else:
                logger.error(f"DEBUG: Unsupported sheet set. Available sheets: {', '.join(available)}")
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": f"Unsupported sheet set. Use either: (1) Financial_Statement, Balance_Sheet_Liabilities, Balance_Sheet_Assets, Profit_Loss, Trading_Account OR (2) Balance Sheet, Profit and Loss, Trading Account, Operational Metrics. Available: {', '.join(available)}"
                })

            # Create Financial Period (filename e.g. April_2025, or fiscal year from Financial_Statement)
            period_label = request.data.get('period_label') or period_info.get('label') or f"FY-{datetime.now().year}-{datetime.now().year + 1}"
            start_date = request.data.get('start_date') or period_info.get('start_date') or f"{datetime.now().year}-04-01"
            end_date = request.data.get('end_date') or period_info.get('end_date') or f"{datetime.now().year + 1}-03-31"
            period_type = request.data.get('period_type') or period_info.get('period_type') or ('MONTHLY' if period_info else 'YEARLY')
            
            logger.info(f"DEBUG: Creating/updating period - Company: {company.name}, Label: {period_label}")
            
            # Use transaction to ensure all data is saved together
            with transaction.atomic():
                period, created = FinancialPeriod.objects.get_or_create(
                    company=company,
                    label=period_label,
                    defaults={
                        'period_type': period_type,
                        'start_date': start_date,
                        'end_date': end_date,
                        'is_finalized': False,
                        'excel_file': excel_file,
                    }
                )
                
                logger.info(f"DEBUG: Period {'created' if created else 'updated'} - ID: {period.id}")
                
                # If updating existing period, save the new excel file
                if not created:
                    period.excel_file = excel_file
                    period.save()
                    logger.info(f"DEBUG: Updated excel_file for period {period.id}")
                
                logger.info(f"DEBUG: Saving trading account data")
                TradingAccount.objects.update_or_create(
                    period=period,
                    defaults=trading_account_data
                )
                
                logger.info(f"DEBUG: Saving profit & loss data")
                # Create/Update Profit & Loss
                ProfitAndLoss.objects.update_or_create(
                    period=period,
                    defaults=profit_loss_data
                )
                
                logger.info(f"DEBUG: Saving balance sheet data")
                # Create/Update Balance Sheet
                BalanceSheet.objects.update_or_create(
                    period=period,
                    defaults=balance_sheet_data
                )
                
                logger.info(f"DEBUG: Saving operational metrics data")
                # Create/Update Operational Metrics
                OperationalMetrics.objects.update_or_create(
                    period=period,
                    defaults=operational_metrics_data
                )
                
                logger.info(f"DEBUG: Calculating ratios")
                # Automatically calculate ratios
                from app.services.ratio_calculator import RatioCalculator
                calculator = RatioCalculator(period)
                all_ratios = calculator.calculate_all_ratios()
                traffic_light_statuses = calculator.get_traffic_light_statuses()
                
                logger.info(f"DEBUG: Saving ratio results")
                # Create or update RatioResult
                RatioResult.objects.update_or_create(
                    period=period,
                    defaults={
                        'working_fund': Decimal(str(all_ratios['working_fund'])),
                        'stock_turnover': Decimal(str(all_ratios.get('stock_turnover', 0))),
                        'gross_profit_ratio': Decimal(str(all_ratios.get('gross_profit_ratio', 0))),
                        'net_profit_ratio': Decimal(str(all_ratios.get('net_profit_ratio', 0))),
                        'own_fund_to_wf': Decimal(str(all_ratios.get('own_fund_to_wf', 0))),
                        'deposits_to_wf': Decimal(str(all_ratios.get('deposits_to_wf', 0))),
                        'borrowings_to_wf': Decimal(str(all_ratios.get('borrowings_to_wf', 0))),
                        'loans_to_wf': Decimal(str(all_ratios.get('loans_to_wf', 0))),
                        'investments_to_wf': Decimal(str(all_ratios.get('investments_to_wf', 0))),
                        'cost_of_deposits': Decimal(str(all_ratios.get('cost_of_deposits', 0))),
                        'yield_on_loans': Decimal(str(all_ratios.get('yield_on_loans', 0))),
                        'yield_on_investments': Decimal(str(all_ratios.get('yield_on_investments', 0))),
                        'credit_deposit_ratio': Decimal(str(all_ratios.get('credit_deposit_ratio', 0))),
                        'avg_cost_of_wf': Decimal(str(all_ratios.get('avg_cost_of_wf', 0))),
                        'avg_yield_on_wf': Decimal(str(all_ratios.get('avg_yield_on_wf', 0))),
                        'gross_fin_margin': Decimal(str(all_ratios.get('gross_fin_margin', 0))),
                        'operating_cost_to_wf': Decimal(str(all_ratios.get('operating_cost_to_wf', 0))),
                        'net_fin_margin': Decimal(str(all_ratios.get('net_fin_margin', 0))),
                        'risk_cost_to_wf': Decimal(str(all_ratios.get('risk_cost_to_wf', 0))),
                        'net_margin': Decimal(str(all_ratios.get('net_margin', 0))),
                        'all_ratios': all_ratios,
                        'traffic_light_status': traffic_light_statuses
                    }
                )
                
                logger.info(f"DEBUG: All data saved successfully for period {period.id}")
            
            logger.info(f"DEBUG: Returning success response")
            return Response({
                "status": "success",
                "response_code": status.HTTP_200_OK,
                "message": "Excel file processed successfully",
                "period_id": period.id,
                "period_label": period.label
            })
            
            
        except Exception as e:
            logger.exception(f"=== EXCEPTION in UploadExcelView: {str(e)} ===")
            import traceback
            traceback.print_exc()
            return Response({
                "status": "failed",
                "response_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
                "message": f"Error processing Excel file: {str(e)}"
            })
    
    def _parse_balance_sheet(self, sheet):
        """Parse Balance Sheet sheet - handles both column format (Liabilities/Amount, Assets/Amount) and row format"""
        data = {}
        
        # Try to detect format by checking first row
        first_row = [str(cell).strip().lower() if cell else '' for cell in next(sheet.iter_rows(values_only=True))]
        
        # Check if it's column format (Liabilities/Amount/Assets/Amount)
        if 'liabilities' in ' '.join(first_row) or 'amount' in ' '.join(first_row):
            # Column format: Liabilities | Amount | Assets | Amount
            liabilities_col = None
            liabilities_amount_col = None
            assets_col = None
            assets_amount_col = None
            
            for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
                if row_idx == 1:
                    # Find column indices
                    for col_idx, cell_value in enumerate(row):
                        if cell_value:
                            header = str(cell_value).strip().lower()
                            if 'liabilities' in header:
                                liabilities_col = col_idx
                            elif 'assets' in header and liabilities_col is not None:
                                assets_col = col_idx
                            elif 'amount' in header:
                                if liabilities_amount_col is None:
                                    liabilities_amount_col = col_idx
                                else:
                                    assets_amount_col = col_idx
                elif row_idx > 1:
                    # Parse data rows
                    if liabilities_col is not None and liabilities_amount_col is not None:
                        item = row[liabilities_col] if liabilities_col < len(row) else None
                        amount = row[liabilities_amount_col] if liabilities_amount_col < len(row) else None
                        if item and amount is not None:
                            field_name = self._map_balance_sheet_field(str(item))
                            if field_name:
                                data[field_name] = self._parse_decimal(amount)
                    
                    if assets_col is not None and assets_amount_col is not None:
                        item = row[assets_col] if assets_col < len(row) else None
                        amount = row[assets_amount_col] if assets_amount_col < len(row) else None
                        if item and amount is not None:
                            field_name = self._map_balance_sheet_field(str(item))
                            if field_name:
                                data[field_name] = self._parse_decimal(amount)
        else:
            # Row format: Headers in first row, data in second row
            headers = {}
            data_row = None
            
            for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
                if row_idx == 1:
                    for col_idx, cell_value in enumerate(row):
                        if cell_value:
                            header = str(cell_value).strip().lower()
                            headers[header] = col_idx
                elif row_idx == 2:
                    data_row = row
                    break
            
            if data_row and headers:
                for header, col_idx in headers.items():
                    field_name = self._map_balance_sheet_field(header)
                    if field_name and col_idx < len(data_row):
                        value = data_row[col_idx]
                        if value is not None:
                            data[field_name] = self._parse_decimal(value)
        
        return data
    
    def _map_balance_sheet_field(self, item_str):
        """Map balance sheet item string to model field name"""
        item_lower = item_str.lower().strip()
        
        field_mapping = {
            'share capital': 'share_capital',
            'share cap': 'share_capital',
            'deposits': 'deposits',
            'borrowings': 'borrowings',
            'borrowing': 'borrowings',
            'reserves': 'reserves_statutory_free',
            'reserves (': 'reserves_statutory_free',
            'statutory & free reserves': 'reserves_statutory_free',
            'undistributed profit': 'undistributed_profit',
            'undistribu': 'undistributed_profit',
            'udp': 'undistributed_profit',
            'provisions': 'provisions',
            'other liabilities': 'other_liabilities',
            'other liab': 'other_liabilities',
            'cash in hand': 'cash_in_hand',
            'cash in ha': 'cash_in_hand',
            'cash at bank': 'cash_at_bank',
            'cash at ba': 'cash_at_bank',
            'investments': 'investments',
            'investmer': 'investments',
            'loans & advances': 'loans_advances',
            'loans & a': 'loans_advances',
            'loans and advances': 'loans_advances',
            'fixed assets': 'fixed_assets',
            'fixed asse': 'fixed_assets',
            'other assets': 'other_assets',
            'other ass': 'other_assets',
            'stock in trade': 'stock_in_trade',
            'stock in tr': 'stock_in_trade',
        }
        
        for key, field_name in field_mapping.items():
            if key in item_lower:
                return field_name
        return None
    
    def _parse_profit_loss(self, sheet):
        """Parse Profit and Loss sheet - handles Expenses/Amount and Income/Amount column format"""
        data = {}
        
        # Check format - column format (Expenses/Amount, Income/Amount) or row format
        first_row = [str(cell).strip().lower() if cell else '' for cell in next(sheet.iter_rows(values_only=True))]
        
        if 'expenses' in ' '.join(first_row) or 'income' in ' '.join(first_row):
            # Column format: Expenses | Amount | Income | Amount
            expenses_col = None
            expenses_amount_col = None
            income_col = None
            income_amount_col = None
            
            for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
                if row_idx == 1:
                    for col_idx, cell_value in enumerate(row):
                        if cell_value:
                            header = str(cell_value).strip().lower()
                            if 'expenses' in header:
                                expenses_col = col_idx
                            elif 'income' in header:
                                income_col = col_idx
                            elif 'amount' in header:
                                if expenses_amount_col is None:
                                    expenses_amount_col = col_idx
                                else:
                                    income_amount_col = col_idx
                elif row_idx > 1:
                    # Parse expenses
                    if expenses_col is not None and expenses_amount_col is not None:
                        item = row[expenses_col] if expenses_col < len(row) else None
                        amount = row[expenses_amount_col] if expenses_amount_col < len(row) else None
                        if item and amount is not None:
                            field_name = self._map_profit_loss_field(str(item), is_income=False)
                            if field_name:
                                data[field_name] = self._parse_decimal(amount)
                    
                    # Parse income
                    if income_col is not None and income_amount_col is not None:
                        item = row[income_col] if income_col < len(row) else None
                        amount = row[income_amount_col] if income_amount_col < len(row) else None
                        if item and amount is not None:
                            field_name = self._map_profit_loss_field(str(item), is_income=True)
                            if field_name:
                                data[field_name] = self._parse_decimal(amount)
        else:
            # Row format: Headers in first row, income in row 2, expenses in row 3
            headers = {}
            income_row = None
            expense_row = None
            
            for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
                if row_idx == 1:
                    for col_idx, cell_value in enumerate(row):
                        if cell_value:
                            header = str(cell_value).strip().lower()
                            headers[header] = col_idx
                elif row_idx == 2:
                    income_row = row
                elif row_idx == 3:
                    expense_row = row
                    break
            
            if headers:
                # Parse income
                if income_row:
                    for header, col_idx in headers.items():
                        field_name = self._map_profit_loss_field(header, is_income=True)
                        if field_name and col_idx < len(income_row):
                            value = income_row[col_idx]
                            if value is not None:
                                data[field_name] = self._parse_decimal(value)
                
                # Parse expenses
                if expense_row:
                    for header, col_idx in headers.items():
                        field_name = self._map_profit_loss_field(header, is_income=False)
                        if field_name and col_idx < len(expense_row):
                            value = expense_row[col_idx]
                            if value is not None:
                                data[field_name] = self._parse_decimal(value)
        
        return data
    
    def _map_profit_loss_field(self, item_str, is_income=False):
        """Map profit & loss item string to model field name"""
        item_lower = item_str.lower().strip()
        
        if is_income:
            field_mapping = {
                'interest on loans': 'interest_on_loans',
                'interest rec. on loans': 'interest_on_loans',
                'interest received on loans': 'interest_on_loans',
                'interest rec': 'interest_on_loans',
                'interest on bank a/c': 'interest_on_bank_ac',
                'interest on bank ac': 'interest_on_bank_ac',
                'interest of': 'interest_on_bank_ac',
                'return on investment': 'return_on_investment',
                'return on': 'return_on_investment',
                'miscellaneous income': 'miscellaneous_income',
                'miscellane': 'miscellaneous_income',
            }
        else:
            field_mapping = {
                'interest on deposits': 'interest_on_deposits',
                'interest οι': 'interest_on_deposits',
                'interest on borrowings': 'interest_on_borrowings',
                'establishment & contingencies': 'establishment_contingencies',
                'establishment': 'establishment_contingencies',
                'establishm': 'establishment_contingencies',
                'provisions': 'provisions',
                'provisions (risk cost)': 'provisions',
                'net profit': 'net_profit',
            }
        
        for key, field_name in field_mapping.items():
            if key in item_lower:
                return field_name
        return None
    
    def _parse_trading_account(self, sheet):
        """Parse Trading Account sheet"""
        data = {}
        
        # Look for Item and Amount columns
        headers = {}
        item_col = None
        amount_col = None
        
        for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
            if row_idx == 1:
                for col_idx, cell_value in enumerate(row):
                    if cell_value:
                        header = str(cell_value).strip().lower()
                        if 'item' in header:
                            item_col = col_idx
                        elif 'amount' in header:
                            amount_col = col_idx
            elif row_idx > 1 and item_col is not None and amount_col is not None:
                item = row[item_col] if item_col < len(row) else None
                amount = row[amount_col] if amount_col < len(row) else None
                
                if item and amount is not None:
                    item_str = str(item).strip().lower()
                    
                    if 'opening' in item_str and 'stock' in item_str:
                        data['opening_stock'] = self._parse_decimal(amount)
                    elif 'purchases' in item_str:
                        data['purchases'] = self._parse_decimal(amount)
                    elif 'trade' in item_str and 'charges' in item_str:
                        data['trade_charges'] = self._parse_decimal(amount)
                    elif 'sales' in item_str:
                        data['sales'] = self._parse_decimal(amount)
                    elif 'closing' in item_str and 'stock' in item_str:
                        data['closing_stock'] = self._parse_decimal(amount)
        
        return data
    
    def _parse_operational_metrics(self, sheet):
        """Parse Operational Metrics sheet"""
        data = {}
        
        # Look for Metric and Value columns
        metric_col = None
        value_col = None
        
        for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
            if row_idx == 1:
                for col_idx, cell_value in enumerate(row):
                    if cell_value:
                        header = str(cell_value).strip().lower()
                        if 'metric' in header:
                            metric_col = col_idx
                        elif 'value' in header:
                            value_col = col_idx
            elif row_idx > 1 and metric_col is not None and value_col is not None:
                metric = row[metric_col] if metric_col < len(row) else None
                value = row[value_col] if value_col < len(row) else None
                
                if metric and value is not None:
                    metric_str = str(metric).strip().lower()
                    
                    if 'staff' in metric_str and 'count' in metric_str:
                        data['staff_count'] = int(float(value))
        
        return data
    
    def _parse_financial_statement_sheet(self, sheet):
        """Parse Financial_Statement sheet: Entity Name, Fiscal Year End, Currency, Staff Count"""
        data = {}
        col_map = {}  # header -> col index
        for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
            if row_idx == 1:
                for col_idx, cell_value in enumerate(row):
                    if cell_value:
                        header = str(cell_value).strip().lower().replace(' ', '_')
                        col_map[header] = col_idx
            else:
                if not col_map:
                    break
                for header, col_idx in col_map.items():
                    if col_idx >= len(row):
                        continue
                    val = row[col_idx]
                    if val is None:
                        continue
                    if 'entity' in header and 'name' in header:
                        data['entity_name'] = str(val).strip()
                    elif 'fiscal' in header and 'year' in header:
                        data['fiscal_year_end'] = str(val).strip()
                    elif 'currency' in header:
                        data['currency'] = str(val).strip()
                    elif 'staff' in header and 'count' in header:
                        try:
                            data['staff_count'] = int(float(val))
                        except (TypeError, ValueError):
                            pass
                break
        return data
    
    def _parse_balance_sheet_liabilities(self, sheet):
        """Parse Balance_Sheet_Liabilities: Liability Type, Amount (one row per liability)"""
        data = {}
        type_col = amount_col = None
        # Order matters: more specific phrases first
        liability_to_field = [
            ('reserves (statutory + free)', 'reserves_statutory_free'),
            ('reserves (statutory', 'reserves_statutory_free'),
            ('share capital', 'share_capital'),
            ('deposits', 'deposits'),
            ('borrowings', 'borrowings'),
            ('reserves', 'reserves_statutory_free'),
            ('statutory', 'reserves_statutory_free'),
            ('provisions', 'provisions'),
            ('other liabilities', 'other_liabilities'),
            ('undistributed profit', 'undistributed_profit'),
            ('udp', 'undistributed_profit'),
        ]
        for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
            if row_idx == 1:
                for col_idx, cell_value in enumerate(row):
                    if cell_value:
                        h = str(cell_value).strip().lower()
                        if 'liability' in h or 'type' in h:
                            type_col = col_idx
                        elif 'amount' in h:
                            amount_col = col_idx
            elif row_idx > 1 and type_col is not None and amount_col is not None:
                typ = row[type_col] if type_col < len(row) else None
                amt = row[amount_col] if amount_col < len(row) else None
                if typ is not None and amt is not None:
                    t = str(typ).strip().lower()
                    for key, field in liability_to_field:
                        if key in t or t in key:
                            data[field] = self._parse_decimal(amt)
                            break
        return data
    
    def _parse_balance_sheet_assets(self, sheet):
        """Parse Balance_Sheet_Assets: Asset Type, Amount (one row per asset)"""
        data = {}
        type_col = amount_col = None
        asset_to_field = {
            'cash in hand': 'cash_in_hand',
            'cash at bank': 'cash_at_bank',
            'investments': 'investments',
            'loans & advances': 'loans_advances',
            'loans and advances': 'loans_advances',
            'fixed assets': 'fixed_assets',
            'other assets': 'other_assets',
            'stock in trade': 'stock_in_trade',
        }
        for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
            if row_idx == 1:
                for col_idx, cell_value in enumerate(row):
                    if cell_value:
                        h = str(cell_value).strip().lower()
                        if 'asset' in h or 'type' in h:
                            type_col = col_idx
                        elif 'amount' in h:
                            amount_col = col_idx
            elif row_idx > 1 and type_col is not None and amount_col is not None:
                typ = row[type_col] if type_col < len(row) else None
                amt = row[amount_col] if amount_col < len(row) else None
                if typ is not None and amt is not None:
                    t = str(typ).strip().lower()
                    for key, field in asset_to_field.items():
                        if key in t or t in key:
                            data[field] = self._parse_decimal(amt)
                            break
        return data
    
    def _parse_profit_loss_rows(self, sheet):
        """Parse Profit_Loss sheet: Category, Item, Amount (Income/Expense/Net Profit rows)"""
        data = {}
        cat_col = item_col = amount_col = None
        for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
            if row_idx == 1:
                for col_idx, cell_value in enumerate(row):
                    if cell_value:
                        h = str(cell_value).strip().lower()
                        if 'category' in h:
                            cat_col = col_idx
                        elif 'item' in h:
                            item_col = col_idx
                        elif 'amount' in h:
                            amount_col = col_idx
            elif row_idx > 1 and item_col is not None and amount_col is not None:
                cat = str(row[cat_col] or '').strip().lower() if cat_col is not None and cat_col < len(row) else ''
                item = str(row[item_col] or '').strip().lower() if item_col < len(row) else ''
                amt = row[amount_col] if amount_col < len(row) else None
                if not item or amt is None:
                    continue
                amt_val = self._parse_decimal(amt)
                if 'income' in cat:
                    if 'interest' in item and 'loan' in item:
                        data['interest_on_loans'] = amt_val
                    elif 'interest' in item and 'bank' in item:
                        data['interest_on_bank_ac'] = amt_val
                    elif 'return' in item and 'investment' in item:
                        data['return_on_investment'] = amt_val
                    elif 'miscellaneous' in item:
                        data['miscellaneous_income'] = amt_val
                elif 'expense' in cat:
                    if 'interest' in item and 'deposit' in item:
                        data['interest_on_deposits'] = amt_val
                    elif 'interest' in item and 'borrowing' in item:
                        data['interest_on_borrowings'] = amt_val
                    elif 'establishment' in item or 'contingenc' in item:
                        data['establishment_contingencies'] = amt_val
                    elif 'provision' in item:
                        data['provisions'] = amt_val
                elif 'net profit' in cat or (cat == '' and 'net profit' in item):
                    data['net_profit'] = amt_val
        return data
    
    def _parse_trading_account_rows(self, sheet):
        """Parse Trading_Account sheet: Item, Amount (one row per item)"""
        data = {}
        item_col = amount_col = None
        for row_idx, row in enumerate(sheet.iter_rows(values_only=True), 1):
            if row_idx == 1:
                for col_idx, cell_value in enumerate(row):
                    if cell_value:
                        h = str(cell_value).strip().lower()
                        if 'item' in h:
                            item_col = col_idx
                        elif 'amount' in h:
                            amount_col = col_idx
            elif row_idx > 1 and item_col is not None and amount_col is not None:
                item = str(row[item_col] or '').strip().lower() if item_col < len(row) else ''
                amt = row[amount_col] if amount_col < len(row) else None
                if not item or amt is None:
                    continue
                amt_val = self._parse_decimal(amt)
                if 'opening' in item and 'stock' in item:
                    data['opening_stock'] = amt_val
                elif 'purchases' in item:
                    data['purchases'] = amt_val
                elif 'sales' in item:
                    data['sales'] = amt_val
                elif 'trade' in item and 'charges' in item:
                    data['trade_charges'] = amt_val
                elif 'closing' in item and 'stock' in item:
                    data['closing_stock'] = amt_val
        return data
    
    def _parse_decimal(self, value):
        """Parse value to Decimal"""
        if value is None:
            return Decimal('0')
        if isinstance(value, (int, float)):
            return Decimal(str(value))
        if isinstance(value, str):
            clean_value = value.replace(',', '').strip()
            try:
                return Decimal(clean_value)
            except:
                return Decimal('0')
        return Decimal('0')
    
    def _default_balance_sheet(self, data):
        """Ensure all BalanceSheet fields exist (default 0)."""
        keys = [
            'share_capital', 'deposits', 'borrowings', 'reserves_statutory_free', 'undistributed_profit',
            'provisions', 'other_liabilities', 'cash_in_hand', 'cash_at_bank', 'investments',
            'loans_advances', 'fixed_assets', 'other_assets', 'stock_in_trade'
        ]
        for k in keys:
            if k not in data:
                data[k] = Decimal('0')
        return data
    
    def _default_profit_loss(self, data):
        """Ensure all ProfitAndLoss fields exist (default 0)."""
        keys = [
            'interest_on_loans', 'interest_on_bank_ac', 'return_on_investment', 'miscellaneous_income',
            'interest_on_deposits', 'interest_on_borrowings', 'establishment_contingencies', 'provisions',
            'net_profit'
        ]
        for k in keys:
            if k not in data:
                data[k] = Decimal('0')
        return data
    
    def _default_trading_account(self, data):
        """Ensure all TradingAccount fields exist (default 0)."""
        keys = ['opening_stock', 'purchases', 'trade_charges', 'sales', 'closing_stock']
        for k in keys:
            if k not in data:
                data[k] = Decimal('0')
        return data
    
    def _find_sheets(self, workbook):
        """Find required sheets with flexible name matching. Supports two formats."""
        available_sheets = workbook.sheetnames
        sheet_mapping = {}
        
        # Format A: Financial_Statement, Balance_Sheet_Liabilities, Balance_Sheet_Assets, Profit_Loss, Trading_Account
        sheet_variations_a = {
            'Financial_Statement': ['financial_statement', 'financial statement'],
            'Balance_Sheet_Liabilities': ['balance_sheet_liabilities', 'balance sheet liabilities', 'liabilities'],
            'Balance_Sheet_Assets': ['balance_sheet_assets', 'balance sheet assets', 'assets'],
            'Profit_Loss': ['profit_loss', 'profit loss', 'profit_loss', 'profit & loss'],
            'Trading_Account': ['trading_account', 'trading account'],
        }
        # Format B: single Balance Sheet, P&L, Trading Account, Operational Metrics
        sheet_variations_b = {
            'Balance Sheet': ['balance sheet', 'balance_sheet', 'balancesheet', 'balance'],
            'Profit and Loss': ['profit and loss', 'profit & loss', 'profit_and_loss', 'profitandloss', 'p&l', 'pl'],
            'Trading Account': ['trading account', 'trading_account', 'tradingaccount', 'trading'],
            'Operational Metrics': ['operational metrics', 'operational_metrics', 'operationalmetrics', 'operational', 'metrics']
        }
        
        for required_name, variations in {**sheet_variations_a, **sheet_variations_b}.items():
            if required_name in sheet_mapping:
                continue
            for sheet_name in available_sheets:
                sheet_lower = sheet_name.lower().strip().replace(' ', '_')
                sheet_lower_orig = sheet_name.lower().strip()
                for variation in variations:
                    v_norm = variation.replace(' ', '_')
                    if v_norm in sheet_lower or sheet_lower == v_norm or variation in sheet_lower_orig or sheet_lower_orig == variation:
                        sheet_mapping[required_name] = sheet_name
                        break
                else:
                    continue
                break
        
        return sheet_mapping
    
    def _extract_period_from_filename(self, filename):
        """Extract period information from filename like 'April_2025.xlsx' or 'April-2025.xlsx'"""
        import re
        from datetime import datetime
        
        period_info = {}
        
        # Remove file extension
        name_without_ext = filename.rsplit('.', 1)[0] if '.' in filename else filename
        
        # Try to match patterns like "April_2025", "April-2025", "april 2025", etc.
        # Match month name and year
        month_patterns = [
            r'([A-Za-z]+)[_\-\s]+(\d{4})',  # April_2025, April-2025, April 2025
            r'(\d{1,2})[_\-\s]+([A-Za-z]+)[_\-\s]+(\d{4})',  # 01_April_2025
            r'([A-Za-z]+)[_\-\s]+(\d{4})[_\-\s]+([A-Za-z]+)',  # April_2025_March
        ]
        
        month_names = {
            'january': 1, 'february': 2, 'march': 3, 'april': 4,
            'may': 5, 'june': 6, 'july': 7, 'august': 8,
            'september': 9, 'october': 10, 'november': 11, 'december': 12
        }
        
        for pattern in month_patterns:
            match = re.search(pattern, name_without_ext, re.IGNORECASE)
            if match:
                groups = match.groups()
                
                # Find month name in groups
                month_name = None
                month_num = None
                year = None
                
                for group in groups:
                    group_lower = str(group).lower()
                    if group_lower in month_names:
                        month_name = group_lower
                        month_num = month_names[month_name]
                    elif str(group).isdigit() and len(str(group)) == 4:
                        year = int(group)
                
                if month_name and year and month_num:
                    # Create period label
                    period_info['label'] = f"{month_name.capitalize()}_{year}"
                    
                    # Calculate start and end dates for monthly period
                    if month_num == 12:
                        start_date = datetime(year, month_num, 1)
                        end_date = datetime(year + 1, 1, 31)
                    else:
                        start_date = datetime(year, month_num, 1)
                        # Get last day of month
                        if month_num == 2:
                            end_day = 29 if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0) else 28
                        elif month_num in [4, 6, 9, 11]:
                            end_day = 30
                        else:
                            end_day = 31
                        end_date = datetime(year, month_num, end_day)
                    
                    period_info['start_date'] = start_date.strftime('%Y-%m-%d')
                    period_info['end_date'] = end_date.strftime('%Y-%m-%d')
                    period_info['period_type'] = 'MONTHLY'
                    break
        
        return period_info


class RatioBenchmarksView(APIView):
    """GET: return current ratio benchmarks (DB merged with defaults). PUT: update stored benchmarks."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from app.services.benchmark_config import get_ratio_benchmarks
        from app.config.ratio_benchmarks import DEFAULT_RATIO_BENCHMARKS
        data = get_ratio_benchmarks()
        # Include labels for frontend (same keys as defaults)
        labels = {
            "stock_turnover": "Stock Turnover (times/year)",
            "gross_profit_ratio_min": "Gross Profit Ratio Min (%)",
            "gross_profit_ratio_max": "Gross Profit Ratio Max (%)",
            "own_fund_to_wf": "Own Fund to Working Fund (%)",
            "loans_to_wf_min": "Loans to WF Min (%)",
            "loans_to_wf_max": "Loans to WF Max (%)",
            "investments_to_wf_min": "Investments to WF Min (%)",
            "investments_to_wf_max": "Investments to WF Max (%)",
            "avg_cost_of_wf": "Avg Cost of WF (%)",
            "avg_yield_on_wf": "Avg Yield on WF (%)",
            "gross_financial_margin": "Gross Financial Margin (%)",
            "operating_cost_to_wf_min": "Operating Cost to WF Min (%)",
            "operating_cost_to_wf_max": "Operating Cost to WF Max (%)",
            "net_financial_margin": "Net Financial Margin (%)",
            "risk_cost_to_wf_max": "Risk Cost to WF Max (%)",
            "net_margin": "Net Margin (%)",
            "credit_deposit_ratio_min": "Credit Deposit Ratio Min (%)",
        }
        return Response({
            "benchmarks": data,
            "labels": labels,
            "keys_order": list(DEFAULT_RATIO_BENCHMARKS.keys()),
        })

    def put(self, request):
        from app.services.benchmark_config import set_ratio_benchmarks
        try:
            data = request.data.get("benchmarks") if isinstance(request.data, dict) else request.data
            if not isinstance(data, dict):
                return Response({
                    "status": "failed",
                    "message": "benchmarks must be an object",
                }, status=status.HTTP_400_BAD_REQUEST)
            set_ratio_benchmarks(data)
            return Response({"status": "success", "message": "Benchmarks updated."})
        except ValueError as e:
            return Response({"status": "failed", "message": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({
                "status": "failed",
                "message": str(e),
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
