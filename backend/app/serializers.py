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


        