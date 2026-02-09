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

    # Optional: search & filter support
    search_fields = ["name", "registration_no"]
