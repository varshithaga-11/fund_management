
from django.contrib import admin
from .models import *

@admin.register(UserRegister)
class UserRegisterAdmin(admin.ModelAdmin):
    list_display = ('username', 'email', 'role', 'is_active')
    search_fields = ('username', 'email')

@admin.register(FinancialPeriod)
class FinancialPeriodAdmin(admin.ModelAdmin):
    list_display = ('label', 'period_type', 'start_date', 'end_date', 'is_finalized')
    list_filter = ('period_type', 'is_finalized')

@admin.register(ProductKey)
class ProductKeyAdmin(admin.ModelAdmin):
    list_display = ('key', 'device_id', 'is_active', 'activated_at', 'created_at')
    search_fields = ('key', 'device_id')
    list_filter = ('is_active',)

admin.site.register(TradingAccount)
admin.site.register(ProfitAndLoss)
admin.site.register(BalanceSheet)
admin.site.register(OperationalMetrics)
admin.site.register(RatioResult)
admin.site.register(AppConfig)
admin.site.register(StatementColumnConfig)
admin.site.register(EmailOTP)
