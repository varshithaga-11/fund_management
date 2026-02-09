

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from .views import *

router = DefaultRouter()

router.register(r'profile', ProfileView, basename='profile')
router.register(r"companies", CompanyViewSet, basename="company")



urlpatterns = [
    path('', include(router.urls)),
    path('register/', UserRegisterView.as_view(), name='register'),
    # path('userlist/', UserListView.as_view(), name='user_list'),
    # path('userlist/<int:pk>/', UserRetrieveUpdateDestroyView.as_view(), name='user_detail'),
    path('login/', LoginView.as_view(), name='login'),
    path('token/refresh/', RefreshTokenView.as_view(), name='token_refresh'),
    # path('sendotp/', SendOtpView.as_view(),name='sendotp'),
    # path('verifyotp/', VerifyOTPView.as_view(),name='verifyotp'),
    # path('resetpassword/', ResetPasswordView.as_view(), name='resetpassword'),
    # path('updateuser/', UpdateUserView.as_view(), name='updateuser'),
]