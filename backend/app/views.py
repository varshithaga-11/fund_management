from django.shortcuts import render
from django.shortcuts import render
from rest_framework import viewsets

from .models import *

from .serializers import *
import os
from django.conf import settings
from django.http import FileResponse, HttpResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated,AllowAny
import random
from django.conf import settings
from .models import *
from .serializers import *
from rest_framework.generics import RetrieveUpdateDestroyAPIView
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, AllowAny
import os
from rest_framework import viewsets, status

from rest_framework.permissions import AllowAny

from django.utils import timezone
from django.contrib.auth.hashers import make_password
from decimal import Decimal
from openpyxl import load_workbook
from datetime import datetime
# from_email = settings.EMAIL_HOST_USER

# from django.core.mail import send_mail



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
        try:
            if 'file' not in request.FILES:
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": "No file provided"
                })
            
            company_id = request.data.get('company_id')
            if not company_id:
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": "company_id is required"
                })
            
            try:
                company = Company.objects.get(id=company_id)
            except Company.DoesNotExist:
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_404_NOT_FOUND,
                    "message": "Company not found"
                })
            
            excel_file = request.FILES['file']
            
            # Extract period information from filename if available
            filename = excel_file.name
            period_info = self._extract_period_from_filename(filename)
            
            # Load workbook
            workbook = load_workbook(excel_file, data_only=True)
            
            # Find required sheets with flexible matching
            sheet_mapping = self._find_sheets(workbook)
            
            missing_sheets = []
            required_sheet_names = ['Balance Sheet', 'Profit and Loss', 'Trading Account', 'Operational Metrics']
            for sheet_name in required_sheet_names:
                if sheet_name not in sheet_mapping:
                    missing_sheets.append(sheet_name)
            
            if missing_sheets:
                return Response({
                    "status": "failed",
                    "response_code": status.HTTP_400_BAD_REQUEST,
                    "message": f"Missing required sheets: {', '.join(missing_sheets)}. Available sheets: {', '.join(workbook.sheetnames)}"
                })
            
            # Parse each sheet using mapped names
            balance_sheet_data = self._parse_balance_sheet(workbook[sheet_mapping['Balance Sheet']])
            profit_loss_data = self._parse_profit_loss(workbook[sheet_mapping['Profit and Loss']])
            trading_account_data = self._parse_trading_account(workbook[sheet_mapping['Trading Account']])
            operational_metrics_data = self._parse_operational_metrics(workbook[sheet_mapping['Operational Metrics']])
            
            # Create Financial Period (use filename info or provided data or defaults)
            period_label = request.data.get('period_label') or period_info.get('label') or f"FY-{datetime.now().year}-{datetime.now().year + 1}"
            start_date = request.data.get('start_date') or period_info.get('start_date') or f"{datetime.now().year}-04-01"
            end_date = request.data.get('end_date') or period_info.get('end_date') or f"{datetime.now().year + 1}-03-31"
            period_type = request.data.get('period_type') or period_info.get('period_type') or 'MONTHLY' if period_info else 'YEARLY'
            
            period, created = FinancialPeriod.objects.get_or_create(
                company=company,
                label=period_label,
                defaults={
                    'period_type': period_type,
                    'start_date': start_date,
                    'end_date': end_date,
                    'is_finalized': False,
                }
            )
            
            # Create/Update Trading Account
            TradingAccount.objects.update_or_create(
                period=period,
                defaults=trading_account_data
            )
            
            # Create/Update Profit & Loss
            ProfitAndLoss.objects.update_or_create(
                period=period,
                defaults=profit_loss_data
            )
            
            # Create/Update Balance Sheet
            BalanceSheet.objects.update_or_create(
                period=period,
                defaults=balance_sheet_data
            )
            
            # Create/Update Operational Metrics
            OperationalMetrics.objects.update_or_create(
                period=period,
                defaults=operational_metrics_data
            )
            
            # Automatically calculate ratios
            from app.services.ratio_calculator import RatioCalculator
            calculator = RatioCalculator(period)
            all_ratios = calculator.calculate_all_ratios()
            traffic_light_statuses = calculator.get_traffic_light_statuses()
            
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
            
            return Response({
                "status": "success",
                "response_code": status.HTTP_200_OK,
                "message": "Excel file processed successfully",
                "period_id": period.id,
                "period_label": period.label
            })
            
        except Exception as e:
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
    
    def _find_sheets(self, workbook):
        """Find required sheets with flexible name matching"""
        available_sheets = workbook.sheetnames
        sheet_mapping = {}
        
        # Define variations for each required sheet
        sheet_variations = {
            'Balance Sheet': ['balance sheet', 'balance_sheet', 'balancesheet', 'balance'],
            'Profit and Loss': ['profit and loss', 'profit & loss', 'profit_and_loss', 'profitandloss', 'profit & loss', 'p&l', 'pl'],
            'Trading Account': ['trading account', 'trading_account', 'tradingaccount', 'trading'],
            'Operational Metrics': ['operational metrics', 'operational_metrics', 'operationalmetrics', 'operational', 'metrics']
        }
        
        for required_name, variations in sheet_variations.items():
            found = False
            for sheet_name in available_sheets:
                sheet_lower = sheet_name.lower().strip()
                for variation in variations:
                    if variation in sheet_lower or sheet_lower == variation:
                        sheet_mapping[required_name] = sheet_name
                        found = True
                        break
                if found:
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
