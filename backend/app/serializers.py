from rest_framework import serializers
from .models import *
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate


class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8, style={'input_type': 'password'})
    password_confirm = serializers.CharField(write_only=True, style={'input_type': 'password'})
    created_by = serializers.PrimaryKeyRelatedField(allow_null=True,queryset=UserRegister.objects.all(),required=False)   
    
    class Meta:
        model = UserRegister
        fields = [
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'role',
            'password',
            'password_confirm',
            'created_by'
        ]
        extra_kwargs = {
            'password': {'write_only': True},
        }
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        user = UserRegister(**validated_data)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        validated_data.pop('password_confirm', None)
        
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        if password:
            instance.set_password(password)
        
        instance.save()
        return instance



class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)
    
    def validate(self, data):
        username = data.get("username")
        password = data.get("password")

        user = authenticate(username=username, password=password)
        if not user:
            raise Exception("Invalid username or password.")

        refresh = RefreshToken.for_user(user)
        refresh['username'] = user.username    
        refresh['role'] = user.role
        refresh['user_id'] = user.id

        return {
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "userRole": user.role,  
            }


class RefreshTokenSerializer(serializers.Serializer):
    refresh = serializers.CharField()
    
    def validate(self, data):
        refresh = data.get("refresh")
        try:
            token = RefreshToken(refresh)
            # Get user from token
            user_id = token.payload.get('user_id')
            if not user_id:
                raise serializers.ValidationError("Invalid refresh token.")
            
            # Get user instance
            user = UserRegister.objects.get(id=user_id)
            
            # Create new refresh token with user data
            new_refresh = RefreshToken.for_user(user)
            new_refresh['username'] = user.username    
            new_refresh['role'] = user.role
            
            return {
                "access": str(new_refresh.access_token)
            }
        except Exception as e:
            raise serializers.ValidationError("Invalid refresh token.")




class ProfileSerializer(serializers.ModelSerializer):
    current_password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    new_password = serializers.CharField(write_only=True, required=False, style={'input_type': 'password'})
    
    class Meta:
        model = UserRegister
        fields = [
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'current_password',
            'new_password'
        ]
        extra_kwargs = {
            'current_password': {'write_only': True},
            'new_password': {'write_only': True},
        }
    
    def validate(self, attrs):
        """Validate that the current password is correct"""
        current_password = attrs.get('current_password')
        if current_password and self.instance:
            if not self.instance.check_password(current_password):
                raise serializers.ValidationError({
                    'current_password': 'Current password is incorrect.'
                })
        return attrs
        
    def update(self, instance, validated_data):
        # Remove password fields from validated_data
        current_password = validated_data.pop('current_password', None)
        new_password = validated_data.pop('new_password', None)
        validated_data.pop('password_confirm', None)
        
        # Update regular fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        # Update password only if new_password is provided
        if new_password:
            instance.set_password(new_password)
        
        instance.save()
        return instance



class CompanySerializer(serializers.ModelSerializer):
    class Meta:
        model = Company
        fields = [
            "id",
            "name",
            "registration_no",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class TradingAccountSerializer(serializers.ModelSerializer):
    gross_profit = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    
    class Meta:
        model = TradingAccount
        fields = [
            'id',
            'period',
            'opening_stock',
            'purchases',
            'trade_charges',
            'sales',
            'closing_stock',
            'gross_profit'
        ]
        read_only_fields = ['id', 'period']


class ProfitAndLossSerializer(serializers.ModelSerializer):
    total_interest_income = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    total_interest_expense = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    
    class Meta:
        model = ProfitAndLoss
        fields = [
            'id',
            'period',
            'interest_on_loans',
            'interest_on_bank_ac',
            'return_on_investment',
            'miscellaneous_income',
            'interest_on_deposits',
            'interest_on_borrowings',
            'establishment_contingencies',
            'provisions',
            'net_profit',
            'total_interest_income',
            'total_interest_expense'
        ]
        read_only_fields = ['id', 'period']


class BalanceSheetSerializer(serializers.ModelSerializer):
    working_fund = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    own_funds = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    
    class Meta:
        model = BalanceSheet
        fields = [
            'id',
            'period',
            'share_capital',
            'deposits',
            'borrowings',
            'reserves_statutory_free',
            'undistributed_profit',
            'provisions',
            'other_liabilities',
            'cash_in_hand',
            'cash_at_bank',
            'investments',
            'loans_advances',
            'fixed_assets',
            'other_assets',
            'stock_in_trade',
            'working_fund',
            'own_funds'
        ]
        read_only_fields = ['id', 'period']


class OperationalMetricsSerializer(serializers.ModelSerializer):
    class Meta:
        model = OperationalMetrics
        fields = [
            'id',
            'period',
            'staff_count'
        ]
        read_only_fields = ['id', 'period']


class FinancialPeriodSerializer(serializers.ModelSerializer):
    trading_account = TradingAccountSerializer(read_only=True)
    profit_loss = ProfitAndLossSerializer(read_only=True)
    balance_sheet = BalanceSheetSerializer(read_only=True)
    operational_metrics = OperationalMetricsSerializer(read_only=True)
    ratios = serializers.SerializerMethodField()
    
    class Meta:
        model = FinancialPeriod
        fields = [
            'id',
            'company',
            'period_type',
            'start_date',
            'end_date',
            'label',
            'is_finalized',
            'uploaded_file',
            'file_type',
            'created_at',
            'trading_account',
            'profit_loss',
            'balance_sheet',
            'operational_metrics',
            'ratios'
        ]
        read_only_fields = ['id', 'created_at']
    
    def __init__(self, *args, **kwargs):
        # Extract the fields parameter if provided
        fields = kwargs.pop('fields', None)
        super().__init__(*args, **kwargs)
        
        # If specific fields are requested, remove all others
        if fields:
            # fields is a list of field names to keep
            allowed_fields = set(fields)
            existing_fields = set(self.fields.keys())
            
            # Remove fields that are not in the allowed list
            for field_name in existing_fields - allowed_fields:
                self.fields.pop(field_name)
    
    def get_ratios(self, obj):
        if hasattr(obj, 'ratios'):
            return RatioResultSerializer(obj.ratios).data
        return None


class RatioResultSerializer(serializers.ModelSerializer):
    interpretation = serializers.SerializerMethodField()
    
    class Meta:
        model = RatioResult
        fields = [
            'id',
            'period',
            'working_fund',
            'stock_turnover',
            'gross_profit_ratio',
            'net_profit_ratio',
            'net_own_funds',
            'own_fund_to_wf',
            'deposits_to_wf',
            'borrowings_to_wf',
            'loans_to_wf',
            'investments_to_wf',
            'earning_assets_to_wf',
            'interest_tagged_funds_to_wf',
            'cost_of_deposits',
            'yield_on_loans',
            'yield_on_investments',
            'credit_deposit_ratio',
            'avg_cost_of_wf',
            'avg_yield_on_wf',
            'misc_income_to_wf',
            'interest_exp_to_interest_income',
            'gross_fin_margin',
            'operating_cost_to_wf',
            'net_fin_margin',
            'risk_cost_to_wf',
            'net_margin',
            'capital_turnover_ratio',
            'per_employee_deposit',
            'per_employee_loan',
            'per_employee_contribution',
            'per_employee_operating_cost',
            'all_ratios',
            'traffic_light_status',
            'calculated_at',
            'interpretation'
        ]
        read_only_fields = ['id', 'calculated_at']
    
    def get_interpretation(self, obj):
        from app.services.ratio_calculator import RatioCalculator
        try:
            calculator = RatioCalculator(obj.period)
            return calculator.generate_interpretation()
        except:
            return ""


class RatioCalculationRequestSerializer(serializers.Serializer):
    period_id = serializers.IntegerField()


class StatementColumnConfigSerializer(serializers.ModelSerializer):
    company_name = serializers.CharField(source="company.name", read_only=True)

    class Meta:
        model = StatementColumnConfig
        fields = [
            "id",
            "company",
            "company_name",
            "statement_type",
            "canonical_field",
            "display_name",
            "aliases",
            "is_required",
        ]
        read_only_fields = ["id"]




class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)
    created_by = serializers.PrimaryKeyRelatedField(
        queryset=UserRegister.objects.all(), required=False, allow_null=True
    )
    created_by_first_name = serializers.CharField(
        source='created_by.first_name', read_only=True
    )
    created_by_last_name = serializers.CharField(
        source='created_by.last_name', read_only=True
    )

    class Meta:
        model = UserRegister
        fields = [
            'id',
            'username',
            'email',
            'password',
            'is_active',
            'first_name',
            'last_name',
            'role',
            'phone_number',
            'created_by',            
            'created_by_first_name',  
            'created_by_last_name',  
        ]
        extra_kwargs = {
            'phone_number': {'required': False, 'allow_null': True},
            'role': {'required': True},
        }

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        created_by = validated_data.pop('created_by', None)
        
        user = UserRegister.objects.create_user(**validated_data)
        if password:
            user.set_password(password)
        if created_by:
            user.created_by = created_by
            
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        created_by = validated_data.pop('created_by', None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        if password:
            instance.set_password(password)
        if created_by:
            instance.created_by = created_by
        instance.save()
        return instance
