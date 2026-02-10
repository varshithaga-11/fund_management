

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from .views import *  # noqa: F401 F403

router = DefaultRouter()

router.register(r'profile', ProfileView, basename='profile')
router.register(r"companies", CompanyViewSet, basename="company")
router.register(r"financial-periods", FinancialPeriodViewSet, basename="financial-period")
router.register(r"trading-accounts", TradingAccountViewSet, basename="trading-account")
router.register(r"profit-loss", ProfitAndLossViewSet, basename="profit-loss")
router.register(r"balance-sheets", BalanceSheetViewSet, basename="balance-sheet")
router.register(r"operational-metrics", OperationalMetricsViewSet, basename="operational-metrics")
router.register(r"ratio-results", RatioResultViewSet, basename="ratio-result")



urlpatterns = [
    path('', include(router.urls)),
    path('register/', UserRegisterView.as_view(), name='register'),
    # path('userlist/', UserListView.as_view(), name='user_list'),
    # path('userlist/<int:pk>/', UserRetrieveUpdateDestroyView.as_view(), name='user_detail'),
    path('login/', LoginView.as_view(), name='login'),
    path('token/refresh/', RefreshTokenView.as_view(), name='token_refresh'),
    path('periods/<int:period_id>/calculate-ratios/', CalculateRatiosView.as_view(), name='calculate-ratios'),
    path('upload-excel/', UploadExcelView.as_view(), name='upload-excel'),
    path('ratio-benchmarks/', RatioBenchmarksView.as_view(), name='ratio-benchmarks'),
    # path('sendotp/', SendOtpView.as_view(),name='sendotp'),
    # path('verifyotp/', VerifyOTPView.as_view(),name='verifyotp'),
    # path('resetpassword/', ResetPasswordView.as_view(), name='resetpassword'),
    # path('updateuser/', UpdateUserView.as_view(), name='updateuser'),
]