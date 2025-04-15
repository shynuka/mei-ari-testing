import json
import jwt
from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient, APIRequestFactory
from rest_framework.exceptions import AuthenticationFailed
from django.urls import reverse
from unittest.mock import patch, MagicMock
import pytest

# Assuming the following are your models
from meiaribe.models import UserDetails, SubDeptOfficeDetails, WorkGroup, WorkGroupDetails, ReportRecord

# If UserTokenAuthentication is a custom class
from meiaribe.authentication import UserTokenAuthentication


# ---------- User Token Authentication Tests ----------
class UserTokenAuthenticationTests(TestCase):

    def setUp(self):
        """Setting up a test user for authentication"""
        self.user = UserDetails.objects.create(
            id="123",  # Assuming 'id' field is a string
            username="testuser",
            password="password123",
            role="admin"
        )
        self.valid_token = jwt.encode(
            {"id": self.user.id, "role": self.user.role},
            "user_key", algorithm="HS256"
        )
        self.invalid_token = "invalid.token"
        self.expired_token = jwt.encode(
            {"id": self.user.id, "role": self.user.role, "exp": timezone.now() - timedelta(days=1)},
            "user_key", algorithm="HS256"
        )

    def test_valid_token(self):
        """Test authentication with a valid token"""
        factory = APIRequestFactory()
        request = factory.get('/some-url', HTTP_AUTHORIZATION=f"Bearer {self.valid_token}")
        auth = UserTokenAuthentication()  # Make sure to import UserTokenAuthentication
        user, role = auth.authenticate(request)
        self.assertEqual(user.username, "testuser")
        self.assertEqual(role, "admin")

    def test_invalid_token(self):
        """Test authentication with an invalid token"""
        factory = APIRequestFactory()
        request = factory.get('/some-url', HTTP_AUTHORIZATION=f"Bearer {self.invalid_token}")
        auth = UserTokenAuthentication()  # Make sure to import UserTokenAuthentication
        with self.assertRaises(AuthenticationFailed):
            auth.authenticate(request)

    def test_expired_token(self):
        """Test authentication with an expired token"""
        factory = APIRequestFactory()
        request = factory.get('/some-url', HTTP_AUTHORIZATION=f"Bearer {self.expired_token}")
        auth = UserTokenAuthentication()  # Make sure to import UserTokenAuthentication
        with self.assertRaises(AuthenticationFailed):
            auth.authenticate(request)

    def test_missing_token(self):
        """Test authentication when token is missing"""
        factory = APIRequestFactory()
        request = factory.get('/some-url')
        auth = UserTokenAuthentication()  # Make sure to import UserTokenAuthentication
        with self.assertRaises(AuthenticationFailed):
            auth.authenticate(request)


# ---------- Login Tests ----------
class LoginTests(TestCase):

    def setUp(self):
        """Setting up test user for login"""
        self.user = UserDetails.objects.create(
            id="123",
            username="testuser",
            password="password123",
            role="admin"
        )
        self.client = APIClient()

    def test_successful_login(self):
        """Test that login works with correct credentials"""
        data = {
            "username": "testuser",
            "password": "password123"
        }
        response = self.client.post('/login/', data, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertIn('token', response.data)

    def test_incorrect_password(self):
        """Test that login fails with incorrect password"""
        data = {
            "username": "testuser",
            "password": "wrongpassword"
        }
        response = self.client.post('/login/', data, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn('detail', response.data)

    def test_missing_credentials(self):
        """Test that login fails when credentials are missing"""
        # Missing password
        data = {
            "username": "testuser"
        }
        response = self.client.post('/login/', data, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn('detail', response.data)

        # Missing username
        data = {
            "password": "password123"
        }
        response = self.client.post('/login/', data, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn('detail', response.data)

    def test_expired_token_login(self):
        """Test that expired token is rejected"""
        expired_token = jwt.encode(
            {"id": self.user.id, "role": self.user.role, "exp": timezone.now() - timedelta(days=1)},
            "user_key", algorithm="HS256"
        )
        headers = {'Authorization': f'Bearer {expired_token}'}
        response = self.client.get('/some-protected-url', **headers)
        self.assertEqual(response.status_code, 401)  # Unauthorized due to expired token


# ---------- WorkGroup View Tests ----------
@pytest.mark.django_db
def test_workgroup_list(client, sub_dept_office):
    response = client.get("/api/work-groups/", {"sub_dept_office": sub_dept_office.id})
    assert response.status_code == 200
    data = response.json()["data"]
    assert data[0]["group_name"] == "Test Group"


# ---------- Report Generation and Download Tests ----------
@patch("your_app.views.boto3.client")
@patch("your_app.views.requests.post")
@pytest.mark.django_db
def test_generate_and_upload_report(mock_post, mock_boto_client, client, sub_dept_office):
    mock_post.return_value.status_code = 200
    mock_post.return_value.json.return_value = {"data": {"summary_report": "Mock Report Text"}}

    mock_s3 = MagicMock()
    mock_boto_client.return_value = mock_s3

    payload = {
        "location": {"city": "TestCity", "latitude": "10.0", "longitude": "20.0"},
        "departmentName": "Health",
        "subDepartmentName": "Public Health",
        "subDeptOfficeName": sub_dept_office.id,
        "accessId": "abc123",
    }

    response = client.post("/api/generate-report/", payload, format="json")
    assert response.status_code == 201
    assert "report_id" in response.json()
    assert ReportRecord.objects.count() == 1


@patch("your_app.views.boto3.client")
@pytest.mark.django_db
def test_download_report(mock_boto_client, client, report_record):
    mock_s3 = MagicMock()
    mock_boto_client.return_value = mock_s3
    mock_s3.get_object.return_value = {
        "Body": MagicMock(read=lambda: b"Mock S3 Report Text")
    }

    response = client.get(f"/api/download-report/{report_record.id}/")
    assert response.status_code == 200
    assert b"Mock S3 Report Text" in response.content


# ---------- Fixtures ----------
@pytest.fixture
def sub_dept_office(db):
    return SubDeptOfficeDetails.objects.create(name="Test Office")

@pytest.fixture
def report_record(db, sub_dept_office):
    return ReportRecord.objects.create(
        sub_dept_office=sub_dept_office,
        report_data="Mock Report"
    )
